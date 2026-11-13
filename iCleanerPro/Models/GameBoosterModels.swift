import Foundation
import UIKit

/// Categories of mobile games.
enum GameCategory: String, CaseIterable, Identifiable, Codable {
    case moba = "MOBA"
    case battleRoyale = "Battle Royale"
    case fps = "Bắn súng (FPS)"
    case rpg = "Nhập vai (RPG)"
    case racing = "Đua xe (Racing)"
    case strategy = "Chiến thuật"
    case casual = "Giải trí / Casual"
    case other = "Khác"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .moba: return "shield.lefthalf.filled"
        case .battleRoyale: return "cross.vial.fill"
        case .fps: return "scope"
        case .rpg: return "wand.and.stars"
        case .racing: return "flag.checkered"
        case .strategy: return "checkerboard.rectangle"
        case .casual: return "gamecontroller"
        case .other: return "sparkles"
        }
    }
}

/// Represents a game in the user's Game Library.
struct GameItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: GameCategory
    var urlScheme: String?
    var iconSymbol: String
    var colorHex: String
    let createdAt: Date
    var lastPlayed: Date?
    var playCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: GameCategory,
        urlScheme: String? = nil,
        iconSymbol: String = "gamecontroller.fill",
        colorHex: String = "#00F5A0",
        createdAt: Date = Date(),
        lastPlayed: Date? = nil,
        playCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.urlScheme = urlScheme
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.lastPlayed = lastPlayed
        self.playCount = playCount
    }
}

/// Gaming configuration presets for balancing performance, battery, and focus.
enum GamePresetMode: String, CaseIterable, Identifiable, Codable {
    case balanced = "Cân bằng"
    case performance = "Hiệu năng cao"
    case batterySaver = "Tiết kiệm pin"
    case gamingFocus = "Tập trung thi đấu"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .balanced:
            return "60 FPS ổn định, nhiệt độ vừa phải & tiêu hao pin cân bằng"
        case .performance:
            return "Ưu tiên độ mượt tối đa, mở khóa ProMotion 120Hz & giảm tải hệ thống"
        case .batterySaver:
            return "Kéo dài thời lượng chơi, giảm nhiệt độ & hạn chế hao pin"
        case .gamingFocus:
            return "Chặn gián đoạn từ thông báo, cuộc gọi & tin nhắn mạng xã hội"
        }
    }

    var iconName: String {
        switch self {
        case .balanced: return "scale.3d"
        case .performance: return "bolt.fill"
        case .batterySaver: return "battery.75"
        case .gamingFocus: return "moon.stars.fill"
        }
    }

    var recommendedGuidelines: [String] {
        switch self {
        case .balanced:
            return [
                "Độ sáng màn hình khuyến nghị: 50% – 65%",
                "Bật giới hạn tốc độ khung hình 60 FPS trong cài đặt game",
                "Đóng các ứng dụng chạy ngầm trước khi vào trận"
            ]
        case .performance:
            return [
                "TẮT Chế độ Nguồn điện thấp để CPU/GPU hoạt động hết công suất",
                "Tháo ốp lưng dày nếu chơi liên tục để tản nhiệt tự nhiên tốt hơn",
                "Đóng tất cả ứng dụng trong App Switcher trước khi khởi động game",
                "Không vừa sạc nhanh vừa chơi game nặng để tránh nghẽn nhiệt"
            ]
        case .batterySaver:
            return [
                "BẬT Chế độ Nguồn điện thấp nếu pin dưới 30%",
                "Giảm độ sáng màn hình xuống 35% – 45%",
                "Hạn chế âm lượng loa ngoài hoặc dùng tai nghe có dây"
            ]
        case .gamingFocus:
            return [
                "BẬT Focus Mode (Chế độ Chơi game / Không làm phiền) trong Trung tâm điều khiển",
                "Tắt thông báo biểu ngữ của Zalo, Messenger, Facebook",
                "Bật tính năng Giới hạn truy cập (Guided Access) nếu muốn khóa cử chỉ vuốt về Home"
            ]
        }
    }
}

/// Device readiness assessment level before starting a game.
enum GameReadinessLevel: String, Codable {
    case optimal = "Tốt"
    case moderate = "Trung bình"
    case needsOptimization = "Cần tối ưu"
}

/// Real device gaming readiness assessment based on public APIs.
struct GameReadinessReport: Equatable {
    let level: GameReadinessLevel
    let score: Int
    let summary: String
    let ramAvailableBytes: UInt64
    let storageFreeBytes: Int64
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerMode: Bool
    let batteryLevel: Float
    let recommendations: [String]

    var thermalTitle: String {
        switch thermalState {
        case .nominal: return "Mát (Bình thường)"
        case .fair: return "Hơi ấm"
        case .serious: return "Nóng (Có thể tụt FPS)"
        case .critical: return "Quá nhiệt (Giới hạn CPU)"
        @unknown default: return "Không xác định"
        }
    }
}

/// Interactive checklist items to prepare device before gaming.
struct GamingChecklistItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let iconName: String
    var isCompleted: Bool
    var isOptional: Bool
    var targetSettingDescription: String
}

/// Recorded history of a gaming session.
struct GameSessionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let gameId: UUID?
    let gameName: String
    let presetMode: String
    let startTime: Date
    let endTime: Date
    let durationSeconds: TimeInterval
    let initialReadinessScore: Int
    let initialThermalTitle: String
    let finalThermalTitle: String
    let batteryLevelStart: Float
    let batteryLevelEnd: Float

    var formattedDuration: String {
        let mins = Int(durationSeconds) / 60
        let secs = Int(durationSeconds) % 60
        if mins >= 60 {
            let hours = mins / 60
            let remMins = mins % 60
            return "\(hours)h \(remMins)m"
        }
        return "\(mins)m \(secs)s"
    }
}

/// Real verified result from executing the "BOOST NOW" gaming routine.
struct GameOptimizationSnapshot: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let freedAppMemoryBytes: Int64
    let freedCacheBytes: Int64
    let appFootprintBefore: UInt64
    let appFootprintAfter: UInt64
    let storageFreeBefore: Int64
    let storageFreeAfter: Int64
    let verifiedSteps: [String]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        freedAppMemoryBytes: Int64,
        freedCacheBytes: Int64,
        appFootprintBefore: UInt64,
        appFootprintAfter: UInt64,
        storageFreeBefore: Int64,
        storageFreeAfter: Int64,
        verifiedSteps: [String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.freedAppMemoryBytes = freedAppMemoryBytes
        self.freedCacheBytes = freedCacheBytes
        self.appFootprintBefore = appFootprintBefore
        self.appFootprintAfter = appFootprintAfter
        self.storageFreeBefore = storageFreeBefore
        self.storageFreeAfter = storageFreeAfter
        self.verifiedSteps = verifiedSteps
    }
}
