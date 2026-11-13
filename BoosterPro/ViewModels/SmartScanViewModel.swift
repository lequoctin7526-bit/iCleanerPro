import Foundation

@MainActor
final class SmartScanViewModel: ObservableObject {
    @Published var phase: ScanPhase = .idle
    @Published var overallProgress: Double = 0.0
    @Published var stages: [ScanStageProgress] = []
    @Published var junkItems: [JunkItem] = []
    @Published var cachePartitions: [CachePartitionItem] = []
    @Published var slowdownFactors: [SlowdownFactor] = []
    @Published var storageInfo: DeviceStorageInfo = .empty
    @Published var ramSnapshot: RAMSnapshot = .empty
    @Published var finalReport: ComprehensiveScanReport?

    @Published var includeJunkCleanup = true
    @Published var includeCacheCleanup = true
    @Published var includeMemoryOptimization = true

    private let storageService = StorageManagerService()
    private let junkService = JunkCleanerService()
    private let cacheService = CacheCleanerService()
    private let memoryService = MemoryMonitorService()
    private let deviceService = DeviceMonitorService()

    init() {
        resetStages()
    }

    func resetStages() {
        stages = [
            ScanStageProgress(id: "storage", title: "Phân tích bộ nhớ thiết bị", subtitle: "Kiểm tra dung lượng khả dụng & sandbox", iconName: "internaldrive", progress: 0, foundBytes: 0, foundItemsCount: 0, isCompleted: false),
            ScanStageProgress(id: "junk", title: "Quét file rác & tệp tạm", subtitle: "tmp/, Logs, Staging & file lớn", iconName: "trash.slash", progress: 0, foundBytes: 0, foundItemsCount: 0, isCompleted: false),
            ScanStageProgress(id: "cache", title: "Kiểm tra bộ nhớ đệm ứng dụng", subtitle: "URLCache, Thumbnails & Snapshots", iconName: "tray.full", progress: 0, foundBytes: 0, foundItemsCount: 0, isCompleted: false),
            ScanStageProgress(id: "memory", title: "Đo lường RAM & tiến trình", subtitle: "host_statistics64 & TASK_VM_INFO", iconName: "memorychip", progress: 0, foundBytes: 0, foundItemsCount: 0, isCompleted: false),
            ScanStageProgress(id: "health", title: "Phân tích hiệu năng thiết bị", subtitle: "CPU, nhiệt độ, Low Power & yếu tố gây chậm", iconName: "speedometer", progress: 0, foundBytes: 0, foundItemsCount: 0, isCompleted: false)
        ]
    }

    func startSmartScan() async {
        resetStages()
        finalReport = nil
        overallProgress = 0.02

        // 1. Storage
        phase = .scanningStorage
        storageInfo = storageService.fetchDeviceStorageInfo()
        updateStage(id: "storage", progress: 1.0, foundBytes: storageInfo.appSandboxUsedBytes, count: 1, completed: true)
        overallProgress = 0.20

        // 2. Junk
        phase = .scanningJunk
        let scannedJunk = await junkService.scanSandboxJunk()
        junkItems = scannedJunk
        let junkBytes = scannedJunk.reduce(0) { $0 + $1.sizeBytes }
        updateStage(id: "junk", progress: 1.0, foundBytes: junkBytes, count: scannedJunk.count, completed: true)
        overallProgress = 0.45

        // 3. Cache
        phase = .scanningCache
        let scannedCache = cacheService.auditCachePartitions()
        cachePartitions = scannedCache
        let cleanableCacheBytes = scannedCache.filter(\.isDeletable).reduce(0) { $0 + $1.sizeBytes }
        let cleanableCacheFiles = scannedCache.filter(\.isDeletable).reduce(0) { $0 + $1.fileCount }
        updateStage(id: "cache", progress: 1.0, foundBytes: cleanableCacheBytes, count: cleanableCacheFiles, completed: true)
        overallProgress = 0.68

        // 4. Memory
        phase = .scanningMemory
        ramSnapshot = memoryService.captureSnapshot()
        updateStage(id: "memory", progress: 1.0, foundBytes: Int64(ramSnapshot.appFootprintBytes), count: 1, completed: true)
        overallProgress = 0.85

        // 5. Device Health
        phase = .scanningDeviceHealth
        slowdownFactors = deviceService.analyzeSlowdownFactors()
        updateStage(id: "health", progress: 1.0, foundBytes: 0, count: slowdownFactors.count, completed: true)
        overallProgress = 1.0
        phase = .completed

        await DiagnosticLogger.shared.log(
            "SmartScan completed: junk=\(junkBytes) bytes, cache=\(cleanableCacheBytes) bytes, factors=\(slowdownFactors.count).",
            category: "SmartScan"
        )
    }

