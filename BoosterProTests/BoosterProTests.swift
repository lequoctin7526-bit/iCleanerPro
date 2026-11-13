import CoreGraphics
import XCTest
@testable import BoosterPro

final class BoosterProTests: XCTestCase {

    func testJunkSizeTierClassification() {
        XCTAssertEqual(JunkSizeTier.tier(for: 512_000), .small)
        XCTAssertEqual(JunkSizeTier.tier(for: 2 * 1_048_576), .medium)
        XCTAssertEqual(JunkSizeTier.tier(for: 25 * 1_048_576), .large)
        XCTAssertEqual(JunkSizeTier.tier(for: 80 * 1_048_576), .huge)
    }

    func testJunkCleanerScansAndDeletesRealTempFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("unit_test_junk_\(UUID().uuidString).tmp")
        let data = Data(repeating: 0x5A, count: 64 * 1024)
        try data.write(to: testFile, options: .atomic)

        defer { try? FileManager.default.removeItem(at: testFile) }

        let service = JunkCleanerService()
        let items = await service.scanSandboxJunk()
        let matched = items.first { $0.url.lastPathComponent == testFile.lastPathComponent }
        XCTAssertNotNil(matched)
        XCTAssertGreaterThanOrEqual(matched?.sizeBytes ?? 0, Int64(data.count))

