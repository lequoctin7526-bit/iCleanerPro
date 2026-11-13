import Foundation

/// Categories of cleanable sandbox files within the app container.
enum JunkCategory: String, CaseIterable, Identifiable, Codable {
    case temporaryFiles
    case logFiles
    case orphanedCaches
    case largeSandboxFiles
    case importStaging

    var id: String { rawValue }

    var title: String {
        switch self {
        case .temporaryFiles:
            return "File tạm hệ thống ứng dụng"
        case .logFiles:
            return "Nhật ký chẩn đoán (Logs)"
        case .orphanedCaches:
            return "Bộ nhớ đệm dư thừa"
        case .largeSandboxFiles:
            return "File dung lượng lớn (Sandbox)"
        case .importStaging:
            return "Dữ liệu tạm từ Import/Download"
        }
    }

    var iconName: String {
        switch self {
        case .temporaryFiles:
            return "doc.badge.clock"
        case .logFiles:
            return "doc.text.magnifyingglass"
        case .orphanedCaches:
            return "internaldrive"
        case .largeSandboxFiles:
            return "externaldrive.badge.exclamationmark"
        case .importStaging:
            return "tray.and.arrow.down"
        }
    }

    var safetyNote: String {
        switch self {
        case .temporaryFiles:
            return "An toàn để xóa. Dữ liệu tạm trong tmp/ sẽ được tạo lại khi cần."
        case .logFiles:
            return "An toàn để xóa. Chỉ chứa nhật ký hoạt động nội bộ."
        case .orphanedCaches:
            return "An toàn để xóa. Không ảnh hưởng đến cài đặt hay tài khoản."
        case .largeSandboxFiles:
            return "Kiểm tra kỹ trước khi xóa nếu đó là file bạn đã tải về."
        case .importStaging:
            return "File trung gian khi xử lý tệp; an toàn để dọn dẹp."
        }
    }
}

/// Size classification tier for junk files.
enum JunkSizeTier: String, CaseIterable, Identifiable {
    case small = "< 1 MB"
    case medium = "1 – 10 MB"
    case large = "10 – 50 MB"
    case huge = "> 50 MB"

    var id: String { rawValue }

    static func tier(for bytes: Int64) -> JunkSizeTier {
        let mb: Int64 = 1_048_576
        if bytes < mb {
            return .small
        } else if bytes < 10 * mb {
            return .medium
        } else if bytes < 50 * mb {
            return .large
        } else {
            return .huge
        }
    }
}

/// Represents a concrete file discovered inside the iOS sandbox that can be inspected or deleted.
struct JunkItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    let pathDescription: String
    let sizeBytes: Int64
    let category: JunkCategory
    let sizeTier: JunkSizeTier
    let createdAt: Date
    let modifiedAt: Date
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        pathDescription: String,
        sizeBytes: Int64,
        category: JunkCategory,
        createdAt: Date,
        modifiedAt: Date,
        isSelected: Bool = true
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.pathDescription = pathDescription
        self.sizeBytes = sizeBytes
        self.category = category
        self.sizeTier = JunkSizeTier.tier(for: sizeBytes)
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isSelected = isSelected
    }
}

/// Real verified result after performing sandbox junk cleanup.
struct JunkCleanupSummary: Equatable {
    let beforeTotalBytes: Int64
    let afterTotalBytes: Int64
    let freedBytes: Int64
    let deletedFilesCount: Int
    let failedFilesCount: Int
    let timestamp: Date
}
