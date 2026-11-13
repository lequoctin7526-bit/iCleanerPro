import CoreGraphics
import CryptoKit
import Foundation
import Vision

/// Provides perceptual difference hashing (dHash), Vision feature-print comparison, and SHA-256 hashing
/// using strictly public Apple frameworks (CoreGraphics, Vision, CryptoKit).
enum ImageHasher {
    /// Computes a 64-bit difference hash (dHash) by sampling a 9x8 grayscale grid
    /// and comparing horizontal adjacent luminance values.
    static func computeDHash(for cgImage: CGImage) -> UInt64? {
        let width = 9
        let height = 8
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hash: UInt64 = 0
        var bitIndex = 0

        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<(width - 1) {
                if pixels[rowOffset + x] > pixels[rowOffset + x + 1] {
                    hash |= (1 << bitIndex)
                }
                bitIndex += 1
            }
        }

        return hash
    }

    /// Computes Hamming distance between two 64-bit dHashes (0 = identical, <= 6 = visually similar).
    static func hammingDistance(_ lhs: UInt64, _ rhs: UInt64) -> Int {
        (lhs ^ rhs).nonzeroBitCount
    }

    /// Generates an Apple Vision feature print observation for high-accuracy visual similarity comparison.
    static func generateFeaturePrint(for cgImage: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }

    /// Computes normalized feature-print distance between two Vision observations.
    /// Lower distance indicates higher similarity (typically < 0.25 for burst/duplicate photos).
    static func featurePrintDistance(
        _ first: VNFeaturePrintObservation,
        _ second: VNFeaturePrintObservation
    ) -> Float? {
        var distance: Float = 0
        do {
            try first.computeDistance(&distance, to: second)
            return distance
        } catch {
            return nil
        }
    }

    /// Computes exact SHA-256 hex digest for binary data comparison.
    static func sha256Digest(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
