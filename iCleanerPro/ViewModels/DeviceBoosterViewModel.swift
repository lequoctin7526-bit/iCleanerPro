import Foundation
import UIKit

@MainActor
final class DeviceBoosterViewModel: ObservableObject {
    @Published var cpuMetrics: CPUMetrics = .empty
    @Published var slowdownFactors: [SlowdownFactor] = []
    @Published var optimizationResults: [OptimizationStepResult] = []
    @Published var isOptimizing = false
    @Published var hasOptimized = false

    private let deviceService = DeviceMonitorService()

    func refreshMetrics() {
        cpuMetrics = deviceService.collectCPUMetrics()
        slowdownFactors = deviceService.analyzeSlowdownFactors()
    }

    func runSafeOptimization() async {
        isOptimizing = true
        defer { isOptimizing = false }

        let steps = await deviceService.runSafeOptimizationRoutine()
        optimizationResults = steps
        hasOptimized = true
        refreshMetrics()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