    var selectedReclaimableDiskBytes: Int64 {
        var total: Int64 = 0
        if includeJunkCleanup {
            total += junkItems.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
        }
        if includeCacheCleanup {
            total += cachePartitions.filter { $0.isDeletable && $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
        }
        return total
    }

    var totalSelectedItemsCount: Int {
        var count = 0
        if includeJunkCleanup {
            count += junkItems.filter(\.isSelected).count
        }
        if includeCacheCleanup {
            count += cachePartitions.filter { $0.isDeletable && $0.isSelected }.reduce(0) { $0 + $1.fileCount }
        }
        return count
    }

    func executeSelectedCleanup() async {
        phase = .cleaning
        let beforeStorage = storageService.fetchDeviceStorageInfo()
        let beforeRAM = memoryService.captureSnapshot()
        let foundBefore = selectedReclaimableDiskBytes

        var totalFreedDisk: Int64 = 0
        var totalFilesProcessed = 0

        if includeJunkCleanup {
            let summary = await junkService.cleanSelectedItems(junkItems)
            totalFreedDisk += summary.freedBytes
            totalFilesProcessed += summary.deletedFilesCount
        }

        if includeCacheCleanup {
            let cacheResult = await cacheService.cleanSelectedCaches(cachePartitions)
            totalFreedDisk += cacheResult.freedBytes
            totalFilesProcessed += cacheResult.cleanedPartitionsCount
        }

        var reclaimedRAM: Int64 = 0
        if includeMemoryOptimization {
            let ramResult = await memoryService.performSafeMemoryCleanup()
            reclaimedRAM = max(0, ramResult.appFootprintDeltaBytes)
            ramSnapshot = ramResult.afterSnapshot
        } else {
            ramSnapshot = memoryService.captureSnapshot()
        }

        let afterStorage = storageService.fetchDeviceStorageInfo()
        storageInfo = afterStorage
        junkItems = await junkService.scanSandboxJunk()
        cachePartitions = cacheService.auditCachePartitions()

        finalReport = ComprehensiveScanReport(
            beforeStorageAvailableBytes: beforeStorage.availableBytes,
            afterStorageAvailableBytes: afterStorage.availableBytes,
            beforeAppFootprintBytes: beforeRAM.appFootprintBytes,
            afterAppFootprintBytes: ramSnapshot.appFootprintBytes,
            totalReclaimableBytesFound: foundBefore,
            totalFilesProcessed: totalFilesProcessed,
            actualFreedDiskBytes: totalFreedDisk,
            actualReclaimedRAMBytes: reclaimedRAM,
            timestamp: Date()
        )

        phase = .cleaned
    }

    private func updateStage(id: String, progress: Double, foundBytes: Int64, count: Int, completed: Bool) {
        if let idx = stages.firstIndex(where: { $0.id == id }) {
            stages[idx].progress = progress
            stages[idx].foundBytes = foundBytes
            stages[idx].foundItemsCount = count
            stages[idx].isCompleted = completed
        }
    }
}
