import Foundation
import UIKit

/// Core domain service handling Game Booster calculations, safe optimizations,
/// game library management, and session tracking using only public Apple APIs.
final class GameBoosterService: @unchecked Sendable {
    static let shared = GameBoosterService()

    private let memoryService = MemoryMonitorService()
    private let storageService = StorageManagerService()
    private let junkService = JunkCleanerService()
    private let cacheService = CacheCleanerService()

    private let gamesStorageKey = "BoosterPro_gaming_library_v1"
    private let sessionsStorageKey = "BoosterPro_gaming_sessions_v1"
    private let optimizationsStorageKey = "BoosterPro_gaming_optimizations_v1"

    init() {}

    // MARK: - Real Device Readiness Assessment
    func evaluateReadiness() -> GameReadinessReport {
        let ram = memoryService.captureSnapshot()
        let storage = storageService.fetchDeviceStorageInfo()
        let processInfo = ProcessInfo.processInfo
        let thermal = processInfo.thermalState
        let isLowPower = processInfo.isLowPowerModeEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        let battery = UIDevice.current.batteryLevel

        var score = 100
        var recommendations: [String] = []

        // 1. Thermal check (Public Apple ThermalState)
        switch thermal {
        case .critical:
            score -= 35
            recommendations.append("Thiết bị đang quá nhiệt: CPU/GPU bị bóp xung nghiêm trọng. Hãy để máy nguội trước khi chơi.")
        case .serious:
            score -= 22
            recommendations.append("Nhiệt độ máy cao: Có thể bị tụt khung hình (FPS drop). Tháo ốp lưng và tránh vừa sạc vừa chơi.")
        case .fair:
            score -= 8
            recommendations.append("Thiết bị hơi ấm: Giảm độ sáng màn hình xuống 50% để hạn chế tăng nhiệt.")
        case .nominal:
            break
        @unknown default:
            break
        }

        // 2. Storage check (< 10% free degrades APFS / swap performance)
        if storage.freePercentage < 0.10 {
            score -= 25
            recommendations.append("Dung lượng trống dưới 10%: iOS thiếu không gian tạo bộ nhớ ảo (swap), dễ giật lag.")
        } else if storage.freePercentage < 0.18 {
            score -= 10
            recommendations.append("Dung lượng bộ nhớ nên trống thêm ít nhất 5 GB để game tải tài nguyên mượt mà.")
        }

        // 3. RAM pressure check
        if ram.usedRatio >= 0.85 {
            score -= 20
            recommendations.append("Áp lực RAM cao: Nhiều app nền đang giữ trang nhớ. Hãy đóng các app không dùng trong App Switcher.")
        } else if ram.usedRatio >= 0.70 {
            score -= 10
        }

        // 4. Low Power Mode check (limits CPU clock & 120Hz ProMotion)
        if isLowPower {
            score -= 15
            recommendations.append("Chế độ Nguồn điện thấp đang BẬT: iOS đang khóa ProMotion 120Hz và giảm xung CPU.")
        }

        let clampedScore = max(10, min(100, score))
        let level: GameReadinessLevel
        if clampedScore >= 80 {
            level = .optimal
        } else if clampedScore >= 55 {
            level = .moderate
        } else {
            level = .needsOptimization
        }

        let summaryText: String
        switch level {
        case .optimal:
            summaryText = "Thiết bị mát mẻ, RAM & bộ nhớ dồi dào, sẵn sàng chiến game max setting."
        case .moderate:
            summaryText = "Thiết bị hoạt động ổn định. Nên nhấn BOOST NOW và kiểm tra checklist trước khi vào trận."
        case .needsOptimization:
            summaryText = "Thiết bị đang chịu áp lực nhiệt hoặc bộ nhớ. Cần tối ưu và đóng ứng dụng nền để tránh drop FPS."
        }

        return GameReadinessReport(
            level: level,
            score: clampedScore,
            summary: summaryText,
            ramAvailableBytes: ram.procAvailableBytes,
            storageFreeBytes: storage.availableBytes,
            thermalState: thermal,
            isLowPowerMode: isLowPower,
            batteryLevel: battery,
            recommendations: recommendations
        )
    }

