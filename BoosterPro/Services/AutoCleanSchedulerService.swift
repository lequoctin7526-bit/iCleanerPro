import Foundation
import UIKit
import BackgroundTasks
import UserNotifications

/// Manages automatic cleanup scheduling, safety condition evaluations, and background task execution.
/// Complies with iOS sandbox security: only cleans Booster Pro's own sandbox files and memory.
/// Never touches third-party apps, system wired RAM, documents, or personal user files.
final class AutoCleanSchedulerService {
    static let shared = AutoCleanSchedulerService()

    // MARK: - Constants
    static let refreshTaskIdentifier = "com.boosterpro.app.autoclean.refresh"
    static let processingTaskIdentifier = "com.boosterpro.app.autoclean.processing"

    private let configStorageKey = "BoosterPro_auto_clean_config_v1"
    private let historyStorageKey = "BoosterPro_auto_clean_history_v1"

    // MARK: - State & Synchronization
    private let lock = NSLock()
    private(set) var isCleaningInProgress: Bool = false
    private var isCancellationRequested: Bool = false

    private let fileManager = FileManager.default
    private let junkService = JunkCleanerService()
    private let cacheService = CacheCleanerService()
    private let memoryService = MemoryMonitorService()

    private init() {}

    // MARK: - Persistence: Configuration
    func loadConfiguration() -> AutoCleanConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configStorageKey),
              let decoded = try? JSONDecoder().decode(AutoCleanConfiguration.self, from: data) else {
            return .default
        }
        return decoded
    }

    func saveConfiguration(_ config: AutoCleanConfiguration) {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: configStorageKey)
        }
    }

    func resetConfigurationToDefaults() -> AutoCleanConfiguration {
        let defaults = AutoCleanConfiguration.default
        saveConfiguration(defaults)
        return defaults
    }

    // MARK: - Persistence: History
    func loadHistory() -> [AutoCleanHistoryRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyStorageKey),
              let decoded = try? JSONDecoder().decode([AutoCleanHistoryRecord].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.timestamp > $1.timestamp }
    }

    func saveHistory(_ history: [AutoCleanHistoryRecord]) {
        // Keep up to 100 most recent records to prevent unbounded growth
        let trimmed = Array(history.prefix(100))
        if let encoded = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(encoded, forKey: historyStorageKey)
        }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyStorageKey)
    }

    func appendHistoryRecord(_ record: AutoCleanHistoryRecord) {
        var current = loadHistory()
        current.insert(record, at: 0)
        saveHistory(current)
    }

    // MARK: - Safety Condition Evaluation
    /// Evaluates whether auto clean is permitted under the current device state and user settings.
    func evaluateConditions(
        config: AutoCleanConfiguration,
        trigger: String,
        isBackground: Bool = false
    ) -> (allowed: Bool, reason: String?) {
        guard config.isMasterEnabled else {
            return (false, "Auto Clean đã bị tắt trong Cài đặt.")
        }

        lock.lock()
        let inProgress = isCleaningInProgress
        lock.unlock()

        if inProgress {
            return (false, "Một tiến trình dọn dẹp khác đang chạy.")
        }

        // Active App Only condition
        if config.conditions.activeAppOnly && isBackground {
            return (false, "Cấu hình yêu cầu chỉ dọn khi ứng dụng đang hoạt động trên màn hình.")
        }

        // Thermal State Check
        if config.conditions.thermalProtection {
            let thermal = ProcessInfo.processInfo.thermalState
            if thermal == .critical || thermal == .serious {
                return (false, "Thiết bị đang quá nhiệt (\(thermalStateTitle(thermal))). Tạm dừng để bảo vệ pin và CPU.")
            }
        }

        // Battery Conditions
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryState = UIDevice.current.batteryState
        let batteryLevel = UIDevice.current.batteryLevel

        if config.conditions.chargingOnly {
            let isCharging = (batteryState == .charging || batteryState == .full)
            if !isCharging {
                return (false, "Chỉ dọn khi thiết bị đang cắm sạc.")
            }
        }

        if config.conditions.lowBatteryProtection {
            let isCharging = (batteryState == .charging || batteryState == .full)
            if batteryLevel >= 0 && batteryLevel < 0.20 && !isCharging {
                let percent = Int(batteryLevel * 100)
                return (false, "Mức pin thấp (\(percent)%) và không cắm sạc. Tạm dừng để tránh hao pin.")
            }
        }

        return (true, nil)
    }

    private func thermalStateTitle(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Bình thường"
        case .fair: return "Hơi ấm"
        case .serious: return "Nóng (Serious)"
        case .critical: return "Rất nóng (Critical)"
        @unknown default: return "Không xác định"
        }
    }

    // MARK: - Cancellation Control
    func requestCancellation() {
        lock.lock()
        isCancellationRequested = true
        lock.unlock()
    }

    private func checkAndResetCancellation() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancellationRequested
    }

    // MARK: - Smart Auto Clean Execution Engine
    /// Executes the full safe cleanup workflow conforming to Section 5:
    /// 1. Check permissions & accessible sandbox data.
    /// 2. Analyze size.
    /// 3. Classify safe vs protected data (NEVER touch Documents, Preferences, Photos, external games).
    /// 4. Respect user's category toggles.
    /// 5. Clean safe items.
    /// 6. Verify deletion.
    /// 7. Update real statistics and record history.
    func executeClean(
        trigger: String,
        isBackground: Bool = false,
        progressCallback: ((String, Double) -> Void)? = nil
    ) async -> AutoCleanExecutionResult {
        var config = loadConfiguration()

        // 1. Evaluate safety conditions
        let (allowed, skipReason) = evaluateConditions(config: config, trigger: trigger, isBackground: isBackground)
        guard allowed else {
            let record = AutoCleanHistoryRecord(
                triggerReason: trigger,
                categoriesCleaned: [],
                beforeBytes: 0,
                afterBytes: 0,
                bytesFreed: 0,
                durationSeconds: 0,
                wasSuccessful: false,
                statusMessage: "Bỏ qua: \(skipReason ?? "Không đủ điều kiện")",
                skippedReason: skipReason
            )
            appendHistoryRecord(record)
            config.failedCleansCount += 1
            saveConfiguration(config)
            return AutoCleanExecutionResult(
                wasSuccessful: false,
                trigger: trigger,
                categories: [],
                bytesFreed: 0,
                durationSeconds: 0,
                statusMessage: "Bỏ qua: \(skipReason ?? "Không đủ điều kiện")",
                skippedReason: skipReason
            )
        }

        // Concurrency Lock
        lock.lock()
        isCleaningInProgress = true
        isCancellationRequested = false
        lock.unlock()

        defer {
            lock.lock()
            isCleaningInProgress = false
            lock.unlock()
        }

        let startTime = Date()
        var categoriesCleaned: [String] = []

        // Initial measurement
        progressCallback?("Đang phân tích dữ liệu sandbox...", 0.1)
        let beforeSandboxBytes = measureDeletableSandboxSize()

        // Cooperative cancellation check
        if checkAndResetCancellation() {
            return makeCancelledResult(trigger: trigger, startTime: startTime)
        }

        // Step A: Junk Files (tmp/)
        if config.dataOptions.cleanJunkFiles || config.dataOptions.cleanTemporaryFiles {
            progressCallback?("Đang dọn tệp rác và tệp tạm thời...", 0.3)
            let junkItems = junkService.scanSandboxJunk()
            let safeItems = junkItems.filter { $0.type == .tempFiles || $0.type == .crashLogs }
            if !safeItems.isEmpty {
                _ = junkService.cleanSelectedItems(safeItems)
                categoriesCleaned.append("Tệp tạm thời (tmp)")
            }
        }

        if checkAndResetCancellation() {
            return makeCancelledResult(trigger: trigger, startTime: startTime)
        }

        // Step B: Application Cache (Caches/Thumbnails, URLCache)
        if config.dataOptions.cleanAppCache {
            progressCallback?("Đang dọn bộ nhớ đệm ứng dụng...", 0.5)
            let partitions = cacheService.auditCachePartitions()
            let deletable = partitions.filter { $0.isDeletable }
            if !deletable.isEmpty {
                _ = cacheService.cleanSelectedCaches(deletable)
                categoriesCleaned.append("Bộ nhớ đệm (Caches)")
            }
        }

        if checkAndResetCancellation() {
            return makeCancelledResult(trigger: trigger, startTime: startTime)
        }

        // Step C: Application Logs (Library/Logs)
        if config.dataOptions.cleanAppLogs {
            progressCallback?("Đang dọn nhật ký chẩn đoán...", 0.7)
            cleanAppLogsSafely()
            categoriesCleaned.append("Nhật ký ứng dụng (Logs)")
        }

        if checkAndResetCancellation() {
            return makeCancelledResult(trigger: trigger, startTime: startTime)
        }

        // Step D: App Memory (URLCache responses & NSCache)
        if config.dataOptions.cleanAppMemory {
            progressCallback?("Đang giải phóng bộ nhớ RAM nội bộ...", 0.85)
            _ = await memoryService.performSafeMemoryCleanup()
            categoriesCleaned.append("Bộ nhớ RAM ứng dụng")
        }

        // Step E: Game Optimization Resources
        if config.dataOptions.cleanGameResources {
            cleanGameTemporaryResources()
            categoriesCleaned.append("Tài nguyên đệm Game")
        }

        progressCallback?("Đang xác minh dữ liệu đã xóa...", 0.95)
        let afterSandboxBytes = measureDeletableSandboxSize()
        let bytesFreed = max(0, beforeSandboxBytes - afterSandboxBytes)
        let duration = max(0.1, Date().timeIntervalSince(startTime))

        // Update persistent stats
        config.lastCleanDate = Date()
        config.totalBytesFreedAllTime += bytesFreed
        config.successfulCleansCount += 1
        saveConfiguration(config)

        let statusMsg = bytesFreed > 0
            ? "Tự động dọn dẹp thành công. Đã giải phóng \(ByteFormatterUtil.format(bytesFreed))."
            : "Hoàn tất kiểm tra sandbox. Không có dữ liệu rác tồn đọng."

        let record = AutoCleanHistoryRecord(
            triggerReason: trigger,
            categoriesCleaned: categoriesCleaned,
            beforeBytes: beforeSandboxBytes,
            afterBytes: afterSandboxBytes,
            bytesFreed: bytesFreed,
            durationSeconds: duration,
            wasSuccessful: true,
            statusMessage: statusMsg,
            skippedReason: nil
        )
        appendHistoryRecord(record)

        progressCallback?("Hoàn tất!", 1.0)

        // Reschedule next background task
        scheduleNextBackgroundTask()

        return AutoCleanExecutionResult(
            wasSuccessful: true,
            trigger: trigger,
            categories: categoriesCleaned,
            bytesFreed: bytesFreed,
            durationSeconds: duration,
            statusMessage: statusMsg,
            skippedReason: nil
        )
    }

    private func makeCancelledResult(trigger: String, startTime: Date) -> AutoCleanExecutionResult {
        let duration = max(0.1, Date().timeIntervalSince(startTime))
        let record = AutoCleanHistoryRecord(
            triggerReason: trigger,
            categoriesCleaned: [],
            beforeBytes: 0,
            afterBytes: 0,
            bytesFreed: 0,
            durationSeconds: duration,
            wasSuccessful: false,
            statusMessage: "Người dùng đã hủy quá trình dọn dẹp.",
            skippedReason: "Bị hủy bởi người dùng"
        )
        appendHistoryRecord(record)
        return AutoCleanExecutionResult(
            wasSuccessful: false,
            trigger: trigger,
            categories: [],
            bytesFreed: 0,
            durationSeconds: duration,
            statusMessage: "Người dùng đã hủy quá trình dọn dẹp.",
            skippedReason: "Bị hủy bởi người dùng"
        )
    }

    // MARK: - Safe Sandbox Directory Helpers
    private func measureDeletableSandboxSize() -> Int64 {
        var total: Int64 = 0

        // 1. tmp directory
        let tmpDir = fileManager.temporaryDirectory
        total += calculateDirectorySize(tmpDir)

        // 2. Caches/Thumbnails
        if let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let thumb = caches.appendingPathComponent("Thumbnails", isDirectory: true)
            total += calculateDirectorySize(thumb)
        }

        // 3. URLCache disk usage
        total += Int64(URLCache.shared.currentDiskUsage)

        return total
    }

    private func calculateDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               values.isRegularFile == true,
               let size = values.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    private func cleanAppLogsSafely() {
        guard let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let logsDir = libraryURL.appendingPathComponent("Logs", isDirectory: true)
        guard fileManager.fileExists(atPath: logsDir.path) else { return }

        if let files = try? fileManager.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: nil) {
            for file in files {
                // Delete diagnostic log files inside sandbox
                try? fileManager.removeItem(at: file)
            }
        }
    }

    private func cleanGameTemporaryResources() {
        // Clear any temporary pre-game analysis files created in tmp
        let tmpDir = fileManager.temporaryDirectory
        if let items = try? fileManager.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
            for item in items where item.lastPathComponent.contains("game_") || item.lastPathComponent.contains("snapshot_") {
                try? fileManager.removeItem(at: item)
            }
        }
    }

    // MARK: - Next Scheduled Date Calculation
    /// Calculates the estimated next execution Date based on user's schedule.
    func calculateNextScheduledDate(schedule: AutoCleanSchedule) -> Date? {
        guard schedule.isScheduleEnabled else { return nil }

        let calendar = Calendar.current
        let now = Date()

        switch schedule.frequency {
        case .daily:
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = schedule.startHour
            components.minute = schedule.startMinute
            components.second = 0

            guard let candidate = calendar.date(from: components) else { return nil }
            if candidate > now {
                return candidate
            } else {
                return calendar.date(byAdding: .day, value: 1, to: candidate)
            }

        case .weekly:
            guard !schedule.selectedDaysOfWeek.isEmpty else { return nil }
            // Find next upcoming day of week
            for offset in 0..<8 {
                guard let testDate = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                let weekday = calendar.component(.weekday, from: testDate)
                if schedule.selectedDaysOfWeek.contains(weekday) {
                    var components = calendar.dateComponents([.year, .month, .day], from: testDate)
                    components.hour = schedule.startHour
                    components.minute = schedule.startMinute
                    components.second = 0
                    if let candidate = calendar.date(from: components), candidate > now {
                        return candidate
                    }
                }
            }
            return nil

        case .onAppOpen:
            return nil // Triggered by lifecycle event
        case .beforeGaming:
            return nil // Triggered before game launch
        case .onReturnFromGaming:
            return nil // Triggered on game return
        case .onLowStorage:
            return nil // Triggered by low storage check
        }
    }

    // MARK: - BackgroundTasks Integration (BGTaskScheduler)
    /// Registers background tasks with iOS system. Must be called before application finishes launching.
    func registerBackgroundTasks() {
        // 1. App Refresh Task (Quick audit and light cleanup)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            self?.handleAppRefresh(task: appRefreshTask)
        }

        // 2. Processing Task (Heavier cleanup when device is idle & charging)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else { return }
            self?.handleProcessing(task: processingTask)
        }
    }

    /// Schedules the next background execution with BGTaskScheduler.
    func scheduleNextBackgroundTask() {
        let config = loadConfiguration()
        guard config.isMasterEnabled && config.schedule.isScheduleEnabled else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
            return
        }

        let earliestDate = calculateNextScheduledDate(schedule: config.schedule) ?? Date().addingTimeInterval(3600 * 24)

        // 1. Schedule App Refresh Task
        let refreshRequest = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        refreshRequest.earliestBeginDate = earliestDate

        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
        } catch {
            // Background task scheduling may fail on Simulator or if disabled by user in Settings
        }

        // 2. Schedule Processing Task if charging condition is requested
        let processingRequest = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        processingRequest.earliestBeginDate = earliestDate
        processingRequest.requiresNetworkConnectivity = false
        processingRequest.requiresExternalPower = config.conditions.chargingOnly

        do {
            try BGTaskScheduler.shared.submit(processingRequest)
        } catch {
            // System submission error handling
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Reschedule next task immediately
        scheduleNextBackgroundTask()

        let cleaningTask = Task {
            let result = await executeClean(
                trigger: "Lịch chạy nền iOS (App Refresh)",
                isBackground: true
            )
            task.setTaskCompleted(success: result.wasSuccessful)
        }

        task.expirationHandler = {
            self.requestCancellation()
            cleaningTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private func handleProcessing(task: BGProcessingTask) {
        scheduleNextBackgroundTask()

        let cleaningTask = Task {
            let result = await executeClean(
                trigger: "Lịch chạy nền nâng cao (BG Processing)",
                isBackground: true
            )
            task.setTaskCompleted(success: result.wasSuccessful)
        }

        task.expirationHandler = {
            self.requestCancellation()
            cleaningTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