        if var target = matched {
            target.isSelected = true
            let summary = await service.cleanSelectedItems([target])
            XCTAssertEqual(summary.deletedFilesCount, 1)
            XCTAssertGreaterThanOrEqual(summary.freedBytes, Int64(data.count))
            XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path))
        }
    }

    func testCacheCleanerProtectsUserPreferencesAndDocuments() {
        let cacheService = CacheCleanerService()
        let partitions = cacheService.auditCachePartitions()

        let protected = partitions.filter { !$0.isDeletable }
        XCTAssertFalse(protected.isEmpty)
        XCTAssertTrue(protected.allSatisfy { !$0.isSelected })
    }

    func testMemoryMonitorReadsRealPhysicalRAM() {
        let service = MemoryMonitorService()
        let snapshot = service.captureSnapshot()

        XCTAssertGreaterThan(snapshot.totalPhysicalBytes, 0)
        XCTAssertGreaterThan(snapshot.appFootprintBytes, 0)
    }

    func testImageHasherDetectsIdenticalAndDifferentImages() {
        let identicalA = makeGradientCGImage(reverse: false)
        let identicalB = makeGradientCGImage(reverse: false)
        let reversed = makeGradientCGImage(reverse: true)

        guard let hashA = identicalA.flatMap(ImageHasher.computeDHash(for:)),
              let hashB = identicalB.flatMap(ImageHasher.computeDHash(for:)),
              let hashRev = reversed.flatMap(ImageHasher.computeDHash(for:)) else {
            XCTFail("Failed to compute dHash for test images")
            return
        }

        XCTAssertEqual(ImageHasher.hammingDistance(hashA, hashB), 0)
        XCTAssertGreaterThan(ImageHasher.hammingDistance(hashA, hashRev), 15)
    }

    func testGameBoosterReadinessEvaluation() {
        let service = GameBoosterService.shared
        let report = service.evaluateReadiness()

        XCTAssertGreaterThanOrEqual(report.score, 10)
        XCTAssertLessThanOrEqual(report.score, 100)
        XCTAssertFalse(report.summary.isEmpty)
    }

    func testGameLibraryPersistence() {
        let service = GameBoosterService.shared
        let initialGames = service.loadGames()
        XCTAssertFalse(initialGames.isEmpty)

        let testGame = GameItem(
            name: "Test Game \(UUID().uuidString)",
            category: .moba,
            urlScheme: "testgame://"
        )
        let updated = service.addGame(testGame)
        XCTAssertTrue(updated.contains(where: { $0.id == testGame.id }))

        let afterDelete = service.deleteGame(id: testGame.id)
        XCTAssertFalse(afterDelete.contains(where: { $0.id == testGame.id }))
    }

    func testIntroSlideItemsIntegrity() {
        let slides = IntroSlideItem.defaultSlides
        XCTAssertEqual(slides.count, 4)
        for slide in slides {
            XCTAssertFalse(slide.title.isEmpty)
            XCTAssertFalse(slide.subtitle.isEmpty)
            XCTAssertFalse(slide.badgeText.isEmpty)
            XCTAssertFalse(slide.iconName.isEmpty)
            XCTAssertFalse(slide.gradientColors.isEmpty)
        }
    }

    func testVersionComparatorLogic() {
        XCTAssertTrue(VersionComparator.isNewer(storeVersion: "1.55.0", installedVersion: "1.54.1"))
        XCTAssertTrue(VersionComparator.isNewer(storeVersion: "2.0", installedVersion: "1.9.9"))
        XCTAssertTrue(VersionComparator.isNewer(storeVersion: "3.2.1", installedVersion: "3.2.0"))
        XCTAssertFalse(VersionComparator.isNewer(storeVersion: "1.0.0", installedVersion: "1.0.0"))
        XCTAssertFalse(VersionComparator.isNewer(storeVersion: "1.2.0", installedVersion: "1.2.1"))
        XCTAssertFalse(VersionComparator.isNewer(storeVersion: "1.0", installedVersion: "1.0.0"))
    }

    func testSmartGameModelUpdateDetection() {
        var game = SmartGameModel(
            name: "Test Game",
            bundleId: "com.test.game",
            appStoreId: "123456789",
            installedVersion: "1.2.0",
            latestStoreVersion: "1.3.0"
        )
        XCTAssertTrue(game.hasUpdateAvailable)

        game.latestStoreVersion = "1.2.0"
        XCTAssertFalse(game.hasUpdateAvailable)

        game.latestStoreVersion = nil
        XCTAssertFalse(game.hasUpdateAvailable)
    }

    func testGamePresetCatalogIntegrity() {
        let presets = GamePresetCatalog.presets
        XCTAssertFalse(presets.isEmpty)
        for preset in presets {
            XCTAssertFalse(preset.name.isEmpty)
            XCTAssertFalse(preset.bundleId.isEmpty)
            XCTAssertFalse(preset.appStoreId.isEmpty)
            XCTAssertNotNil(preset.urlScheme)
        }
    }

    func testSmartGameManagerSettingsPersistence() {
        let service = SmartGameManagerService.shared
        var settings = service.loadSettings()
        settings.autoOptimizeBeforePlay.toggle()
        service.saveSettings(settings)

        let reloaded = service.loadSettings()
        XCTAssertEqual(reloaded.autoOptimizeBeforePlay, settings.autoOptimizeBeforePlay)
    }

    func testDeviceStorageInfoMetrics() {
        let service = StorageManagerService()
        let info = service.fetchDeviceStorageInfo()
        XCTAssertGreaterThan(info.totalBytes, 0)
        XCTAssertGreaterThanOrEqual(info.availableBytes, 0)
        XCTAssertGreaterThanOrEqual(info.usedPercentage, 0.0)
        XCTAssertLessThanOrEqual(info.usedPercentage, 1.0)
    }

    @MainActor
    func testDeviceMonitorCPUMetrics() {
        let service = DeviceMonitorService()
        let metrics = service.collectCPUMetrics()
        XCTAssertGreaterThan(metrics.processorCount, 0)
        XCTAssertGreaterThan(metrics.activeProcessorCount, 0)
        XCTAssertGreaterThanOrEqual(metrics.appCPUUsagePercent, 0.0)
    }

    @MainActor
    func testDeviceSlowdownAnalysis() {
        let service = DeviceMonitorService()
        let factors = service.analyzeSlowdownFactors()
        for factor in factors {
            XCTAssertFalse(factor.title.isEmpty)
            XCTAssertFalse(factor.recommendation.isEmpty)
        }
    }

    func testByteFormatterUtilities() {
        XCTAssertFalse(ByteFormatterUtil.formatFileSize(1024).isEmpty)
        XCTAssertFalse(ByteFormatterUtil.formatMemorySize(UInt64(1024 * 1024 * 50)).isEmpty)
        XCTAssertEqual(ByteFormatterUtil.formatPercentage(0.45), "45%")
        XCTAssertEqual(ByteFormatterUtil.formatPercentage(1.0), "100%")
        XCTAssertEqual(ByteFormatterUtil.formatDuration(3665), "1h 1m")
    }

    func testSafeMemoryPurge() async {
        let service = MemoryMonitorService()
        let result = await service.performSafeMemoryCleanup()
        XCTAssertGreaterThanOrEqual(result.appFootprintAfter, 0)
    }

    private func makeGradientCGImage(reverse: Bool) -> CGImage? {
        let width = 32
        let height = 32
        var pixels = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let value = UInt8((x * 255) / (width - 1))
                pixels[y * width + x] = reverse ? (255 - value) : value
            }
        }

        return pixels.withUnsafeMutableBytes { ptr -> CGImage? in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return nil
            }
            return context.makeImage()
        }
    }
}
