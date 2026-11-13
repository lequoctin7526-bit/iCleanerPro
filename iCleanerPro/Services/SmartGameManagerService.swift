import Foundation
import UIKit
import UserNotifications

/// Core service handling automated game management, App Store version tracking,
/// installation detection, and pre/post game optimizations using official Apple APIs.
public final class SmartGameManagerService: @unchecked Sendable {
    public static let shared = SmartGameManagerService()

    private let libraryStorageKey = "iCleanerPro_smart_games_library_v1"
    private let settingsStorageKey = "iCleanerPro_smart_game_settings_v1"

    private let lookupService = AppStoreLookupService.shared
    private let boosterService = GameBoosterService.shared
    private let memoryService = MemoryMonitorService()
    private let storageService = StorageManagerService()
    private let cacheService = CacheCleanerService()

    public init() {}

    // MARK: - Library Persistence
    public func loadGames() -> [SmartGameModel] {
        if let data = UserDefaults.standard.data(forKey: libraryStorageKey),
           let list = try? JSONDecoder().decode([SmartGameModel].self, from: data) {
            return list
        }
        let defaults = GamePresetCatalog.presets
        saveGames(defaults)
        return defaults
    }

    public func saveGames(_ games: [SmartGameModel]) {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: libraryStorageKey)
        }
    }

    public func addGame(_ game: SmartGameModel) -> [SmartGameModel] {
        var current = loadGames()
        if let idx = current.firstIndex(where: { $0.bundleId == game.bundleId || $0.appStoreId == game.appStoreId }) {
            current[idx] = game
        } else {
            current.insert(game, at: 0)
        }
        saveGames(current)
        return current
    }

    public func deleteGame(id: UUID) -> [SmartGameModel] {
        var current = loadGames()
        current.removeAll { $0.id == id }
        saveGames(current)
        return current
    }

    public func updateGame(_ game: SmartGameModel) -> [SmartGameModel] {
        var current = loadGames()
        if let idx = current.firstIndex(where: { $0.id == game.id }) {
            current[idx] = game
            saveGames(current)
        }
        return current
    }

    // MARK: - Settings Persistence
    public func loadSettings() -> SmartGameAutomationSettings {
        if let data = UserDefaults.standard.data(forKey: settingsStorageKey),
           let settings = try? JSONDecoder().decode(SmartGameAutomationSettings.self, from: data) {
            return settings
        }
        return .default
    }

    public func saveSettings(_ settings: SmartGameAutomationSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsStorageKey)
        }
    }

    // MARK: - Game Installation Detection
    /// Uses UIApplication.canOpenURL to check if the game scheme is supported.
    @MainActor
    public func isGameInstalled(_ game: SmartGameModel) -> Bool {
        guard let scheme = game.urlScheme,
              !scheme.trimmingCharacters(in: .whitespaces).isEmpty,
              let url = URL(string: scheme) else {
            return game.isInstalled
        }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Automatically scans and updates installation status for all games in the library.
    @MainActor
    public func autoDetectInstallationStatus() -> [SmartGameModel] {
        var current = loadGames()
        for i in 0..<current.count {
            if let scheme = current[i].urlScheme,
               !scheme.trimmingCharacters(in: .whitespaces).isEmpty,
               let url = URL(string: scheme) {
                current[i].isInstalled = UIApplication.shared.canOpenURL(url)
            }
        }
        saveGames(current)
        return current
    }

    // MARK: - Update Checker
    /// Checks App Store versions for games via public iTunes API.
    public func checkUpdates(for games: [SmartGameModel]) async -> [SmartGameModel] {
        var updatedList = games
        var newlyFoundUpdates = 0

        for i in 0..<updatedList.count {
            let game = updatedList[i]
            do {
                var item: AppStoreLookupItem?
                if !game.appStoreId.isEmpty {
                    item = try await lookupService.lookup(appStoreId: game.appStoreId)
                } else if !game.bundleId.isEmpty {
                    item = try await lookupService.lookup(bundleId: game.bundleId)
                }

                if let info = item {
                    updatedList[i].latestStoreVersion = info.version
                    updatedList[i].appStoreUrl = info.trackViewUrl
                    if let artwork = info.artworkUrl512 ?? info.artworkUrl100, !artwork.isEmpty {
                        updatedList[i].iconUrl = artwork
                    }
                    if let bytes = info.parsedFileSizeBytes {
                        updatedList[i].fileSizeBytes = bytes
                    }
                    if let notes = info.releaseNotes {
                        updatedList[i].releaseNotes = notes
                    }
                    updatedList[i].lastCheckedDate = Date()

                    if updatedList[i].hasUpdateAvailable {
                        newlyFoundUpdates += 1
                    }
                }
            } catch {
                // Silently keep previous check date on transient network errors
            }
        }

        saveGames(updatedList)

        // Send local notification if updates exist and setting enabled
        let settings = loadSettings()
        if settings.updateNotifications && newlyFoundUpdates > 0 {
            sendUpdateAvailableNotification(count: newlyFoundUpdates)
        }

        return updatedList
    }

    // MARK: - Auto Pre-Game Optimization
    /// Runs multi-step optimization before game launch.
    public func executePreGameOptimization(for game: SmartGameModel) async -> GameOptimizationSnapshot {
        let beforeRAM = memoryService.captureSnapshot()
        let beforeStorage = storageService.fetchDeviceStorageInfo()

        var steps: [String] = []

        // Step 1: In-app memory purge
        let ramResult = await memoryService.performSafeMemoryCleanup()
        let freedMemory = max(0, ramResult.appFootprintDeltaBytes)
        steps.append("Đã giải phóng \(ByteFormatterUtil.formatMemorySize(freedMemory)) vùng đệm iCleaner Pro")

        // Step 2: In-app sandbox caches
        let cachePartitions = cacheService.auditCachePartitions()
        let cacheResult = await cacheService.cleanSelectedCaches(cachePartitions)
        let freedCache = cacheResult.freedBytes
        steps.append("Đã dọn dẹp \(ByteFormatterUtil.formatFileSize(freedCache)) tệp tạm & cache an toàn")

        try? await Task.sleep(nanoseconds: 200_000_000)

        let afterRAM = memoryService.captureSnapshot()
        let afterStorage = storageService.fetchDeviceStorageInfo()

        let snapshot = GameOptimizationSnapshot(
            freedAppMemoryBytes: freedMemory,
            freedCacheBytes: freedCache,
            appFootprintBefore: beforeRAM.appFootprintBytes,
            appFootprintAfter: afterRAM.appFootprintBytes,
            storageFreeBefore: beforeStorage.availableBytes,
            storageFreeAfter: afterStorage.availableBytes,
            verifiedSteps: steps
        )

        return snapshot
    }

    // MARK: - Auto Post-Game Clean
    /// Automatically cleans up iCleaner Pro temp caches after gaming session ends and saves session.
    public func executePostGameAutoClean(
        game: SmartGameModel,
        duration: TimeInterval,
        presetName: String = "Cân bằng"
    ) async -> (GameOptimizationSnapshot, GameSessionRecord) {
        let snapshot = await executePreGameOptimization(for: game)

        let processInfo = ProcessInfo.processInfo
        UIDevice.current.isBatteryMonitoringEnabled = true
        let battery = UIDevice.current.batteryLevel

        let session = GameSessionRecord(
            id: UUID(),
            gameId: game.id,
            gameName: game.name,
            presetMode: presetName,
            startTime: Date().addingTimeInterval(-duration),
            endTime: Date(),
            durationSeconds: duration,
            initialReadinessScore: 88,
            initialThermalTitle: "Bình thường",
            finalThermalTitle: thermalTitle(for: processInfo.thermalState),
            batteryLevelStart: battery,
            batteryLevelEnd: battery
        )

        boosterService.saveSessionRecord(session)

        // Increment play count
        var current = loadGames()
        if let idx = current.firstIndex(where: { $0.id == game.id }) {
            current[idx].playCount += 1
            current[idx].lastPlayedDate = Date()
            saveGames(current)
        }

        return (snapshot, session)
    }

    // MARK: - Game Launcher
    @MainActor
    public func launchGame(_ game: SmartGameModel, completion: @escaping (Bool) -> Void) {
        guard let scheme = game.urlScheme,
              !scheme.trimmingCharacters(in: .whitespaces).isEmpty,
              let url = URL(string: scheme) else {
            completion(false)
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                completion(success)
            }
        } else {
            completion(false)
        }
    }

    @MainActor
    public func openAppStore(for game: SmartGameModel) {
        var targetUrl: URL?
        if !game.appStoreId.isEmpty, let url = URL(string: "itms-apps://itunes.apple.com/app/id\(game.appStoreId)") {
            targetUrl = url
        } else if let storeStr = game.appStoreUrl, let url = URL(string: storeStr) {
            targetUrl = url
        }

        if let url = targetUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - Local Notification
    private func sendUpdateAvailableNotification(count: Int) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "Smart Game Manager: Có bản cập nhật mới!"
            content.body = "Phát hiện \(count) game trên thiết bị có phiên bản mới trên App Store. Nhấn để cập nhật ngay."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "smart_game_update_\(UUID().uuidString)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    private func thermalTitle(for state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Mát (Bình thường)"
        case .fair: return "Hơi ấm"
        case .serious: return "Nóng"
        case .critical: return "Quá nhiệt"
        @unknown default: return "Không xác định"
        }
    }
}
