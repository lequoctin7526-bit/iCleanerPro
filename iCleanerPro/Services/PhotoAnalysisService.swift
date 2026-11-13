import Foundation
import Photos
import UIKit
import Vision

/// Integrates Apple's Photos Framework (PhotoKit) and Vision Framework to analyze large media
/// and detect duplicate/similar photos purely on-device with explicit user confirmation before deletion.
final class PhotoAnalysisService: @unchecked Sendable {
    static let sharedCachingManager = PHCachingImageManager()
    private var imageManager: PHCachingImageManager { Self.sharedCachingManager }

    func currentPermissionState() -> PhotoPermissionState {
        mapStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestPhotoPermission() async -> PhotoPermissionState {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return mapStatus(status)
    }

    private func mapStatus(_ status: PHAuthorizationStatus) -> PhotoPermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    /// Scans the user's authorized Photos/Videos above `minimumBytes` threshold.
    func scanLargeMedia(
        minimumBytes: Int64 = 10 * 1_048_576,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async -> [MediaAssetItem] {
        let status = currentPermissionState()
        guard status.canAccessPhotos else { return [] }

        return await Task.detached(priority: .userInitiated) { [self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: fetchOptions)

            let totalCount = assets.count
            guard totalCount > 0 else {
                progressHandler?(1.0)
                return []
            }

            var results: [MediaAssetItem] = []

            assets.enumerateObjects { asset, index, _ in
                let size = self.assetByteSize(for: asset)
                if size >= minimumBytes {
                    results.append(
                        MediaAssetItem(
                            id: asset.localIdentifier,
                            asset: asset,
                            mediaType: asset.mediaType,
                            fileSizeBytes: size,
                            creationDate: asset.creationDate,
                            pixelWidth: asset.pixelWidth,
                            pixelHeight: asset.pixelHeight,
                            duration: asset.duration,
                            isSelected: false
                        )
                    )
                }
                if index % 25 == 0 || index == totalCount - 1 {
                    progressHandler?(Double(index + 1) / Double(totalCount))
                }
            }

            return results.sorted { $0.fileSizeBytes > $1.fileSizeBytes }
        }.value
    }

    /// Detects exact and visually similar duplicate photos using 64-bit dHash + Vision FeaturePrint comparison.
    func scanDuplicatePhotos(
        maxAssetsToAnalyze: Int = 500,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async -> [DuplicatePhotoGroup] {
        let status = currentPermissionState()
        guard status.canAccessPhotos else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxAssetsToAnalyze
        let assetsResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        let total = assetsResult.count
        guard total > 1 else {
            progressHandler?(1.0)
            return []
        }

        struct AnalyzedPhoto {
            let item: MediaAssetItem
            let dHash: UInt64
            let featurePrint: VNFeaturePrintObservation?
        }

        var analyzed: [AnalyzedPhoto] = []
        analyzed.reserveCapacity(total)

        for index in 0..<total {
            let asset = assetsResult.object(at: index)
            if let cgImage = await requestThumbnailCGImage(for: asset, targetSize: CGSize(width: 192, height: 192)),
               let dHash = ImageHasher.computeDHash(for: cgImage) {
                let featurePrint = ImageHasher.generateFeaturePrint(for: cgImage)
                let size = assetByteSize(for: asset)
                let item = MediaAssetItem(
                    id: asset.localIdentifier,
                    asset: asset,
                    mediaType: asset.mediaType,
                    fileSizeBytes: size,
                    creationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    duration: asset.duration,
                    isSelected: false
                )
                analyzed.append(AnalyzedPhoto(item: item, dHash: dHash, featurePrint: featurePrint))
            }

            if index % 10 == 0 || index == total - 1 {
                progressHandler?(Double(index + 1) / Double(total) * 0.8)
            }
        }

        // Cluster similar images
        var visited = Set<String>()
        var groups: [DuplicatePhotoGroup] = []

        for i in 0..<analyzed.count {
            let anchor = analyzed[i]
            if visited.contains(anchor.item.id) { continue }

            var cluster: [AnalyzedPhoto] = [anchor]
            var bestSimilarity: Float = 1.0
            var isExact = true

            for j in (i + 1)..<analyzed.count {
                let candidate = analyzed[j]
                if visited.contains(candidate.item.id) { continue }

                let hamming = ImageHasher.hammingDistance(anchor.dHash, candidate.dHash)
                guard hamming <= 8 else { continue }

                var matched = false
                var similarity: Float = max(0, 1.0 - Float(hamming) / 64.0)

                if hamming <= 2 {
                    matched = true
                } else if let fpA = anchor.featurePrint,
                          let fpB = candidate.featurePrint,
                          let distance = ImageHasher.featurePrintDistance(fpA, fpB),
                          distance <= 0.35 {
                    matched = true
                    isExact = false
                    similarity = max(0.0, min(1.0, 1.0 - distance))
                }

                if matched {
                    cluster.append(candidate)
                    bestSimilarity = min(bestSimilarity, similarity)
                }
            }

            if cluster.count > 1 {
                cluster.forEach { visited.insert($0.item.id) }

                // Recommend keeping the highest resolution (and oldest creation date on tie).
                let sortedCluster = cluster.sorted { lhs, rhs in
                    let pixelsL = lhs.item.pixelWidth * lhs.item.pixelHeight
                    let pixelsR = rhs.item.pixelWidth * rhs.item.pixelHeight
                    if pixelsL != pixelsR {
                        return pixelsL > pixelsR
                    }
                    return (lhs.item.creationDate ?? .distantFuture) < (rhs.item.creationDate ?? .distantFuture)
                }

                let keepID = sortedCluster.first?.item.id ?? anchor.item.id
                let items = sortedCluster.map { entry -> MediaAssetItem in
                    var copy = entry.item
                    // Pre-select duplicates (excluding the recommended original to keep).
                    copy.isSelected = (copy.id != keepID)
                    return copy
                }

                groups.append(
                    DuplicatePhotoGroup(
                        matchType: isExact ? .exactHash : .visualSimilar,
                        similarityScore: bestSimilarity,
                        assets: items,
                        recommendedKeepAssetID: keepID
                    )
                )
            }
        }

        progressHandler?(1.0)
        return groups.sorted { $0.totalGroupBytes > $1.totalGroupBytes }
    }

    /// Requests a display thumbnail for SwiftUI views and caches it via ImageCacheManager.
    func loadThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let cacheKey = "\(asset.localIdentifier)_\(Int(targetSize.width))x\(Int(targetSize.height))"
        if let cached = ImageCacheManager.shared.image(forKey: cacheKey) {
            return cached
        }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            var resumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded && !resumed {
                    resumed = true
                    if let image = image {
                        ImageCacheManager.shared.setImage(image, forKey: cacheKey)
                    }
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Deletes only user-confirmed PHAssets via PhotoKit's standard confirmation dialog.
    func deleteAssets(_ items: [MediaAssetItem]) async throws -> Int64 {
        let assetsToDelete = items.map(\.asset)
        guard !assetsToDelete.isEmpty else { return 0 }

        let totalBytes = items.reduce(0) { $0 + $1.fileSizeBytes }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }

        await DiagnosticLogger.shared.log(
            "User confirmed deletion of \(assetsToDelete.count) media assets (~ \(totalBytes) bytes).",
            category: "PhotoAnalysis"
        )

        return totalBytes
    }

    private func requestThumbnailCGImage(for asset: PHAsset, targetSize: CGSize) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            var resumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if !resumed {
                    resumed = true
                    continuation.resume(returning: image?.cgImage)
                }
            }
        }
    }

    private func assetByteSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var total: Int64 = 0
        for resource in resources {
            if resource.responds(to: Selector(("fileSize"))),
               let val = resource.value(forKey: "fileSize") as? NSNumber {
                total += val.int64Value
            }
        }
        if total == 0 {
            let pixels = Int64(asset.pixelWidth * asset.pixelHeight)
            if asset.mediaType == .video {
                total = max(1_048_576, Int64(asset.duration * 2_500_000))
            } else {
                total = max(500_000, pixels * 2)
            }
        }
        return total
    }
}
