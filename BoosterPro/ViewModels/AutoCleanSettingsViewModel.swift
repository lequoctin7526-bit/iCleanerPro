import Foundation
import SwiftUI
import Combine

@MainActor
final class AutoCleanSettingsViewModel: ObservableObject {
    @Published var config: AutoCleanConfiguration = .default
    @Published var history: [AutoCleanHistoryRecord] = []

    // Progress & state
    @Published var isCleaning: Bool = false
    @Published var cleaningProgressStep: String = ""
    @Published var activeProgressRatio: Double = 0.0
    @Published var statusMessage: String = ""

    // Dialogs & Sheets
    @Published var showHistorySheet: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showClearHistoryConfirmation: Bool = false
    @Published var selectedHistoryRecord: AutoCleanHistoryRecord? = nil

    private let service = AutoCleanSchedulerService.shared
    private var cleaningTask: Task<Void, Never>? = nil

    init() {
        loadData()
    }

    func loadData() {
        config = service.loadConfiguration()
        history = service.loadHistory()
    }

    func saveConfiguration() {
        service.saveConfiguration(config)
        service.scheduleNextBackgroundTask()
    }

    func resetToDefaults() {
        config = service.resetConfigurationToDefaults()
        service.scheduleNextBackgroundTask()
        statusMessage = "Đã khôi phục cài đặt mặc định thành công."
    }

    func clearHistory() {
        service.clearHistory()
        history = []
        statusMessage = "Đã xóa toàn bộ lịch sử dọn dẹp."
    }

    // MARK: - Manual Clean Now
    func cleanNow() {
        guard !isCleaning else { return }

        isCleaning = true
        activeProgressRatio = 0.0
        cleaningProgressStep = "Đang khởi tạo quy trình dọn dẹp..."

        cleaningTask = Task {
            let result = await service.executeClean(
                trigger: "Thủ công (CLEAN NOW)",
                isBackground: false
            ) { [weak self] stepName, ratio in
                Task { @MainActor in
                    self?.cleaningProgressStep = stepName
                    self?.activeProgressRatio = ratio
                }
            }

            self.loadData()
            self.statusMessage = result.statusMessage
            self.isCleaning = false
            self.cleaningTask = nil
        }
    }

    func cancelCleaning() {
        service.requestCancellation()
        cleaningTask?.cancel()
        cleaningProgressStep = "Đang dừng tác vụ..."
    }

    // MARK: - Schedule Helpers
    func toggleDayOfWeek(_ day: Int) {
        if config.schedule.selectedDaysOfWeek.contains(day) {
            // Keep at least 1 day selected
            if config.schedule.selectedDaysOfWeek.count > 1 {
                config.schedule.selectedDaysOfWeek.remove(day)
            }
        } else {
            config.schedule.selectedDaysOfWeek.insert(day)
        }
        saveConfiguration()
    }

    // MARK: - Computed Display Helpers
    var statusBadgeText: String {
        if !config.isMasterEnabled {
            return "Đang tắt"
        }
        if isCleaning {
            return "Đang dọn dẹp..."
        }
        return "Sẵn sàng"
    }

    var statusBadgeColor: Color {
        if !config.isMasterEnabled {
            return .secondary
        }
        if isCleaning {
            return .orange
        }
        return Color(hex: "#00F5A0")
    }

    var nextScheduledTimeText: String {
        guard config.isMasterEnabled && config.schedule.isScheduleEnabled else {
            return "Chưa lập lịch"
        }

        switch config.schedule.frequency {
        case .onAppOpen:
            return "Mỗi khi mở Booster Pro"
        case .beforeGaming:
            return "Trước khi chơi game"
        case .onReturnFromGaming:
            return "Khi quay lại sau phiên chơi game"
        case .onLowStorage:
            return "Khi dung lượng trống < 15%"
        case .daily, .weekly:
            if let nextDate = service.calculateNextScheduledDate(schedule: config.schedule) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "vi_VN")
                formatter.dateFormat = "HH:mm, EEEE dd/MM"
                return formatter.string(from: nextDate)
            } else {
                return "Theo lịch (\(config.schedule.formattedTime))"
            }
        }
    }

    var lastCleanTimeText: String {
        guard let last = config.lastCleanDate else {
            return "Chưa thực hiện"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm - dd/MM/yyyy"
        return formatter.string(from: last)
    }

    var totalFreedText: String {
        ByteFormatterUtil.format(config.totalBytesFreedAllTime)
    }
}
