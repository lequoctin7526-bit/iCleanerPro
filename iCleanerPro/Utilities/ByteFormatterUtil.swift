import Foundation

enum ByteFormatterUtil {
    private static let fileFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    private static let memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func formatFileSize(_ bytes: Int64) -> String {
        fileFormatter.string(fromByteCount: max(0, bytes))
    }

    static func formatFileSize(_ bytes: UInt64) -> String {
        let clamped = bytes > UInt64(Int64.max) ? Int64.max : Int64(bytes)
        return fileFormatter.string(fromByteCount: clamped)
    }

    static func formatMemorySize(_ bytes: UInt64) -> String {
        let clamped = bytes > UInt64(Int64.max) ? Int64.max : Int64(bytes)
        return memoryFormatter.string(fromByteCount: clamped)
    }

    static func formatMemorySize(_ bytes: Int64) -> String {
        memoryFormatter.string(fromByteCount: max(0, bytes))
    }

    static func formatPercentage(_ ratio: Double) -> String {
        let pct = Int((min(1.0, max(0.0, ratio)) * 100.0).rounded())
        return "\(pct)%"
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m \(total % 60)s"
        }
    }

    static func formatMediaDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
