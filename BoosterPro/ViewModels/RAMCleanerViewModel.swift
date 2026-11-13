import Combine
import Foundation

@MainActor
final class RAMCleanerViewModel: ObservableObject {
    @Published var snapshot: RAMSnapshot = .empty
    @Published var isCleaning = false
    @Published var lastResult: RAMCleanupResult?
    @Published var historyFootprints: [UInt64] = []

    private let memoryService = MemoryMonitorService()
    private var timerCancellable: AnyCancellable?

    func startLiveMonitoring() {
        refreshSnapshot()
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshSnapshot()
            }
    }

    func stopLiveMonitoring() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func refreshSnapshot() {
        let current = memoryService.captureSnapshot()
        snapshot = current
        historyFootprints.append(current.appFootprintBytes)
        if historyFootprints.count > 20 {
            historyFootprints.removeFirst()
        }
    }

    func cleanAppMemory() async {
        isCleaning = true
        defer { isCleaning = false }

        let result = await memoryService.performSafeMemoryCleanup()
        lastResult = result
        snapshot = result.afterSnapshot
    }
}
