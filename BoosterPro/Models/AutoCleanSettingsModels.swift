import Foundation

// MARK: - Auto Clean Frequency
/// Frequency options for automatic cleanup execution.
enum AutoCleanFrequency: String, CaseIterable, Codable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case onAppOpen = "onAppOpen"
    case beforeGaming = "beforeGaming"
    case onReturnFromGaming = "onReturnFromGaming"
    case onLowStorage = "onLowStorage"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:
            return "Mỗi ngày"
        case .weekly:
            return "Mỗi tuần"
        case .onAppOpen:
            return "Khi mở ứng dụng"
        case .beforeGaming:
            return "Trước khi chơi game"
        case .onReturnFromGaming:
            return "Khi quay lại sau phiên chơi game"
        case .onLowStorage:
            return "Khi dung lượng lưu trữ thấp (< 15%)"
        }
    }

    var icon: String {
        switch self {
        case .daily:
            return "calendar.day.timeline.left"
        case .weekly:
            return "calendar"
        case .onAppOpen:
            return "arrow.up.forward.app.fill"
        case .beforeGaming:
            return "gamecontroller.fill"
        case .onReturnFromGaming:
            return "arrow.uturn.backward.circle.fill"
        case .onLowStorage:
            return "exclamationmark.triangle.fill"
        }
    }

    var detailDescription: String {
        switch self {
        case .daily:
            return "Tự động dọn dẹp hàng ngày theo giờ bạn thiết lập."
        case .weekly:
            return "Tự động dọn dẹp vào những ngày được chọn trong tuần."
        case .onAppOpen:
            return "Kích hoạt dọn dẹp nhanh mỗi khi bạn mở ứng dụng Booster Pro."
        case .beforeGaming:
            return "Tự động giải phóng cache nội bộ và RAM ứng dụng trước khi khởi chạy game."
        case .onReturnFromGaming:
            return "Dọn dẹp tài nguyên và cache đệm ngay khi bạn kết thúc game quay lại ứng dụng."
        case .onLowStorage:
            return "Kích hoạt cảnh báo và dọn dẹp khi dung lượng khả dụng của thiết bị xuống dưới 15%."
        }
    }
}

// MARK: - Selectable Data Categories
/// Independent toggles for safe cleanup categories within Booster Pro's sandbox.
struct AutoCleanDataOptions: Codable, Hashable {
    var cleanJunkFiles: Bool = true
    var cleanTemporaryFiles: Bool = true
    var cleanAppCache: Bool = true
    var cleanAppLogs: Bool = true
    var cleanAppMemory: Bool = true
    var cleanGameResources: Bool = true

    static var allEnabled: AutoCleanDataOptions {
        AutoCleanDataOptions()
    }

    static var minimal: AutoCleanDataOptions {
        AutoCleanDataOptions(
            cleanJunkFiles: true,
            cleanTemporaryFiles: true,
            cleanAppCache: false,
            cleanAppLogs: false,
            cleanAppMemory: true,
            cleanGameResources: false
        )
    }

    var enabledCount: Int {
        var count = 0
        if cleanJunkFiles { count += 1 }
        if cleanTemporaryFiles { count += 1 }
        if cleanAppCache { count += 1 }
        if cleanAppLogs { count += 1 }
        if cleanAppMemory { count += 1 }
        if cleanGameResources { count += 1 }
        return count
    }
}

// MARK: - Smart Execution Conditions
/// Safety conditions that must be met before an auto clean task is allowed to proceed.
struct AutoCleanConditions: Codable, Hashable {
    var chargingOnly: Bool = false
    var activeAppOnly: Bool = false
    var lowBatteryProtection: Bool = true
    var thermalProtection: Bool = true
    var lowStorageThresholdPercent: Double = 15.0

    static var `default`: AutoCleanConditions {
        AutoCleanConditions()
    }
}

// MARK: - Auto Clean Schedule
/// Schedule configuration for periodic background and time-based cleanup.
struct AutoCleanSchedule: Codable, Hashable {
    var isScheduleEnabled: Bool = true
    var frequency: AutoCleanFrequency = .daily
    var startHour: Int = 2 // 02:00 AM
    var startMinute: Int = 0
    var selectedDaysOfWeek: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // 1=Sun, 2=Mon... 7=Sat

    static var `default`: AutoCleanSchedule {
        AutoCleanSchedule()
    }

    var formattedTime: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var daysSummary: String {
        if selectedDaysOfWeek.count == 7 {
            return "Hàng ngày"
        } else if selectedDaysOfWeek == [2, 3, 4, 5, 6] {
            return "Các ngày trong tuần (T2 - T6)"
        } else if selectedDaysOfWeek == [1, 7] {
            return "Cuối tuần (T7, CN)"
        } else {
            let names = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
            let sorted = selectedDaysOfWeek.sorted().compactMap { day -> String? in
                guard day >= 1 && day <= 7 else { return nil }
                return names[day - 1]
            }
            return sorted.joined(separator: ", ")
        }
    }
}

// MARK: - Auto Clean History Record
/// Persistent record of an auto clean execution session.
struct AutoCleanHistoryRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var timestamp: Date
    var triggerReason: String
    var categoriesCleaned: [String]
    var beforeBytes: Int64
    var afterBytes: Int64
    var bytesFreed: Int64
    var durationSeconds: TimeInterval
    var wasSuccessful: Bool
    var statusMessage: String
    var skippedReason: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        triggerReason: String,
        categoriesCleaned: [String],
        beforeBytes: Int64,
        afterBytes: Int64,
        bytesFreed: Int64,
        durationSeconds: TimeInterval,
        wasSuccessful: Bool,
        statusMessage: String,
        skippedReason: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.triggerReason = triggerReason
        self.categoriesCleaned = categoriesCleaned
        self.beforeBytes = beforeBytes
        self.afterBytes = afterBytes
        self.bytesFreed = bytesFreed
        self.durationSeconds = durationSeconds
        self.wasSuccessful = wasSuccessful
        self.statusMessage = statusMessage
        self.skippedReason = skippedReason
    }
}

// MARK: - Master Auto Clean Configuration
/// Complete configuration model persisted in UserDefaults.
struct AutoCleanConfiguration: Codable, Hashable {
    var isMasterEnabled: Bool = true
    var schedule: AutoCleanSchedule = .default
    var dataOptions: AutoCleanDataOptions = .allEnabled
    var conditions: AutoCleanConditions = .default
    var lastCleanDate: Date? = nil
    var totalBytesFreedAllTime: Int64 = 0
    var successfulCleansCount: Int = 0
    var failedCleansCount: Int = 0

    static var `default`: AutoCleanConfiguration {
        AutoCleanConfiguration()
    }
}

// MARK: - Auto Clean Result Snapshot
/// In-flight result returned after a cleanup pass.
struct AutoCleanExecutionResult {
    let wasSuccessful: Bool
    let trigger: String
    let categories: [String]
    let bytesFreed: Int64
    let durationSeconds: TimeInterval
    let statusMessage: String
    let skippedReason: String?
}
