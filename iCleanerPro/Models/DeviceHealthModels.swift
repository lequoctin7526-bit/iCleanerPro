import Foundation

/// Real CPU, thermal, battery, and process telemetry available via public iOS APIs.
struct CPUMetrics: Equatable {
    let appCPUUsagePercent: Double
    let activeThreadCount: Int
    let processorCount: Int
    let activeProcessorCount: Int
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerMode: Bool
    let systemUptimeSeconds: TimeInterval
    let batteryLevel: Float
    let batteryStateDescription: String
    let backgroundRefreshEnabled: Bool
    let screenBrightness: Double
    let timestamp: Date

    var thermalStateTitle: String {
        switch thermalState {
        case .nominal:
            return "Bình thường"
        case .fair:
            return "Hơi ấm"
        case .serious:
            return "Nóng (Có thể giảm xung)"
        case .critical:
            return "Quá nhiệt (Đang giới hạn CPU)"
        @unknown default:
            return "Không xác định"
        }
    }

    static let empty = CPUMetrics(
        appCPUUsagePercent: 0,
        activeThreadCount: 0,
        processorCount: ProcessInfo.processInfo.processorCount,
        activeProcessorCount: ProcessInfo.processInfo.activeProcessorCount,
        thermalState: .nominal,
        isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
        systemUptimeSeconds: ProcessInfo.processInfo.systemUptime,
        batteryLevel: -1,
        batteryStateDescription: "Không xác định",
        backgroundRefreshEnabled: true,
        screenBrightness: 0.5,
        timestamp: Date()
    )
}

/// Detected factor that may cause sluggishness or battery drain on iOS.
struct SlowdownFactor: Identifiable, Hashable {
    enum Severity: String {
        case low = "Nhẹ"
        case medium = "Trung bình"
        case high = "Cao"
    }

    let id: UUID
    let title: String
    let detail: String
    let severity: Severity
    let recommendation: String
    let canAutoOptimizeInApp: Bool

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        severity: Severity,
        recommendation: String,
        canAutoOptimizeInApp: Bool
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
        self.recommendation = recommendation
        self.canAutoOptimizeInApp = canAutoOptimizeInApp
    }
}

/// Result of a real safe optimization step executed by DeviceMonitorService.
struct OptimizationStepResult: Identifiable, Equatable {
    let id: UUID
    let stepName: String
    let detail: String
    let completed: Bool
    let bytesReclaimed: Int64

    init(
        id: UUID = UUID(),
        stepName: String,
        detail: String,
        completed: Bool,
        bytesReclaimed: Int64 = 0
    ) {
        self.id = id
        self.stepName = stepName
        self.detail = detail
        self.completed = completed
        self.bytesReclaimed = bytesReclaimed
    }
}
