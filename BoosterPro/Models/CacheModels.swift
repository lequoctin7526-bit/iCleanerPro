import Foundation

enum CacheEntryType: String, CaseIterable, Identifiable {
    case urlNetworkCache
    case imageThumbnailCache
    case temporarySnapshots
    case diagnosticLogs
    case protectedUserSettings
    case protectedUserDocuments

    var id: String { rawValue }
}

/// Represents either a cleanable app cache partition or a protected user data store.
struct CachePartitionItem: Identifiable, Hashable {
    let id: UUID
    let type: CacheEntryType
    let title: String
    let subtitle: String
    let directoryURL: URL?
    let sizeBytes: Int64
    let fileCount: Int
    let isDeletable: Bool
    var isSelected: Bool
    let protectionReason: String?

    init(
        id: UUID = UUID(),
        type: CacheEntryType,
        title: String,
        subtitle: String,
        directoryURL: URL?,
        sizeBytes: Int64,
        fileCount: Int,
        isDeletable: Bool,
        isSelected: Bool,
        protectionReason: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.directoryURL = directoryURL
        self.sizeBytes = sizeBytes
        self.fileCount = fileCount
        self.isDeletable = isDeletable
        self.isSelected = isDeletable ? isSelected : false
        self.protectionReason = protectionReason
    }
}

struct CacheCleanupResult: Equatable {
    let beforeCleanableBytes: Int64
    let afterCleanableBytes: Int64
    let freedBytes: Int64
    let cleanedPartitionsCount: Int
    let protectedBytesUntouched: Int64
    let timestamp: Date
}
