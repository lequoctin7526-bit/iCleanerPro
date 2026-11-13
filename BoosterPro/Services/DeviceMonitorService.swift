import Darwin
import Foundation
import UIKit

/// Monitors CPU thread utilization (within app sandbox via Mach thread_info), thermal state,
/// battery level, Low Power Mode, and identifies real device slowdown factors.
final class DeviceMonitorService {
    private let storageService = StorageManagerService()
    private let memoryService = MemoryMonitorService()

    @MainActor
    func collectCPUMetrics() -> CPUMetrics {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let (cpuPercent, threadCount) = readAppThreadCPUUsage()
        let processInfo = ProcessInfo.processInfo
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryStateText: String
        switch UIDevice.current.batteryState {
        case .charging:
            batteryStateText = "Đang sạc"
        case .full:
            batteryStateText = "Pin đầy"
        case .unplugged:
            batteryStateText = "Đang dùng pin"
        case .unknown:
            batteryStateText = "Không xác định"
        @unknown default:
            batteryStateText = "Không xác định"
        }

        let bgRefresh = UIApplication.shared.backgroundRefreshStatus == .available
        let brightness = Double(UIScreen.main.brightness)

        return CPUMetrics(
            appCPUUsagePercent: cpuPercent,
            activeThreadCount: threadCount,
            processorCount: processInfo.processorCount,
            activeProcessorCount: processInfo.activeProcessorCount,
            thermalState: processInfo.thermalState,
            isLowPowerMode: processInfo.isLowPowerModeEnabled,
            systemUptimeSeconds: processInfo.systemUptime,
            batteryLevel: batteryLevel,
            batteryStateDescription: batteryStateText,
            backgroundRefreshEnabled: bgRefresh,
            screenBrightness: brightness,
            timestamp: Date()
        )
    }

