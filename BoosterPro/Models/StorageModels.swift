import Foundation

/// Represents real storage metrics obtained from iOS FileManager / URLResourceValues.
struct DeviceStorageInfo: Equatable {
    let totalBytes: Int64
    let availableBytes: Int64
    let importantAvailableBytes: Int64
    let opportunisticAvailableBytes: Int64
    let appSandboxUsedBytes: Int64
    let timestamp: Date

    var usedBytes: Int64 {
        max(0, totalBytes - availableBytes)
    }

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1.0, max(0.0, Double(usedBytes) / Double(totalBytes)))
    }

    var freePercentage: Double {
        max(0.0, 1.0 - usedPercentage)
    }

    var isLowStorage: Bool {
        freePercentage < 0.15
    }

    static let empty = DeviceStorageInfo(
        totalBytes: 0,
        availableBytes: 0,
        importantAvailableBytes: 0,
        opportunisticAvailableBytes: 0,
        appSandboxUsedBytes: 0,
        timestamp: Date()
    )
}

/// Represents a user-selected or sandbox-managed file in Storage Manager.
struct SandboxFileItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    let sizeBytes: Int64
    let modificationDate: Date
    let contentTypeDescription: String
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        sizeBytes: Int64,
        modificationDate: Date,
        contentTypeDescription: String,
        isSelected: Bool = false
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.sizeBytes = sizeBytes
        self.modificationDate = modificationDate
        self.contentTypeDescription = contentTypeDescription
        self.isSelected = isSelected
    }
}
