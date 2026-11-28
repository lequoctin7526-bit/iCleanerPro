import Foundation
import SwiftUI
import WebKit

enum CacheFilterOption: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case safe = "An toàn"
    case sensitive = "Cần lưu ý"
    case protected = "Bảo vệ"

    var id: String { rawValue }
}

@MainActor
final class CacheCleanerViewModel: ObservableObject {
    @Published var partitions: [CachePartitionItem] = []
    @Published var webViewRecords: [WebViewWebsiteDataRecordItem] = []
    @Published var cacheHistory: [CacheHistoryRecord] = []

    @Published var phase: ScanPhase = .idle
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var scanProgress: Double = 0.0

    @Published var lastResult: CacheCleanupResult?
    @Published var showConfirmDialog: Bool = false
    @Published var showSensitiveConfirmDialog: Bool = false
    @Published var showOtherAppsGuideSheet: Bool = false
    @Published var showWebViewSheet: Bool = false
    @Published var showHistorySheet: Bool = false
    @Published var selectedFilter: CacheFilterOption = .all

    private let cacheService = CacheCleanerService()

    init() {
        self.cacheHistory = cacheService.loadHistory()
    }

    // MARK: - Filtered Lists
    var filteredPartitions: [CachePartitionItem] {
        switch selectedFilter {
        case .all:
            return partitions
        case .safe:
            return partitions.filter { $0.isDeletable && $0.isSafeToClean }
        case .sensitive:
            return partitions.filter { $0.isDeletable && !$0.isSafeToClean }
        case .protected:
            return partitions.filter { !$0.isDeletable }
        }
    }

    var deletablePartitions: [CachePartitionItem] {
        partitions.filter(\.isDeletable)
    }

    var safePartitions: [CachePartitionItem] {
        partitions.filter { $0.isDeletable && $0.isSafeToClean }
    }

    var sensitivePartitions: [CachePartitionItem] {
        partitions.filter { $0.isDeletable && !$0.isSafeToClean }
    }

    var protectedPartitions: [CachePartitionItem] {
        partitions.filter { !$0.isDeletable }
    }

    // MARK: - Metrics
    var totalCleanableBytes: Int64 {
        deletablePartitions.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedCleanableBytes: Int64 {
        deletablePartitions.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    var safeCleanableBytes: Int64 {
        safePartitions.reduce(0) { $0 + $1.sizeBytes }
    }

    var totalProtectedBytes: Int64 {
        protectedPartitions.reduce(0) { $0 + $1.sizeBytes }
    }

    var totalFileCount: Int {
        deletablePartitions.reduce(0) { $0 + $1.fileCount }
    }

    var hasSensitiveSelection: Bool {
        deletablePartitions.contains { $0.isSelected && $0.requiresExplicitConfirmation }
    }

    // MARK: - Actions: Scanning
    func scanCaches() {
        guard !isScanning else { return }
        isScanning = true
        phase = .scanningCache
        scanProgress = 0.1

        Task {
            // Simulated micro-stage progress for smooth cyberpunk radar animation
            try? await Task.sleep(nanoseconds: 120_000_000)
            scanProgress = 0.45
            try? await Task.sleep(nanoseconds: 120_000_000)
            scanProgress = 0.85

            let scanned = cacheService.scanAllCacheCategories()
            self.partitions = scanned

            // Also load webview records asynchronously
            let records = await cacheService.fetchWebViewRecords()
            self.webViewRecords = records

            self.cacheHistory = cacheService.loadHistory()
            scanProgress = 1.0
            phase = .completed
            isScanning = false
        }
    }

    func togglePartition(id: UUID) {
        guard let idx = partitions.firstIndex(where: { $0.id == id }),
              partitions[idx].isDeletable else {
            return
        }
        partitions[idx].isSelected.toggle()
    }

    func selectAllSafe() {
        for idx in 0..<partitions.count {
            if partitions[idx].isDeletable {
                partitions[idx].isSelected = partitions[idx].isSafeToClean
            }
        }
    }

    func deselectAll() {
        for idx in 0..<partitions.count {
            if partitions[idx].isDeletable {
                partitions[idx].isSelected = false
            }
        }
    }

    // MARK: - Actions: Cleanup
    func cleanSelectedCaches() async {
        guard selectedCleanableBytes > 0, !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.cleanSelectedCaches(partitions)
        self.lastResult = result

        // Refresh state
        self.partitions = cacheService.scanAllCacheCategories()
        self.webViewRecords = await cacheService.fetchWebViewRecords()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func cleanAllSafeCaches() async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.cleanAllSafeCaches()
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.webViewRecords = await cacheService.fetchWebViewRecords()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func cleanOldCaches() async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.cleanOldCaches(olderThanDays: 3)
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func cleanTemporaryFiles() async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.cleanTemporaryFilesOnly()
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func clearImageCache() async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.clearImageCacheOnly()
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func clearURLCache() async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.clearURLCacheOnly()
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    func clearWebViewCache(includeCookies: Bool = false) async {
        guard !isCleaning else { return }
        isCleaning = true
        phase = .cleaning

        let result = await cacheService.clearWebViewCacheOnly(includeCookies: includeCookies)
        self.lastResult = result

        self.partitions = cacheService.scanAllCacheCategories()
        self.webViewRecords = await cacheService.fetchWebViewRecords()
        self.cacheHistory = cacheService.loadHistory()

        isCleaning = false
        phase = .cleaned
    }

    // MARK: - Actions: WebView Records
    func toggleWebViewRecord(id: String) {
        guard let idx = webViewRecords.firstIndex(where: { $0.id == id }) else { return }
        webViewRecords[idx].isSelected.toggle()
    }

    func deleteSelectedWebViewRecords(types: Set<String>) async {
        let targets = webViewRecords.filter(\.isSelected)
        guard !targets.isEmpty else { return }

        await cacheService.removeWebViewData(for: targets, types: types)
        self.webViewRecords = await cacheService.fetchWebViewRecords()
        self.partitions = cacheService.scanAllCacheCategories()
    }
}
