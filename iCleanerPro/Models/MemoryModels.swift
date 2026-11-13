import Foundation

enum MemoryPressureLevel: String {
    case normal = "Ổn định"
    case elevated = "Trung bình"
    case high = "Áp lực cao"
}

/// Real RAM and process memory snapshot read via Mach host_statistics64, task_info, and os_proc_available_memory.
struct RAMSnapshot: Equatable {
    let timestamp: Date
    let totalPhysicalBytes: UInt64
    let wiredBytes: UInt64
    let activeBytes: UInt64
    let inactiveBytes: UInt64
    let compressedBytes: UInt64
    let freeBytes: UInt64
    let appFootprintBytes: UInt64
    let procAvailableBytes: UInt64

    /// System memory actively held by kernel/apps (Wired + Active + Compressed).
    var usedSystemBytes: UInt64 {
        wiredBytes + activeBytes + compressedBytes
    }

    /// Memory immediately reclaimable or free (Free + Inactive).
    var reclaimableOrFreeBytes: UInt64 {
        freeBytes + inactiveBytes
    }

    var usedRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0 }
        return min(1.0, Double(usedSystemBytes) / Double(totalPhysicalBytes))
    }

    var freeRatio: Double {
        max(0.0, 1.0 - usedRatio)
    }

    var pressureLevel: MemoryPressureLevel {
        if usedRatio >= 0.85 {
            return .high
        } else if usedRatio >= 0.68 {
            return .elevated
        } else {
            return .normal
        }
    }

    static let empty = RAMSnapshot(
        timestamp: Date(),
        totalPhysicalBytes: ProcessInfo.processInfo.physicalMemory,
        wiredBytes: 0,
        activeBytes: 0,
        inactiveBytes: 0,
        compressedBytes: 0,
        freeBytes: 0,
        appFootprintBytes: 0,
        procAvailableBytes: 0
    )
}

/// Real before/after measurement of safe in-app memory reclamation.
struct RAMCleanupResult: Equatable {
    let beforeSnapshot: RAMSnapshot
    let afterSnapshot: RAMSnapshot
    let appFootprintDeltaBytes: Int64
    let availableMemoryDeltaBytes: Int64
    let purgedComponents: [String]
    let timestamp: Date
}
