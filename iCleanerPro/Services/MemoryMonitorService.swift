import Darwin
import Foundation
import os
import Photos

/// Reads real system RAM statistics via Mach `host_statistics64`, app memory footprint via `task_info(TASK_VM_INFO)`,
/// and process available memory via `os_proc_available_memory()`.
/// Only releases memory managed by this application using standard iOS memory APIs.
final class MemoryMonitorService {

    func captureSnapshot() -> RAMSnapshot {
        let totalPhysical = ProcessInfo.processInfo.physicalMemory
        let pageSize = UInt64(vm_kernel_page_size)

        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let hostResult: kern_return_t = withUnsafeMutablePointer(to: &vmStats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        var wired: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        var compressed: UInt64 = 0
        var free: UInt64 = 0

        if hostResult == KERN_SUCCESS {
            wired = UInt64(vmStats.wire_count) * pageSize
            active = UInt64(vmStats.active_count) * pageSize
            inactive = UInt64(vmStats.inactive_count) * pageSize
            compressed = UInt64(vmStats.compressor_page_count) * pageSize
            free = UInt64(vmStats.free_count) * pageSize
        }

        let appFootprint = readAppPhysicalFootprint()
        let procAvailable = UInt64(max(0, os_proc_available_memory()))

        return RAMSnapshot(
            timestamp: Date(),
            totalPhysicalBytes: totalPhysical,
            wiredBytes: wired,
            activeBytes: active,
            inactiveBytes: inactive,
            compressedBytes: compressed,
            freeBytes: free,
            appFootprintBytes: appFootprint,
            procAvailableBytes: procAvailable
        )
    }

    private func readAppPhysicalFootprint() -> UInt64 {
        var vmInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.stride / MemoryLayout<natural_t>.stride
        )

        let result: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return vmInfo.phys_footprint
    }

    /// Safely releases in-app caches, image caches, URLCache memory/disk entries, and autoreleased buffers.
    /// Does not claim to terminate other apps or clear global OS wired RAM.
    func performSafeMemoryCleanup() async -> RAMCleanupResult {
        let before = captureSnapshot()
        var purged: [String] = []

        autoreleasepool {
            // 1. Purge in-memory thumbnail NSCache
            ImageCacheManager.shared.purgeAll()
            purged.append("Bộ nhớ đệm hình ảnh nội bộ (NSCache)")

            // 2. Purge URLCache responses in memory & disk
            URLCache.shared.removeAllCachedResponses()
            purged.append("Bộ nhớ đệm mạng (URLCache)")

            // 3. Stop PhotoKit image pre-caching if authorized
            let auth = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if auth == .authorized || auth == .limited {
                PhotoAnalysisService.sharedCachingManager.stopCachingImagesForAllAssets()
                purged.append("Bộ đệm xem trước ảnh (PHCachingImageManager)")
            }
        }

        // Allow ARC/kernel accounting a brief moment to settle before measuring after-snapshot.
        try? await Task.sleep(nanoseconds: 250_000_000)

        let after = captureSnapshot()
        let footprintDelta = Int64(before.appFootprintBytes) - Int64(after.appFootprintBytes)
        let availableDelta = Int64(after.procAvailableBytes) - Int64(before.procAvailableBytes)

        await DiagnosticLogger.shared.log(
            "Safe RAM optimization executed. App footprint before=\(before.appFootprintBytes), after=\(after.appFootprintBytes).",
            category: "MemoryMonitor"
        )

        return RAMCleanupResult(
            beforeSnapshot: before,
            afterSnapshot: after,
            appFootprintDeltaBytes: footprintDelta,
            availableMemoryDeltaBytes: availableDelta,
            purgedComponents: purged,
            timestamp: Date()
        )
    }
}
