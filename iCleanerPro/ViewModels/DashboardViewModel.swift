import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var storageInfo: DeviceStorageInfo = .empty
    @Published var ramSnapshot: RAMSnapshot = .empty
    @Published var cpuMetrics: CPUMetrics = .empty
    @Published var appCacheBytes: Int64 = 0
    @Published var junkBytes: Int64 = 0
    @Published var optimizationScore: Double = 0.0
    @Published var isRefreshing = false
    @Published var lastUpdatedText = "Chưa cập nhật"
    @Published var errorMessage: String?

    private let storageService = StorageManagerService()
    private let memoryService = MemoryMonitorService()
    private let deviceService = DeviceMonitorService()
    private let cacheService = CacheCleanerService()
    private let junkService = JunkCleanerService()

    func refreshDashboard() async {
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        let storage = storageService.fetchDeviceStorageInfo()
        let ram = memoryService.captureSnapshot()
        let cpu = deviceService.collectCPUMetrics()
        let cachePartitions = cacheService.auditCachePartitions()
        let junkItems = await junkService.scanSandboxJunk()

        let cleanableCache = cachePartitions
            .filter(\.isDeletable)
            .reduce(Int64(0)) { $0 + $1.sizeBytes }
        let totalJunk = junkItems.reduce(Int64(0)) { $0 + $1.sizeBytes }

        self.storageInfo = storage
        self.ramSnapshot = ram
        self.cpuMetrics = cpu
        self.appCacheBytes = cleanableCache
        self.junkBytes = totalJunk
        self.optimizationScore = computeRealHealthScore(
            storage: storage,
            ram: ram,
            cpu: cpu,
            cleanableBytes: cleanableCache + totalJunk
        )

        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        self.lastUpdatedText = "Cập nhật lúc \(formatter.string(from: Date()))"
    }

    /// Computes a transparent, real-metrics-backed health percentage (0.0 – 1.0).
    private func computeRealHealthScore(
        storage: DeviceStorageInfo,
        ram: RAMSnapshot,
        cpu: CPUMetrics,
        cleanableBytes: Int64
    ) -> Double {
        var score = 1.0

        // 1. Storage pressure penalty
        if storage.freePercentage < 0.08 {
            score -= 0.30
        } else if storage.freePercentage < 0.15 {
            score -= 0.18
        } else if storage.freePercentage < 0.25 {
            score -= 0.08
        }

        // 2. RAM pressure penalty
        if ram.usedRatio > 0.88 {
            score -= 0.22
        } else if ram.usedRatio > 0.72 {
            score -= 0.10
        }

        // 3. Thermal state penalty
        switch cpu.thermalState {
        case .critical: score -= 0.25
        case .serious: score -= 0.16
        case .fair: score -= 0.06
        case .nominal: break
        @unknown default: break
        }

        // 4. Accumulated sandbox cache/junk penalty (50 MB+ lowers score up to 15%)
        let mb50: Double = 50 * 1_048_576
        let junkPenalty = min(0.15, Double(cleanableBytes) / mb50 * 0.15)
        score -= junkPenalty

        return min(1.0, max(0.15, score))
    }

    var deviceStatusSummary: String {
        if optimizationScore >= 0.85 {
            return "Thiết bị đang hoạt động tối ưu"
        } else if optimizationScore >= 0.60 {
            return "Có một số mục có thể tối ưu thêm"
        } else {
            return "Nên dọn dẹp và giải phóng tài nguyên"
        }
    }
}
