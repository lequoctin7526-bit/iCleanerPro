import Foundation

@MainActor
final class CacheCleanerViewModel: ObservableObject {
    @Published var partitions: [CachePartitionItem] = []
    @Published var phase: ScanPhase = .idle
    @Published var lastResult: CacheCleanupResult?
    @Published var showConfirmDialog = false

    private let cacheService = CacheCleanerService()

    var deletablePartitions: [CachePartitionItem] {
        partitions.filter(\.isDeletable)
    }

    var protectedPartitions: [CachePartitionItem] {
        partitions.filter { !$0.isDeletable }
    }

    var totalCleanableBytes: Int64 {
        deletablePartitions.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedCleanableBytes: Int64 {
        deletablePartitions.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    var totalProtectedBytes: Int64 {
        protectedPartitions.reduce(0) { $0 + $1.sizeBytes }
    }

    func scanCaches() {
        phase = .scanningCache
        partitions = cacheService.auditCachePartitions()
        phase = .completed
    }

    func togglePartition(id: UUID) {
        guard let idx = partitions.firstIndex(where: { $0.id == id }),
              partitions[idx].isDeletable else {
            return
        }
        partitions[idx].isSelected.toggle()
    }

    func cleanSelectedCaches() async {
        guard selectedCleanableBytes > 0 else { return }
        phase = .cleaning
        let result = await cacheService.cleanSelectedCaches(partitions)
        lastResult = result
        partitions = cacheService.auditCachePartitions()
        phase = .cleaned
    }
}
