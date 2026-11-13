import Foundation

/// Audits and safely cleans caches managed inside Booster Pro's sandbox.
/// Clearly distinguishes deletable caches from protected user data (UserDefaults, saved files).
/// Does not touch Safari or third-party app caches due to iOS sandbox rules.
final class CacheCleanerService {
    private let fileManager = FileManager.default
    private let storageService = StorageManagerService()

    func auditCachePartitions() -> [CachePartitionItem] {
        let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        var partitions: [CachePartitionItem] = []

        // 1. URL Network Cache (both memory & disk)
        let urlDiskBytes = Int64(URLCache.shared.currentDiskUsage)
        let urlMemBytes = Int64(URLCache.shared.currentMemoryUsage)
        partitions.append(
            CachePartitionItem(
                type: .urlNetworkCache,
                title: "Bộ nhớ đệm mạng (URLCache)",
                subtitle: "Phản hồi HTTP và dữ liệu tải tạm thời của ứng dụng.",
                directoryURL: cachesURL,
                sizeBytes: urlDiskBytes + urlMemBytes,
                fileCount: (urlDiskBytes + urlMemBytes) > 0 ? 1 : 0,
                isDeletable: true,
                isSelected: true
            )
        )

        // 2. Thumbnail & Image Cache Directory
        if let thumbURL = cachesURL?.appendingPathComponent("Thumbnails", isDirectory: true) {
            let (size, count) = inspectDirectory(thumbURL)
            partitions.append(
                CachePartitionItem(
                    type: .imageThumbnailCache,
                    title: "Bộ nhớ đệm hình thu nhỏ (Thumbnails)",
                    subtitle: "Ảnh xem trước tạo ra trong quá trình quét thư viện.",
                    directoryURL: thumbURL,
                    sizeBytes: size,
                    fileCount: count,
                    isDeletable: true,
                    isSelected: true
                )
            )
        }

        // 3. Temporary Snapshots & Working Cache
        let tmpDir = fileManager.temporaryDirectory
        let (tmpSize, tmpCount) = inspectDirectory(tmpDir)
        partitions.append(
            CachePartitionItem(
                type: .temporarySnapshots,
                title: "Dữ liệu đệm phiên làm việc (tmp)",
                subtitle: "Tệp trung gian khi phân tích dung lượng và hình ảnh.",
                directoryURL: tmpDir,
                sizeBytes: tmpSize,
                fileCount: tmpCount,
                isDeletable: true,
                isSelected: true
            )
        )

        // 4. Diagnostic Logs
        if let logsURL = libraryURL?.appendingPathComponent("Logs", isDirectory: true) {
            let (logSize, logCount) = inspectDirectory(logsURL)
            partitions.append(
                CachePartitionItem(
                    type: .diagnosticLogs,
                    title: "Nhật ký chẩn đoán nội bộ",
                    subtitle: "Lịch sử phiên quét gần đây trong Library/Logs.",
                    directoryURL: logsURL,
                    sizeBytes: logSize,
                    fileCount: logCount,
                    isDeletable: true,
                    isSelected: true
                )
            )
        }

        // 5. Protected User Preferences (NOT deletable)
        if let prefsURL = libraryURL?.appendingPathComponent("Preferences", isDirectory: true) {
            let (prefSize, prefCount) = inspectDirectory(prefsURL)
            partitions.append(
                CachePartitionItem(
                    type: .protectedUserSettings,
                    title: "Cài đặt & Phiên người dùng (Được bảo vệ)",
                    subtitle: "Tùy chọn ứng dụng và trạng thái cấu hình cá nhân.",
                    directoryURL: prefsURL,
                    sizeBytes: prefSize,
                    fileCount: prefCount,
                    isDeletable: false,
                    isSelected: false,
                    protectionReason: "Được bảo vệ để không làm mất cấu hình và trạng thái đăng nhập."
                )
            )
        }

        // 6. Protected User Documents (NOT deletable)
        if let managedURL = documentsURL?.appendingPathComponent("ManagedFiles", isDirectory: true) {
            let (docSize, docCount) = inspectDirectory(managedURL)
            partitions.append(
                CachePartitionItem(
                    type: .protectedUserDocuments,
                    title: "Tệp cá nhân đã nhập (Được bảo vệ)",
                    subtitle: "Tài liệu bạn chủ động quản lý qua Files Picker.",
                    directoryURL: managedURL,
                    sizeBytes: docSize,
                    fileCount: docCount,
                    isDeletable: false,
                    isSelected: false,
                    protectionReason: "Chỉ xóa khi bạn tự chọn và xác nhận trong Quản lý dung lượng."
                )
            )
        }

        return partitions
    }

    func cleanSelectedCaches(_ partitions: [CachePartitionItem]) async -> CacheCleanupResult {
        let beforeCleanable = partitions.filter { $0.isDeletable }.reduce(0) { $0 + $1.sizeBytes }
        let protectedBytes = partitions.filter { !$0.isDeletable }.reduce(0) { $0 + $1.sizeBytes }

        var freedBytes: Int64 = 0
        var cleanedCount = 0

        for item in partitions where item.isDeletable && item.isSelected {
            switch item.type {
            case .urlNetworkCache:
                let before = Int64(URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage)
                URLCache.shared.removeAllCachedResponses()
                ImageCacheManager.shared.purgeAll()
                let after = Int64(URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage)
                freedBytes += max(0, before - after)
                cleanedCount += 1

            case .imageThumbnailCache, .temporarySnapshots, .diagnosticLogs:
                if let dirURL = item.directoryURL {
                    let removed = removeDirectoryContents(at: dirURL)
                    freedBytes += removed
                    cleanedCount += 1
                }

            case .protectedUserSettings, .protectedUserDocuments:
                // Never delete protected stores in Cache Cleaner.
                continue
            }
        }

        let updatedPartitions = auditCachePartitions()
        let afterCleanable = updatedPartitions.filter { $0.isDeletable }.reduce(0) { $0 + $1.sizeBytes }

        await DiagnosticLogger.shared.log(
            "Cache cleanup finished: freed \(freedBytes) bytes across \(cleanedCount) partitions.",
            category: "CacheCleaner"
        )

        return CacheCleanupResult(
            beforeCleanableBytes: beforeCleanable,
            afterCleanableBytes: afterCleanable,
            freedBytes: freedBytes,
            cleanedPartitionsCount: cleanedCount,
            protectedBytesUntouched: protectedBytes,
            timestamp: Date()
        )
    }

    private func inspectDirectory(_ url: URL) -> (sizeBytes: Int64, fileCount: Int) {
        guard fileManager.fileExists(atPath: url.path) else { return (0, 0) }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey],
            options: []
        ) else {
            return (0, 0)
        }

        var total: Int64 = 0
        var count = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey]
            ), values.isRegularFile == true else {
                continue
            }
            total += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            count += 1
        }
        return (total, count)
    }

    private func removeDirectoryContents(at directoryURL: URL) -> Int64 {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return 0 }
        let before = storageService.calculateDirectorySize(at: directoryURL)

        if let contents = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) {
            for itemURL in contents {
                try? fileManager.removeItem(at: itemURL)
            }
        }

        let after = storageService.calculateDirectorySize(at: directoryURL)
        return max(0, before - after)
    }
}