    private func readAppThreadCPUUsage() -> (percent: Double, threadCount: Int) {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let kr = task_threads(mach_task_self_, &threadList, &threadCount)
        guard kr == KERN_SUCCESS, let threads = threadList else {
            return (0, 0)
        }

        defer {
            let size = vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), size)
        }

        var totalCPU: Double = 0

        for index in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var infoCount = mach_msg_type_number_t(
                MemoryLayout<thread_basic_info_data_t>.stride / MemoryLayout<integer_t>.stride
            )

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &infoCount)
                }
            }

            if infoResult == KERN_SUCCESS {
                let flags = Int(threadInfo.flags)
                let isIdle = (flags & 1) != 0
                if !isIdle {
                    totalCPU += (Double(threadInfo.cpu_usage) / 1000.0) * 100.0
                }
            }
        }

        return (min(100.0 * Double(ProcessInfo.processInfo.activeProcessorCount), totalCPU), Int(threadCount))
    }

    @MainActor
    func analyzeSlowdownFactors() -> [SlowdownFactor] {
        let cpu = collectCPUMetrics()
        let storage = storageService.fetchDeviceStorageInfo()
        let ram = memoryService.captureSnapshot()

        var factors: [SlowdownFactor] = []

        if cpu.thermalState == .serious || cpu.thermalState == .critical {
            factors.append(
                SlowdownFactor(
                    title: "Thiết bị đang bị nóng (\(cpu.thermalStateTitle))",
                    detail: "iOS tự động giảm xung nhịp CPU/GPU để bảo vệ phần cứng khi nhiệt độ tăng cao.",
                    severity: .high,
                    recommendation: "Đóng các tác vụ nặng hoặc game, tháo ốp lưng dày và để thiết bị nghỉ vài phút.",
                    canAutoOptimizeInApp: false
                )
            )
        } else if cpu.thermalState == .fair {
            factors.append(
                SlowdownFactor(
                    title: "Nhiệt độ thiết bị hơi ấm",
                    detail: "Hệ thống bắt đầu điều chỉnh nhẹ hiệu năng tản nhiệt.",
                    severity: .low,
                    recommendation: "Giảm độ sáng màn hình hoặc hạn chế vừa sạc vừa sử dụng tác vụ nặng.",
                    canAutoOptimizeInApp: false
                )
            )
        }

        if storage.isLowStorage {
            factors.append(
                SlowdownFactor(
                    title: "Bộ nhớ lưu trữ gần đầy (\(ByteFormatterUtil.formatPercentage(storage.usedPercentage)))",
                    detail: "Khi dung lượng trống dưới 15%, iOS gặp khó khăn khi tạo file hoán đổi bộ nhớ (swap) và bộ đệm hệ thống.",
                    severity: .high,
                    recommendation: "Giải phóng ảnh trùng lặp, video dung lượng lớn và file tạm trong Storage Manager.",
                    canAutoOptimizeInApp: true
                )
            )
        }

        if ram.pressureLevel == .high {
            factors.append(
                SlowdownFactor(
                    title: "Áp lực bộ nhớ RAM cao (\(ByteFormatterUtil.formatPercentage(ram.usedRatio)))",
                    detail: "Hệ thống đang nén bộ nhớ (\(ByteFormatterUtil.formatMemorySize(ram.compressedBytes))) do nhiều tác vụ đang chạy.",
                    severity: .medium,
                    recommendation: "Dọn dẹp bộ nhớ đệm của ứng dụng và đóng các ứng dụng nặng không dùng trong App Switcher.",
                    canAutoOptimizeInApp: true
                )
            )
        }

        if cpu.isLowPowerMode {
            factors.append(
                SlowdownFactor(
                    title: "Chế độ Nguồn điện thấp (Low Power Mode) đang bật",
                    detail: "iOS đang giới hạn xung nhịp CPU, tần số quét ProMotion và tác vụ nền để tiết kiệm pin.",
                    severity: .medium,
                    recommendation: "Tắt Chế độ Nguồn điện thấp trong Trung tâm điều khiển nếu cần hiệu năng tối đa.",
                    canAutoOptimizeInApp: false
                )
            )
        }

        if cpu.screenBrightness > 0.85 {
            factors.append(
                SlowdownFactor(
                    title: "Độ sáng màn hình ở mức rất cao (\(Int(cpu.screenBrightness * 100))%)",
                    detail: "Độ sáng cao làm tăng nhiệt độ màn hình và tiêu hao pin nhanh hơn.",
                    severity: .low,
                    recommendation: "Bật Độ sáng tự động hoặc giảm độ sáng xuống mức 50–70%.",
                    canAutoOptimizeInApp: false
                )
            )
        }

        if cpu.backgroundRefreshEnabled {
            factors.append(
                SlowdownFactor(
                    title: "Làm mới ứng dụng trong nền đang bật",
                    detail: "Nhiều ứng dụng có thể đồng bộ dữ liệu ngầm làm tăng tải CPU và tiêu hao pin.",
                    severity: .low,
                    recommendation: "Vào Cài đặt > Cài đặt chung > Làm mới ứng dụng trong nền để tắt các app không cần thiết.",
                    canAutoOptimizeInApp: false
                )
            )
        }

        return factors
    }

    /// Executes real safe in-app optimizations (purges internal caches, cleans temp directory, compacts logs).
    func runSafeOptimizationRoutine() async -> [OptimizationStepResult] {
        var results: [OptimizationStepResult] = []

        // Step 1: Safe Memory Reclamation
        let ramResult = await memoryService.performSafeMemoryCleanup()
        let reclaimedRAM = max(0, ramResult.appFootprintDeltaBytes)
        results.append(
            OptimizationStepResult(
                stepName: "Giải phóng bộ nhớ nội bộ ứng dụng",
                detail: "Đã xóa NSCache, URLCache và giải phóng vùng đệm không còn dùng.",
                completed: true,
                bytesReclaimed: reclaimedRAM
            )
        )

        // Step 2: Purge tmp/ files
        let junkService = JunkCleanerService()
        let junkItems = await junkService.scanSandboxJunk().filter {
            $0.category == .temporaryFiles || $0.category == .orphanedCaches
        }
        let junkSummary = await junkService.cleanSelectedItems(junkItems)
        results.append(
            OptimizationStepResult(
                stepName: "Dọn dẹp tệp tạm và bộ nhớ đệm sandbox",
                detail: "Đã xóa \(junkSummary.deletedFilesCount) file tạm an toàn.",
                completed: true,
                bytesReclaimed: junkSummary.freedBytes
            )
        )

        // Step 3: Compact diagnostic logs
        let logBytes = await DiagnosticLogger.shared.clearLogs()
        results.append(
            OptimizationStepResult(
                stepName: "Thu gọn nhật ký chẩn đoán cũ",
                detail: logBytes > 0
                    ? "Đã giải phóng \(ByteFormatterUtil.formatFileSize(logBytes)) nhật ký phiên cũ."
                    : "Nhật ký hệ thống đã ở trạng thái tối ưu.",
                completed: true,
                bytesReclaimed: logBytes
            )
        )

        await DiagnosticLogger.shared.log(
            "Safe device optimization routine finished with \(results.count) steps.",
            category: "DeviceMonitor"
        )

        return results
    }
}
