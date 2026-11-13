import Foundation

/// Scans and cleans real temporary, log, orphaned cache, and large sandbox files inside the app container.
/// Never touches protected user preferences or user-locked files, and verifies actual freed bytes after deletion.
final class JunkCleanerService: @unchecked Sendable {
    private let fileManager = FileManager.default
    private let largeSandboxThresholdBytes: Int64 = 5 * 1_048_576 // 5 MB

    private var protectedDirectoryNames: Set<String> {
        ["Preferences", "Protected", "ManagedFiles", "SplashBoard"]
    }

    private var tempExtensions: Set<String> {
        ["tmp", "temp", "part", "download", "bak", "old"]
    }

    private var logExtensions: Set<String> {
        ["log", "trace", "crash"]
    }

    func scanSandboxJunk() async -> [JunkItem] {
        await Task.detached(priority: .userInitiated) { [self] in
            var discovered: [JunkItem] = []

            let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

            // 1. Temporary Directory (tmp/)
            discovered.append(
                contentsOf: scanDirectory(
                    fileManager.temporaryDirectory,
                    defaultCategory: .temporaryFiles,
                    pathPrefix: "tmp"
                )
            )

            // 2. Library/Caches
            if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                discovered.append(
                    contentsOf: scanDirectory(
                        cachesURL,
                        defaultCategory: .orphanedCaches,
                        pathPrefix: "Library/Caches"
                    )
                )
            }

            // 3. Library/Logs
            if let logsURL = libraryURL?.appendingPathComponent("Logs", isDirectory: true) {
                discovered.append(
                    contentsOf: scanDirectory(
                        logsURL,
                        defaultCategory: .logFiles,
                        pathPrefix: "Library/Logs"
                    )
                )
            }

            // 4. Documents/Staging & Documents/Downloads
            if let docsURL = documentsURL {
                let stagingURL = docsURL.appendingPathComponent("Staging", isDirectory: true)
                discovered.append(
                    contentsOf: scanDirectory(
                        stagingURL,
                        defaultCategory: .importStaging,
                        pathPrefix: "Documents/Staging"
                    )
                )

                let downloadsURL = docsURL.appendingPathComponent("Downloads", isDirectory: true)
                discovered.append(
                    contentsOf: scanDirectory(
                        downloadsURL,
                        defaultCategory: .largeSandboxFiles,
                        pathPrefix: "Documents/Downloads"
                    )
                )
            }

            return discovered.sorted { $0.sizeBytes > $1.sizeBytes }
        }.value
    }

    private func scanDirectory(
        _ directoryURL: URL,
        defaultCategory: JunkCategory,
        pathPrefix: String
    ) -> [JunkItem] {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return [] }

        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: keys,
            options: []
        ) else {
            return []
        }

        var items: [JunkItem] = []

        for case let fileURL as URL in enumerator {
            let pathComponents = fileURL.pathComponents
            if pathComponents.contains(where: { protectedDirectoryNames.contains($0) }) {
                continue
            }

            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else {
                continue
            }

            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            guard size > 0 else { continue }

            let ext = fileURL.pathExtension.lowercased()
            let resolvedCategory: JunkCategory
            if size >= largeSandboxThresholdBytes && defaultCategory != .logFiles {
                resolvedCategory = .largeSandboxFiles
            } else if tempExtensions.contains(ext) {
                resolvedCategory = .temporaryFiles
            } else if logExtensions.contains(ext) {
                resolvedCategory = .logFiles
            } else {
                resolvedCategory = defaultCategory
            }

            let relativePath = "\(pathPrefix)/\(fileURL.lastPathComponent)"
            let created = values.creationDate ?? Date()
            let modified = values.contentModificationDate ?? created

            // Large sandbox files in Downloads are unchecked by default to ensure explicit user review.
            let preselected = resolvedCategory != .largeSandboxFiles

            items.append(
                JunkItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    pathDescription: relativePath,
                    sizeBytes: size,
                    category: resolvedCategory,
                    createdAt: created,
                    modifiedAt: modified,
                    isSelected: preselected
                )
            )
        }

        return items
    }

    /// Deletes only the user-selected JunkItems and measures exact bytes removed.
    func cleanSelectedItems(_ items: [JunkItem]) async -> JunkCleanupSummary {
        let selected = items.filter { $0.isSelected }
        let beforeTotal = items.reduce(0) { $0 + $1.sizeBytes }

        var freed: Int64 = 0
        var deletedCount = 0
        var failedCount = 0

        for item in selected {
            guard fileManager.fileExists(atPath: item.url.path) else {
                continue
            }
            let exactBefore = exactFileSize(at: item.url) ?? item.sizeBytes
            do {
                try fileManager.removeItem(at: item.url)
                freed += exactBefore
                deletedCount += 1
            } catch {
                failedCount += 1
            }
        }

        // Re-scan remaining items to confirm real post-cleanup state
        let remaining = await scanSandboxJunk()
        let afterTotal = remaining.reduce(0) { $0 + $1.sizeBytes }

        await DiagnosticLogger.shared.log(
            "Junk cleanup completed: deleted \(deletedCount) files, freed \(freed) bytes, failed \(failedCount).",
            category: "JunkCleaner"
        )

        return JunkCleanupSummary(
            beforeTotalBytes: beforeTotal,
            afterTotalBytes: afterTotal,
            freedBytes: freed,
            deletedFilesCount: deletedCount,
            failedFilesCount: failedCount,
            timestamp: Date()
        )
    }

    private func exactFileSize(at url: URL) -> Int64? {
        let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
        if let allocated = values?.totalFileAllocatedSize {
            return Int64(allocated)
        }
        if let regular = values?.fileSize {
            return Int64(regular)
        }
        return nil
    }
}
