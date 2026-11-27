import Foundation
import Photos

enum PhotoPermissionState: Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    var canAccessPhotos: Bool {
        self == .authorized || self == .limited
    }

    var descriptionText: String {
        switch self {
        case .notDetermined:
            return "Chưa cấp quyền truy cập Thư viện Ảnh."
        case .authorized:
            return "Đã cấp quyền truy cập đầy đủ Thư viện Ảnh."
        case .limited:
            return "Đang sử dụng quyền truy cập giới hạn (chỉ ảnh bạn đã chọn)."
        case .denied:
            return "Quyền truy cập Ảnh đã bị từ chối trong Cài đặt."
        case .restricted:
            return "Quyền truy cập Ảnh bị giới hạn bởi thiết bị/MDM."
        }
    }
}

/// Wraps a real PHAsset along with its computed byte size and selection state.
struct MediaAssetItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset?
    let mediaType: PHAssetMediaType
    let fileSizeBytes: Int64
    let isEstimatedSize: Bool
    let isLocallyAvailable: Bool
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    var isSelected: Bool

    init(
        id: String,
        asset: PHAsset? = nil,
        mediaType: PHAssetMediaType = .image,
        fileSizeBytes: Int64,
        isEstimatedSize: Bool = false,
        isLocallyAvailable: Bool = true,
        creationDate: Date? = nil,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        duration: TimeInterval = 0,
        isSelected: Bool = false
    ) {
        self.id = id
        self.asset = asset
        self.mediaType = mediaType
        self.fileSizeBytes = fileSizeBytes
        self.isEstimatedSize = isEstimatedSize
        self.isLocallyAvailable = isLocallyAvailable
        self.creationDate = creationDate
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.duration = duration
        self.isSelected = isSelected
    }

    var resolutionLabel: String {
        "\(pixelWidth)×\(pixelHeight)"
    }

    var isVideo: Bool {
        mediaType == .video
    }

    var isScreenshot: Bool {
        asset?.mediaSubtypes.contains(.photoScreenshot) ?? false
    }

    var isHighResolution: Bool {
        pixelWidth * pixelHeight >= 12_000_000
    }

    var formattedSize: String {
        let base = ByteFormatterUtil.formatFileSize(fileSizeBytes)
        if isEstimatedSize {
            return "~\(base) (Ước lượng)"
        }
        return base
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MediaAssetItem, rhs: MediaAssetItem) -> Bool {
        lhs.id == rhs.id && lhs.isSelected == rhs.isSelected && lhs.fileSizeBytes == rhs.fileSizeBytes
    }
}

/// Group of duplicate or visually similar photos detected via perceptual dHash + Vision FeaturePrint.
struct DuplicatePhotoGroup: Identifiable, Hashable {
    enum MatchType: String {
        case exactHash = "Trùng khớp chính xác"
        case visualSimilar = "Ảnh tương tự"
    }

    let id: UUID
    let matchType: MatchType
    let similarityScore: Float
    var assets: [MediaAssetItem]
    let recommendedKeepAssetID: String

    var reclaimableBytes: Int64 {
        assets
            .filter { $0.id != recommendedKeepAssetID && $0.isSelected }
            .reduce(0) { $0 + $1.fileSizeBytes }
    }

    var totalGroupBytes: Int64 {
        assets.reduce(0) { $0 + $1.fileSizeBytes }
    }

    init(
        id: UUID = UUID(),
        matchType: MatchType,
        similarityScore: Float,
        assets: [MediaAssetItem],
        recommendedKeepAssetID: String
    ) {
        self.id = id
        self.matchType = matchType
        self.similarityScore = similarityScore
        self.assets = assets
        self.recommendedKeepAssetID = recommendedKeepAssetID
    }
}
