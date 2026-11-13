import Foundation
import UIKit

/// Manages real internal NSCache thumbnails and structured operational logs inside Library/Logs.
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
        cache.totalCostLimit = 48 * 1024 * 1024
    }

    func setImage(_ image: UIImage, forKey key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func purgeAll() {
        cache.removeAllObjects()
    }
}

/// Persists real session diagnostic entries inside Library/Logs so users can inspect and clean real logs.
actor DiagnosticLogger {
    static let shared = DiagnosticLogger()

    private let fileManager = FileManager.default

    var logsDirectoryURL: URL {
        let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return libraryURL.appendingPathComponent("Logs", isDirectory: true)
    }

    private var currentLogFileURL: URL {
        logsDirectoryURL.appendingPathComponent("boosterpro_session.log")
    }

    func log(_ message: String, category: String = "System") {
        do {
            if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
                try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
            }
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let line = "[\(timestamp)] [\(category)] \(message)\n"
            if let data = line.data(using: .utf8) {
                if fileManager.fileExists(atPath: currentLogFileURL.path) {
                    let handle = try FileHandle(forWritingTo: currentLogFileURL)
                    defer { try? handle.close() }
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                } else {
                    try data.write(to: currentLogFileURL, options: .atomic)
                }
            }
        } catch {
            // Silently ignore logging I/O error to avoid disrupting primary user action.
        }
    }

    func clearLogs() -> Int64 {
        guard fileManager.fileExists(atPath: logsDirectoryURL.path) else { return 0 }
        var freed: Int64 = 0
        if let contents = try? fileManager.contentsOfDirectory(
            at: logsDirectoryURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            for url in contents {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
                if (try? fileManager.removeItem(at: url)) != nil {
                    freed += size
                }
            }
        }
        return freed
    }
}
