import Foundation

/// Lifecycle states for Smart Scan and Clean operations.
enum ScanPhase: Equatable {
    case idle
    case scanningStorage
    case scanningJunk
    case scanningCache
    case scanningMemory
    case scanningDeviceHealth
    case completed
    case cleaning
    case cleaned
    case error(String)

    var isBusy: Bool {
        switch self {
        case .scanningStorage, .scanningJunk, .scanningCache, .scanningMemory, .scanningDeviceHealth, .cleaning:
            return true
        default:
            return false
        }
    }

    var statusLabel: String {
        switch self {
        case .idle:
            return "Sẵn sàng quét hệ thống"
        case .scanningStorage:
            return "Đang phân tích dung lượng lưu trữ..."
        case .scanningJunk:
            return "Đang quét file tạm và rác sandbox..."
        case .scanningCache:
            return "Đang kiểm tra bộ nhớ đệm ứng dụng..."
        case .scanningMemory:
            return "Đang đo lường mức sử dụng RAM..."
        case .scanningDeviceHealth:
            return "Đang đánh giá CPU và hiệu năng..."
        case .completed:
            return "Hoàn tất phân tích"
        case .cleaning:
            return "Đang dọn dẹp an toàn..."
        case .cleaned:
            return "Dọn dẹp hoàn tất"
        case .error(let message):
            return "Lỗi: \(message)"
        }
    }
}

/// Real-time progress item shown on the Scan screen.
struct ScanStageProgress: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    var progress: Double
    var foundBytes: Int64
    var foundItemsCount: Int
    var isCompleted: Bool
}

/// Comprehensive before/after report displayed on ScanResultView.
struct ComprehensiveScanReport: Equatable {
    let beforeStorageAvailableBytes: Int64
    let afterStorageAvailableBytes: Int64
    let beforeAppFootprintBytes: UInt64
    let afterAppFootprintBytes: UInt64
    let totalReclaimableBytesFound: Int64
    let totalFilesProcessed: Int
    let actualFreedDiskBytes: Int64
    let actualReclaimedRAMBytes: Int64
    let timestamp: Date

    var totalCombinedFreedBytes: Int64 {
        actualFreedDiskBytes + max(0, actualReclaimedRAMBytes)
    }
}
