import Foundation

/// Reads real device volume storage metrics and app sandbox footprint using public Foundation APIs.
final class StorageManagerService {
    private let fileManager = FileManager.default

    func fetchDeviceStorageInfo() -> DeviceStorageInfo {
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())

        let resourceKeys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey
        ]

        var total: Int64 = 0
        var available: Int64 = 0
        var importantAvailable: Int64 = 0
        var opportunisticAvailable: Int64 = 0

        if let values = try? homeURL.resourceValues(forKeys: resourceKeys) {
            total = Int64(values.volumeTotalCapacity ?? 0)
            available = Int64(values.volumeAvailableCapacity ?? 0)
            importantAvailable = values.volumeAvailableCapacityForImportantUsage ?? available
            opportunisticAvailable = values.volumeAvailableCapacityForOpportunisticUsage ?? available
        }

        // Fallback via attributesOfFileSystem if volumeTotalCapacity was unavailable.
        if total == 0,
           let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
            available = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            if importantAvailable == 0 { importantAvailable = available }
            if opportunisticAvailable == 0 { opportunisticAvailable = available }
        }

        let sandboxUsed = calculateDirectorySize(at: homeURL)

        return DeviceStorageInfo(
            totalBytes: total,
            availableBytes: available,
            importantAvailableBytes: importantAvailable,
            opportunisticAvailableBytes: opportunisticAvailable,
            appSandboxUsedBytes: sandboxUsed,
            timestamp: Date()
        )
    }

    func calculateDirectorySize(at url: URL) -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else {
                continue
            }
            let allocated = values.totalFileAllocatedSize.map(Int64.init)
            let regular = values.fileSize.map(Int64.init)
            totalSize += allocated ?? regular ?? 0
        }
        return totalSize
    }
}