    // MARK: - Safe In-App Gaming Optimization Routine
    func executeGamingBoost() async -> GameOptimizationSnapshot {
        let beforeRAM = memoryService.captureSnapshot()
        let beforeStorage = storageService.fetchDeviceStorageInfo()

        var steps: [String] = []

        // 1. Purge in-app memory caches
        let ramResult = await memoryService.performSafeMemoryCleanup()
        let freedMemory = max(0, ramResult.appFootprintDeltaBytes)
        steps.append("Đã giải phóng \(ByteFormatterUtil.formatMemorySize(freedMemory)) vùng đệm trong ứng dụng")

        // 2. Clear non-protected sandbox caches & temp files
        let cachePartitions = cacheService.auditCachePartitions()
        let cacheResult = await cacheService.cleanSelectedCaches(cachePartitions)
        let freedCache = cacheResult.freedBytes
        steps.append("Đã dọn dẹp \(ByteFormatterUtil.formatFileSize(freedCache)) tệp tạm & cache sandbox")

        // Brief delay for system accounting
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

        saveOptimizationSnapshot(snapshot)
        return snapshot
    }

    // MARK: - Game Library Management
    func loadGames() -> [GameItem] {
        if let data = UserDefaults.standard.data(forKey: gamesStorageKey),
           let list = try? JSONDecoder().decode([GameItem].self, from: data) {
            return list
        }
        let defaults = defaultPopularGames()
        saveGames(defaults)
        return defaults
    }

    func saveGames(_ list: [GameItem]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: gamesStorageKey)
        }
    }

    func addGame(_ game: GameItem) -> [GameItem] {
        var list = loadGames()
        list.insert(game, at: 0)
        saveGames(list)
        return list
    }

    func deleteGame(id: UUID) -> [GameItem] {
        var list = loadGames()
        list.removeAll { $0.id == id }
        saveGames(list)
        return list
    }

    func recordGamePlayed(id: UUID) -> [GameItem] {
        var list = loadGames()
        if let idx = list.firstIndex(where: { $0.id == id }) {
            list[idx].lastPlayed = Date()
            list[idx].playCount += 1
            saveGames(list)
        }
        return list
    }

    @MainActor
    func launchGame(_ game: GameItem, completion: @escaping (Bool) -> Void) {
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

    // MARK: - Sessions & History Persistence
    func loadSessions() -> [GameSessionRecord] {
        if let data = UserDefaults.standard.data(forKey: sessionsStorageKey),
           let list = try? JSONDecoder().decode([GameSessionRecord].self, from: data) {
            return list
        }
        return []
    }

    func saveSessionRecord(_ record: GameSessionRecord) {
        var list = loadSessions()
        list.insert(record, at: 0)
        if list.count > 50 {
            list = Array(list.prefix(50))
        }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: sessionsStorageKey)
        }
    }

    func loadOptimizationHistory() -> [GameOptimizationSnapshot] {
        if let data = UserDefaults.standard.data(forKey: optimizationsStorageKey),
           let list = try? JSONDecoder().decode([GameOptimizationSnapshot].self, from: data) {
            return list
        }
        return []
    }

    private func saveOptimizationSnapshot(_ snapshot: GameOptimizationSnapshot) {
        var list = loadOptimizationHistory()
        list.insert(snapshot, at: 0)
        if list.count > 30 {
            list = Array(list.prefix(30))
        }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: optimizationsStorageKey)
        }
    }

    // MARK: - Preloaded Popular Games (VN & Global Presets)
    private func defaultPopularGames() -> [GameItem] {
        [
            GameItem(
                name: "Liên Quân Mobile (Arena of Valor)",
                category: .moba,
                urlScheme: "aov://",
                iconSymbol: "shield.lefthalf.filled",
                colorHex: "#00F5A0"
            ),
            GameItem(
                name: "PUBG Mobile",
                category: .battleRoyale,
                urlScheme: "pubgmobile://",
                iconSymbol: "cross.vial.fill",
                colorHex: "#FF9500"
            ),
            GameItem(
                name: "Tốc Chiến (Wild Rift)",
                category: .moba,
                urlScheme: "wildrift://",
                iconSymbol: "bolt.shield.fill",
                colorHex: "#00D9F5"
            ),
            GameItem(
                name: "Free Fire",
                category: .battleRoyale,
                urlScheme: "freefire://",
                iconSymbol: "flame.fill",
                colorHex: "#FF3B30"
            ),
            GameItem(
                name: "Genshin Impact",
                category: .rpg,
                urlScheme: "genshinimpact://",
                iconSymbol: "wand.and.stars",
                colorHex: "#AF52DE"
            )
        ]
    }
}
