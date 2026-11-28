import Foundation
import WebKit

/// Granular classification of cache and data stores within Booster Pro's sandbox and protected areas.
enum CacheEntryType: String, CaseIterable, Codable, Identifiable {
    // 1. URL & Network caches
    case urlNetworkCache
    case urlSessionCache
    case urlCacheMemory
    case urlCacheDisk

    // 2. Image & Thumbnail caches
    case imageCache
    case imageThumbnailCache
    case generatedPreviews

    // 3. Temporary files
    case temporarySnapshots
    case temporaryFiles
    case expiredDownloads

    // 4. WebKit / WebView data
    case webViewCache
    case webViewWebsiteData

    // 5. App sandbox directories
    case appCacheDirectories
    case diagnosticLogs

    // 6. Protected user data (NEVER DELETABLE)
    case protectedUserSettings
    case protectedUserDocuments
    case protectedDatabase

    var id: String { rawValue }

    var isSafeToCleanByDefault: Bool {
        switch self {
        case .urlNetworkCache, .urlSessionCache, .urlCacheMemory, .urlCacheDisk,
             .imageCache, .imageThumbnailCache, .generatedPreviews,
             .temporarySnapshots, .temporaryFiles, .expiredDownloads,
             .webViewCache, .appCacheDirectories, .diagnosticLogs:
            return true
        case .webViewWebsiteData:
            // Cookies, local storage, session data: sensitive, requires user confirmation
            return false
        case .protectedUserSettings, .protectedUserDocuments, .protectedDatabase:
            return false
        }
    }

    var iconName: String {
        switch self {
        case .urlNetworkCache, .urlSessionCache:
            return "network"
        case .urlCacheMemory:
            return "memorychip"
        case .urlCacheDisk:
            return "internaldrive"
        case .imageCache, .imageThumbnailCache:
            return "photo.on.rectangle.angled"
        case .generatedPreviews:
            return "eye.circle"
        case .temporarySnapshots, .temporaryFiles:
            return "clock.arrow.circlepath"
        case .expiredDownloads:
            return "arrow.down.circle"
        case .webViewCache:
            return "globe"
        case .webViewWebsiteData:
            return "lock.shield"
        case .appCacheDirectories:
            return "folder.badge.gearshape"
        case .diagnosticLogs:
            return "list.clipboard"
        case .protectedUserSettings:
            return "gearshape.fill"
        case .protectedUserDocuments:
            return "doc.fill"
        case .protectedDatabase:
            return "cylinder.split.1x2.fill"
        }
    }
}

/// Represents either an app-managed cleanable cache partition or a protected user data store.
struct CachePartitionItem: Identifiable, Hashable {
    let id: UUID
    let type: CacheEntryType
    let title: String
    let subtitle: String
    let directoryURL: URL?
    let sizeBytes: Int64
    let fileCount: Int
    let lastModifiedDate: Date?
    let isDeletable: Bool
    let isSafeToClean: Bool
    let isCurrentlyInUse: Bool
    let estimatedAfterCleanBytes: Int64
    let requiresExplicitConfirmation: Bool
    var isSelected: Bool
    let protectionReason: String?
    let riskWarning: String?

    init(
        id: UUID = UUID(),
        type: CacheEntryType,
        title: String,
        subtitle: String,
        directoryURL: URL? = nil,
        sizeBytes: Int64,
        fileCount: Int = 1,
        lastModifiedDate: Date? = nil,
        isDeletable: Bool = true,
        isSafeToClean: Bool = true,
        isCurrentlyInUse: Bool = false,
        estimatedAfterCleanBytes: Int64 = 0,
        requiresExplicitConfirmation: Bool = false,
        isSelected: Bool = true,
        protectionReason: String? = nil,
        riskWarning: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.directoryURL = directoryURL
        self.sizeBytes = sizeBytes
        self.fileCount = fileCount
        self.lastModifiedDate = lastModifiedDate
        self.isDeletable = isDeletable
        self.isSafeToClean = isDeletable && isSafeToClean
        self.isCurrentlyInUse = isCurrentlyInUse
        self.estimatedAfterCleanBytes = estimatedAfterCleanBytes
        self.requiresExplicitConfirmation = requiresExplicitConfirmation
        self.isSelected = isDeletable ? isSelected : false
        self.protectionReason = protectionReason
        self.riskWarning = riskWarning
    }
}

/// Comprehensive before/after result from a cache cleanup operation.
struct CacheCleanupResult: Equatable {
    let beforeCleanableBytes: Int64
    let afterCleanableBytes: Int64
    let freedBytes: Int64
    let cleanedPartitionsCount: Int
    let protectedBytesUntouched: Int64
    let filesRemovedCount: Int
    let failedItemsCount: Int
    let failedItemPaths: [String]
    let cleanupDurationSeconds: Double
    let cleanedCategoryTitles: [String]
    let timestamp: Date

    init(
        beforeCleanableBytes: Int64,
        afterCleanableBytes: Int64,
        freedBytes: Int64,
        cleanedPartitionsCount: Int,
        protectedBytesUntouched: Int64,
        filesRemovedCount: Int = 0,
        failedItemsCount: Int = 0,
        failedItemPaths: [String] = [],
        cleanupDurationSeconds: Double = 0.0,
        cleanedCategoryTitles: [String] = [],
        timestamp: Date = Date()
    ) {
        self.beforeCleanableBytes = beforeCleanableBytes
        self.afterCleanableBytes = afterCleanableBytes
        self.freedBytes = freedBytes
        self.cleanedPartitionsCount = cleanedPartitionsCount
        self.protectedBytesUntouched = protectedBytesUntouched
        self.filesRemovedCount = filesRemovedCount
        self.failedItemsCount = failedItemsCount
        self.failedItemPaths = failedItemPaths
        self.cleanupDurationSeconds = cleanupDurationSeconds
        self.cleanedCategoryTitles = cleanedCategoryTitles
        self.timestamp = timestamp
    }
}

/// Representation of a website data record stored by WebKit in Booster Pro's sandbox.
struct WebViewWebsiteDataRecordItem: Identifiable, Hashable {
    let id: String
    let displayName: String
    let dataTypes: [String]
    let isCacheOnly: Bool
    let hasCookiesOrAuth: Bool
    var isSelected: Bool

    init(
        id: String = UUID().uuidString,
        displayName: String,
        dataTypes: [String],
        isCacheOnly: Bool,
        hasCookiesOrAuth: Bool,
        isSelected: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.dataTypes = dataTypes
        self.isCacheOnly = isCacheOnly
        self.hasCookiesOrAuth = hasCookiesOrAuth
        self.isSelected = isSelected
    }
}

/// Historical log record of an App Cache cleanup session for user transparency.
struct CacheHistoryRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let trigger: String
    let bytesFreed: Int64
    let filesRemoved: Int
    let durationSeconds: Double
    let cleanedCategories: [String]
    let wasSuccessful: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        trigger: String,
        bytesFreed: Int64,
        filesRemoved: Int,
        durationSeconds: Double,
        cleanedCategories: [String],
        wasSuccessful: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.trigger = trigger
        self.bytesFreed = bytesFreed
        self.filesRemoved = filesRemoved
        self.durationSeconds = durationSeconds
        self.cleanedCategories = cleanedCategories
        self.wasSuccessful = wasSuccessful
    }
}
