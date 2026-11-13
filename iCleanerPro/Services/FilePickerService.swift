import Foundation
import UniformTypeIdentifiers

/// Manages user-selected files imported via iOS Files Picker (.fileImporter) inside Documents/ManagedFiles.
final class FilePickerService {
    private let fileManager = FileManager.default

    var managedFilesDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = docs.appendingPathComponent("ManagedFiles", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func listManagedFiles() -> [SandboxFileItem] {
        let dir = managedFilesDirectory
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .contentModificationDateKey,
            .contentTypeKey
        ]

        guard let contents = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { url -> SandboxFileItem? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else {
                return nil
            }
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            let modified = values.contentModificationDate ?? Date()
            let typeDesc = values.contentType?.localizedDescription ?? url.pathExtension.uppercased()

            return SandboxFileItem(
                url: url,
                name: url.lastPathComponent,
                sizeBytes: size,
                modificationDate: modified,
                contentTypeDescription: typeDesc.isEmpty ? "Tệp dữ liệu" : typeDesc,
                isSelected: false
            )
        }
        .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    /// Imports user-picked URLs (security-scoped) into Documents/ManagedFiles for inspection and management.
    func importPickedFiles(urls: [URL]) throws -> [SandboxFileItem] {
        var importedCount = 0

        for sourceURL in urls {
            let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            var destinationURL = managedFilesDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            if fileManager.fileExists(atPath: destinationURL.path) {
                let stem = sourceURL.deletingPathExtension().lastPathComponent
                let ext = sourceURL.pathExtension
                let uniqueName = ext.isEmpty
                    ? "\(stem)_\(Int(Date().timeIntervalSince1970))"
                    : "\(stem)_\(Int(Date().timeIntervalSince1970)).\(ext)"
                destinationURL = managedFilesDirectory.appendingPathComponent(uniqueName)
            }

            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            importedCount += 1
        }

        Task {
            await DiagnosticLogger.shared.log(
                "Imported \(importedCount) user files via Files Picker.",
                category: "FilePicker"
            )
        }

        return listManagedFiles()
    }

    /// Deletes selected files after explicit user confirmation and returns actual freed bytes.
    func deleteManagedFiles(_ items: [SandboxFileItem]) -> Int64 {
        var freed: Int64 = 0
        for item in items where item.isSelected {
            if fileManager.fileExists(atPath: item.url.path) {
                do {
                    try fileManager.removeItem(at: item.url)
                    freed += item.sizeBytes
                } catch {
                    continue
                }
            }
        }
        return freed
    }
}
