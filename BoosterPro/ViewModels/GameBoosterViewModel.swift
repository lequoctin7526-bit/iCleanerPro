import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class GameBoosterViewModel: ObservableObject {
    @Published var readinessReport: GameReadinessReport
    @Published var selectedPreset: GamePresetMode = .performance
    @Published var games: [GameItem] = []
    @Published var checklistItems: [GamingChecklistItem] = []
    @Published var sessionHistory: [GameSessionRecord] = []
    @Published var optimizationHistory: [GameOptimizationSnapshot] = []

    // Live Metrics
    @Published var appRamFootprint: UInt64 = 0
    @Published var appCpuUsagePercent: Double = 0.0
    @Published var freeStorageBytes: Int64 = 0
    @Published var thermalStateTitle: String = "Bình thường"
    @Published var isLowPowerMode: Bool = false
    @Published var batteryLevelPercent: Int = 100

    // BOOST NOW state
    @Published var isOptimizing = false
    @Published var optimizationStepMessage = ""
    @Published var lastOptimization: GameOptimizationSnapshot?
    @Published var showBoostSuccessSheet = false

    // Active Game Session
    @Published var activeGame: GameItem?
    @Published var sessionStartTime: Date?
    @Published var sessionDurationFormatted: String = "00:00:00"
    @Published var isSessionActive = false
    @Published var showSessionEndSummary = false
    @Published var lastCompletedSession: GameSessionRecord?

    // UI Feedback
    @Published var launchNotice: String?

    private let boosterService = GameBoosterService.shared
    private let memoryService = MemoryMonitorService()
    private let deviceService = DeviceMonitorService()
    private let storageService = StorageManagerService()

    private var metricsTimer: AnyCancellable?
    private var sessionTimer: AnyCancellable?
    private let checklistStorageKey = "BoosterPro_gaming_checklist_v1"

    init() {
        self.readinessReport = boosterService.evaluateReadiness()
        loadInitialData()
        startLiveMonitoring()
    }

    func loadInitialData() {
        self.games = boosterService.loadGames()
        self.sessionHistory = boosterService.loadSessions()
        self.optimizationHistory = boosterService.loadOptimizationHistory()
        self.checklistItems = loadChecklist()
        refreshLiveMetrics()
    }

    // MARK: - Live Monitoring
    func startLiveMonitoring() {
        refreshLiveMetrics()
        metricsTimer?.cancel()
        metricsTimer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshLiveMetrics()
            }
    }

    func stopLiveMonitoring() {
        metricsTimer?.cancel()
        metricsTimer = nil
    }

    func refreshLiveMetrics() {
        let ram = memoryService.captureSnapshot()
        let cpu = deviceService.collectCPUMetrics()
        let storage = storageService.fetchDeviceStorageInfo()

        self.appRamFootprint = ram.appFootprintBytes
        self.appCpuUsagePercent = cpu.appCPUUsagePercent
        self.freeStorageBytes = storage.availableBytes
        self.thermalStateTitle = cpu.thermalStateTitle
        self.isLowPowerMode = cpu.isLowPowerMode
        self.batteryLevelPercent = cpu.batteryLevel >= 0 ? Int(cpu.batteryLevel * 100) : 100
        self.readinessReport = boosterService.evaluateReadiness()
    }

    // MARK: - BOOST NOW Routine
    func performBoostNow() async {
        isOptimizing = true
        optimizationStepMessage = "Đang dọn dẹp bộ nhớ đệm và tệp tạm trong ứng dụng..."

        try? await Task.sleep(nanoseconds: 350_000_000)
        optimizationStepMessage = "Đang phân tích và thu hồi bộ nhớ ứng dụng..."

        let snapshot = await boosterService.executeGamingBoost()
        self.lastOptimization = snapshot
        self.optimizationHistory = boosterService.loadOptimizationHistory()

        refreshLiveMetrics()
        isOptimizing = false
        optimizationStepMessage = ""
        showBoostSuccessSheet = true
    }

    // MARK: - Game Sessions
    func startSession(for game: GameItem) {
        self.activeGame = game
        self.sessionStartTime = Date()
        self.isSessionActive = true
        self.sessionDurationFormatted = "00:00:00"

        self.games = boosterService.recordGamePlayed(id: game.id)

        sessionTimer?.cancel()
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.sessionStartTime else { return }
                let elapsed = Date().timeIntervalSince(start)
                let hours = Int(elapsed) / 3600
                let mins = (Int(elapsed) % 3600) / 60
                let secs = Int(elapsed) % 60
                self.sessionDurationFormatted = String(format: "%02d:%02d:%02d", hours, mins, secs)
            }
    }

    func endActiveSession() {
        guard let start = sessionStartTime, let game = activeGame else {
            isSessionActive = false
            return
        }

        sessionTimer?.cancel()
        sessionTimer = nil

        let now = Date()
        let elapsed = now.timeIntervalSince(start)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let currentBat = UIDevice.current.batteryLevel

        let record = GameSessionRecord(
            id: UUID(),
            gameId: game.id,
            gameName: game.name,
            presetMode: selectedPreset.rawValue,
            startTime: start,
            endTime: now,
            durationSeconds: elapsed,
            initialReadinessScore: readinessReport.score,
            initialThermalTitle: readinessReport.thermalTitle,
            finalThermalTitle: thermalStateTitle,
            batteryLevelStart: readinessReport.batteryLevel,
            batteryLevelEnd: currentBat
        )

        boosterService.saveSessionRecord(record)
        self.lastCompletedSession = record
        self.sessionHistory = boosterService.loadSessions()

        self.isSessionActive = false
        self.activeGame = nil
        self.sessionStartTime = nil
        self.showSessionEndSummary = true
    }

    // MARK: - Game Library Actions
    func addNewGame(name: String, category: GameCategory, urlScheme: String?, iconSymbol: String, colorHex: String) {
        let newGame = GameItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            urlScheme: urlScheme?.trimmingCharacters(in: .whitespacesAndNewlines),
            iconSymbol: iconSymbol,
            colorHex: colorHex
        )
        self.games = boosterService.addGame(newGame)
    }

    func deleteGame(id: UUID) {
        self.games = boosterService.deleteGame(id: id)
    }

    func launchGame(_ game: GameItem) {
        boosterService.launchGame(game) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.startSession(for: game)
            } else {
                self.launchNotice = "Không thể mở tự động qua URL Scheme. Vui lòng mở \"\(game.name)\" từ màn hình chính."
                // Still allow user to track session if they want
                self.startSession(for: game)
            }
        }
    }

    // MARK: - Checklist Management
    func toggleChecklistItem(id: String) {
        if let idx = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[idx].isCompleted.toggle()
            saveChecklist(checklistItems)
        }
    }

    func resetChecklist() {
        checklistItems = defaultChecklist()
        saveChecklist(checklistItems)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func loadChecklist() -> [GamingChecklistItem] {
        if let data = UserDefaults.standard.data(forKey: checklistStorageKey),
           let list = try? JSONDecoder().decode([GamingChecklistItem].self, from: data) {
            return list
        }
        let defaults = defaultChecklist()
        saveChecklist(defaults)
        return defaults
    }

    private func saveChecklist(_ list: [GamingChecklistItem]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: checklistStorageKey)
        }
    }

    private func defaultChecklist() -> [GamingChecklistItem] {
        [
            GamingChecklistItem(
                id: "focus_mode",
                title: "Bật Chế độ Tập trung (Gaming Focus)",
                detail: "Chặn thông báo biểu ngữ, tin nhắn mạng xã hội và cuộc gọi gây gián đoạn trận đấu.",
                iconName: "moon.fill",
                isCompleted: false,
                isOptional: false,
                targetSettingDescription: "Cài đặt > Chế độ tập trung > Chơi game"
            ),
            GamingChecklistItem(
                id: "low_power_mode",
                title: "Tắt Chế độ Nguồn điện thấp (Low Power)",
                detail: "Mở khóa ProMotion 120Hz và cho phép CPU/GPU chạy xung nhịp tối đa.",
                iconName: "bolt.badge.clock.fill",
                isCompleted: false,
                isOptional: false,
                targetSettingDescription: "Cài đặt > Pin > Chế độ nguồn điện thấp"
            ),
            GamingChecklistItem(
                id: "close_background_apps",
                title: "Đóng ứng dụng nền trong App Switcher",
                detail: "Vuốt lên từ cạnh dưới để đóng các app nặng (Facebook, TikTok, Chrome) giải phóng RAM cho game.",
                iconName: "square.stack.3d.up.fill",
                isCompleted: false,
                isOptional: false,
                targetSettingDescription: "Vuốt thanh Home lên và đóng app"
            ),
            GamingChecklistItem(
                id: "brightness_audio",
                title: "Điều chỉnh độ sáng 50% – 65%",
                detail: "Độ sáng quá cao làm màn hình nóng nhanh, dễ kích hoạt tính năng tự giảm xung bảo vệ của iOS.",
                iconName: "sun.max.fill",
                isCompleted: false,
                isOptional: true,
                targetSettingDescription: "Trung tâm điều khiển > Thanh độ sáng"
            ),
            GamingChecklistItem(
                id: "cooldown_case",
                title: "Tháo ốp lưng nếu chơi game nặng",
                detail: "Giúp mặt lưng kính/nhôm tản nhiệt trực tiếp vào không khí, chống tụt FPS do nghẽn nhiệt.",
                iconName: "thermometer.snowflake",
                isCompleted: false,
                isOptional: true,
                targetSettingDescription: "Thao tác phần cứng vật lý"
            )
        ]
    }
}
