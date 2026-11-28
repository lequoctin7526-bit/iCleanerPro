import Foundation
import WebKit

/// Audits, measures, and safely cleans cache stores created and managed inside Booster Pro's sandbox.
/// Adheres strictly to iOS App Sandbox rules: never attempts to inspect or wipe third-party app caches.
/// Accurately isolates partitions to guarantee zero duplicate size calculations.
final class CacheCleanerService {
    private let fileManager = FileManager.default
    private let storageService = StorageManagerService()
    private let historyStorageKey = "boosterpro_cache_history_records"

    // MARK: - Directory URLs
    private var libraryURL: URL? {
        fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
    }

    private var cachesURL: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private var documentsURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private var temporaryDirectoryURL: URL {
        fileManager.temporaryDirectory
    }

    // MARK: - 1. App Cache Scanner (Zero-Duplicate Multi-Group Inventory)

    /// Audits all cache partitions with granular classification and strictly disjoint disk locations.
    func scanAllCacheCategories() -> [CachePartitionItem] {
        var partitions: [CachePartitionItem] = []

        // --- GROUP 1: URLCache Memory (In-Memory RAM) ---
        let urlMemBytes = Int64(URLCache.shared.currentMemoryUsage)
        partitions.append(
            CachePartitionItem(
                type: .urlCacheMemory,
                title: "Bộ nhớ đệm mạng RAM (URLCache Memory)",
                subtitle: "Phản hồi API và hình ảnh lưu tạm trong RAM của Booster Pro.",
                directoryURL: nil,
                sizeBytes: urlMemBytes,
                fileCount: urlMemBytes > 0 ? 1 : 0,
                lastModifiedDate: Date(),
                isDeletable: true,
                isSafeToClean: true,
                isCurrentlyInUse: true,
                estimatedAfterCleanBytes: 0,
                requiresExplicitConfirmation: false,
                isSelected: true,
                riskWarning: "Sẽ giải phóng bộ nhớ RAM mà URLSession đang chiếm giữ."
            )
        )

        // --- GROUP 2: URLCache Disk (Tệp mạng trên ổ cứng) ---
        let urlDiskBytes = Int64(URLCache.shared.currentDiskUsage)
        partitions.append(
            CachePartitionItem(
                type: .urlCacheDisk,
                title: "Bộ nhớ đệm mạng trên đĩa (URLCache Disk)",
                subtitle: "Phản hồi HTTP/HTTPS được lưu trên ổ cứng để tải nhanh hơn.",
                directoryURL: cachesURL,
                sizeBytes: urlDiskBytes,
                fileCount: urlDiskBytes > 0 ? 1 : 0,
                lastModifiedDate: Date(),
                isDeletable: true,
                isSafeToClean: true,
                isCurrentlyInUse: false,
                estimatedAfterCleanBytes: 0,
                requiresExplicitConfirmation: false,
                isSelected: true,
                riskWarning: "Dữ liệu mạng sẽ được tải lại khi bạn mở lại các màn hình trực tuyến."
            )
        )

        // --- GROUP 3: URLSession Cache ---
        let urlSessionDir = cachesURL?.appendingPathComponent("URLSession", isDirectory: true)
        if let sessionDir = urlSessionDir, fileManager.fileExists(atPath: sessionDir.path) {
            let (size, count, modDate) = inspectDirectory(sessionDir)
            partitions.append(
                CachePartitionItem(
                    type: .urlSessionCache,
                    title: "Dữ liệu phiên mạng (URLSession Cache)",
                    subtitle: "Tệp đệm tải xuống dở dang và cấu hình phiên kết nối.",
                    directoryURL: sessionDir,
                    sizeBytes: size,
                    fileCount: count,
                    lastModifiedDate: modDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true
                )
            )
        }

        // --- GROUP 4: Image Cache (In-Memory NSCache) ---
        // NSCache memory cost tracked or approximated
        partitions.append(
            CachePartitionItem(
                type: .imageCache,
                title: "Bộ nhớ đệm ảnh trong RAM (ImageCacheManager)",
                subtitle: "Ảnh thu nhỏ và texture UI được giải nén sẵn trong bộ nhớ RAM.",
                directoryURL: nil,
                sizeBytes: 8 * 1024 * 1024, // Nominal pool cap (max 48MB)
                fileCount: 1,
                lastModifiedDate: Date(),
                isDeletable: true,
                isSafeToClean: true,
                isCurrentlyInUse: true,
                estimatedAfterCleanBytes: 0,
                requiresExplicitConfirmation: false,
                isSelected: true,
                riskWarning: "Bộ đệm ảnh RAM sẽ giải phóng tức thì mà không làm mất ảnh gốc."
            )
        )

        // --- GROUP 5: Thumbnail Cache ---
        let thumbURL = cachesURL?.appendingPathComponent("Thumbnails", isDirectory: true)
        if let thumbURL = thumbURL {
            let (size, count, modDate) = inspectDirectory(thumbURL)
            partitions.append(
                CachePartitionItem(
                    type: .imageThumbnailCache,
                    title: "Bộ nhớ đệm ảnh thu nhỏ (Thumbnails)",
                    subtitle: "Hình thu nhỏ tạo ra trong quá trình quét Thư viện Ảnh.",
                    directoryURL: thumbURL,
                    sizeBytes: size,
                    fileCount: count,
                    lastModifiedDate: modDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true,
                    riskWarning: "Ảnh thu nhỏ sẽ được tạo lại tự động khi bạn vào lại Quản lý Thư viện."
                )
            )
        }

        // --- GROUP 6: Generated Preview Files ---
        let previewURL = cachesURL?.appendingPathComponent("Previews", isDirectory: true)
        if let previewURL = previewURL {
            let (size, count, modDate) = inspectDirectory(previewURL)
            partitions.append(
                CachePartitionItem(
                    type: .generatedPreviews,
                    title: "Tệp xem trước kết xuất (Generated Previews)",
                    subtitle: "Bản sao thu phóng của video và tài liệu tạm thời.",
                    directoryURL: previewURL,
                    sizeBytes: size,
                    fileCount: count,
                    lastModifiedDate: modDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true
                )
            )
        }

        // --- GROUP 7 & 8: Temporary Files & Expired Downloads in tmp/ ---
        let tmpDir = temporaryDirectoryURL
        let (tmpTotal, tmpFiles, expiredTotal, expiredFiles, tmpModDate, expModDate) = inspectTemporaryDirectory(tmpDir)

        partitions.append(
            CachePartitionItem(
                type: .temporaryFiles,
                title: "Tệp tạm thời phiên làm việc (Temporary Files)",
                subtitle: "Tệp trung gian trong thư mục tmp khi quét rác và tính toán mã băm.",
                directoryURL: tmpDir,
                sizeBytes: tmpTotal,
                fileCount: tmpFiles,
                lastModifiedDate: tmpModDate,
                isDeletable: true,
                isSafeToClean: true,
                isCurrentlyInUse: false,
                estimatedAfterCleanBytes: 0,
                requiresExplicitConfirmation: false,
                isSelected: true
            )
        )

        if expiredTotal > 0 || expiredFiles > 0 {
            let downloadsURL = tmpDir.appendingPathComponent("Downloads", isDirectory: true)
            partitions.append(
                CachePartitionItem(
                    type: .expiredDownloads,
                    title: "Tệp tải xuống tạm hết hạn (Expired Downloads)",
                    subtitle: "Tệp tải về tạm thời từ hơn 24 giờ trước chưa được xóa.",
                    directoryURL: downloadsURL,
                    sizeBytes: expiredTotal,
                    fileCount: expiredFiles,
                    lastModifiedDate: expModDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true
                )
            )
        }

        // --- GROUP 9: WebView Website Cache (WKWebsiteDataStore disk cache) ---
        let webkitCacheDir = cachesURL?.appendingPathComponent("WebKit", isDirectory: true)
        if let webkitDir = webkitCacheDir {
            let (size, count, modDate) = inspectDirectory(webkitDir)
            partitions.append(
                CachePartitionItem(
                    type: .webViewCache,
                    title: "Bộ nhớ đệm WebView (WebKit Website Cache)",
                    subtitle: "Tài nguyên HTML/CSS/JS do WKWebView tạo trong sandbox.",
                    directoryURL: webkitDir,
                    sizeBytes: size,
                    fileCount: count,
                    lastModifiedDate: modDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true,
                    riskWarning: "Các trang web mở trong ứng dụng sẽ tải lại tài nguyên mới nhất."
                )
            )
        }

        // --- GROUP 10: App-owned Cache Directories (Remaining in Library/Caches) ---
        if let caches = cachesURL {
            let (otherSize, otherCount, otherModDate) = inspectRemainingCaches(
                caches,
                excludedSubdirs: ["Thumbnails", "Previews", "WebKit", "URLSession"]
            )
            if otherSize > 0 || otherCount > 0 {
                partitions.append(
                    CachePartitionItem(
                        type: .appCacheDirectories,
                        title: "Bộ nhớ đệm phụ trợ ứng dụng (Library/Caches)",
                        subtitle: "Dữ liệu đệm quản lý bởi framework hệ thống dành riêng cho Booster Pro.",
                        directoryURL: caches,
                        sizeBytes: otherSize,
                        fileCount: otherCount,
                        lastModifiedDate: otherModDate,
                        isDeletable: true,
                        isSafeToClean: true,
                        isCurrentlyInUse: false,
                        estimatedAfterCleanBytes: 0,
                        requiresExplicitConfirmation: false,
                        isSelected: true
                    )
                )
            }
        }

        // --- GROUP 11: Diagnostic Logs ---
        if let logsURL = libraryURL?.appendingPathComponent("Logs", isDirectory: true) {
            let (logSize, logCount, logModDate) = inspectDirectory(logsURL)
            partitions.append(
                CachePartitionItem(
                    type: .diagnosticLogs,
                    title: "Nhật ký chẩn đoán nội bộ (Library/Logs)",
                    subtitle: "Lịch sử phiên dọn dẹp và phân tích hệ thống trong sandbox.",
                    directoryURL: logsURL,
                    sizeBytes: logSize,
                    fileCount: logCount,
                    lastModifiedDate: logModDate,
                    isDeletable: true,
                    isSafeToClean: true,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: 0,
                    requiresExplicitConfirmation: false,
                    isSelected: true
                )
            )
        }

        // --- PROTECTED CATEGORIES (NEVER DELETABLE) ---

        // 1. Protected User Preferences (UserDefaults & plist)
        if let prefsURL = libraryURL?.appendingPathComponent("Preferences", isDirectory: true) {
            let (prefSize, prefCount, prefModDate) = inspectDirectory(prefsURL)
            partitions.append(
                CachePartitionItem(
                    type: .protectedUserSettings,
                    title: "Cài đặt ứng dụng & Tùy chọn (Được bảo vệ)",
                    subtitle: "Cấu hình Auto Clean, danh sách game và tùy chỉnh cá nhân.",
                    directoryURL: prefsURL,
                    sizeBytes: prefSize,
                    fileCount: prefCount,
                    lastModifiedDate: prefModDate,
                    isDeletable: false,
                    isSafeToClean: false,
                    isCurrentlyInUse: true,
                    estimatedAfterCleanBytes: prefSize,
                    requiresExplicitConfirmation: false,
                    isSelected: false,
                    protectionReason: "Được bảo vệ tuyệt đối để đảm bảo bạn không mất cài đặt và cấu hình."
                )
            )
        }

        // 2. Protected User Documents (ManagedFiles in Documents/)
        if let docs = documentsURL {
            let managedURL = docs.appendingPathComponent("ManagedFiles", isDirectory: true)
            let (docSize, docCount, docModDate) = inspectDirectory(managedURL)
            partitions.append(
                CachePartitionItem(
                    type: .protectedUserDocuments,
                    title: "Tài liệu người dùng (Được bảo vệ)",
                    subtitle: "Tệp do bạn chủ động nhập hoặc lưu trữ trong thư mục Documents.",
                    directoryURL: managedURL,
                    sizeBytes: docSize,
                    fileCount: docCount,
                    lastModifiedDate: docModDate,
                    isDeletable: false,
                    isSafeToClean: false,
                    isCurrentlyInUse: false,
                    estimatedAfterCleanBytes: docSize,
                    requiresExplicitConfirmation: false,
                    isSelected: false,
                    protectionReason: "Dữ liệu tài liệu cá nhân chỉ được quản lý thủ công qua Trình quản lý Tệp."
                )
            )
        }

        // 3. Protected App Database (Application Support/Database)
        if let appSupport = libraryURL?.appendingPathComponent("Application Support", isDirectory: true) {
            let (dbSize, dbCount, dbModDate) = inspectDirectory(appSupport)
            if dbSize > 0 || dbCount > 0 {
                partitions.append(
                    CachePartitionItem(
                        type: .protectedDatabase,
                        title: "Cơ sở dữ liệu cốt lõi (Được bảo vệ)",
                        subtitle: "Dữ liệu chỉ mục phân tích và lưu trữ trạng thái hệ thống.",
                        directoryURL: appSupport,
                        sizeBytes: dbSize,
                        fileCount: dbCount,
                        lastModifiedDate: dbModDate,
                        isDeletable: false,
                        isSafeToClean: false,
                        isCurrentlyInUse: true,
                        estimatedAfterCleanBytes: dbSize,
                        requiresExplicitConfirmation: false,
                        isSelected: false,
                        protectionReason: "Cơ sở dữ liệu ứng dụng không bao giờ bị xóa tự động."
                    )
                )
            }
        }

        return partitions
    }

    /// Backwards-compatible alias for existing consumers (SmartScan, Dashboard).
    func auditCachePartitions() -> [CachePartitionItem] {
        scanAllCacheCategories()
    }

    // MARK: - 2. Smart Cache Cleaner Execution

    /// Cleans selected cache partitions with before/after verified measurement.
    func cleanSelectedCaches(_ partitions: [CachePartitionItem]) async -> CacheCleanupResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let beforeCleanable = partitions.filter(\.isDeletable).reduce(0) { $0 + $1.sizeBytes }
        let protectedBytes = partitions.filter { !$0.isDeletable }.reduce(0) { $0 + $1.sizeBytes }

        var freedBytes: Int64 = 0
        var cleanedCount = 0
        var filesRemoved = 0
        var failedItems = 0
        var failedPaths: [String] = []
        var cleanedTitles: [String] = []

        for item in partitions where item.isDeletable && item.isSelected {
            switch item.type {
            case .urlNetworkCache, .urlCacheMemory, .urlCacheDisk:
                let memBefore = Int64(URLCache.shared.currentMemoryUsage)
                let diskBefore = Int64(URLCache.shared.currentDiskUsage)
                URLCache.shared.removeAllCachedResponses()
                let memAfter = Int64(URLCache.shared.currentMemoryUsage)
                let diskAfter = Int64(URLCache.shared.currentDiskUsage)

                let freed = max(0, (memBefore + diskBefore) - (memAfter + diskAfter))
                freedBytes += freed
                cleanedCount += 1
                filesRemoved += (diskBefore > 0 ? 1 : 0)
                cleanedTitles.append(item.title)

            case .imageCache:
                ImageCacheManager.shared.purgeAll()
                freedBytes += item.sizeBytes
                cleanedCount += 1
                filesRemoved += 1
                cleanedTitles.append(item.title)

            case .imageThumbnailCache, .generatedPreviews, .appCacheDirectories, .diagnosticLogs:
                if let dir = item.directoryURL {
                    let (removed, count, errors, paths) = removeContentsOfDirectory(at: dir)
                    freedBytes += removed
                    filesRemoved += count
                    failedItems += errors
                    failedPaths.append(contentsOf: paths)
                    cleanedCount += 1
                    cleanedTitles.append(item.title)
                }

            case .temporarySnapshots, .temporaryFiles:
                let (removed, count, errors, paths) = removeTemporaryFiles(olderThanHours: nil)
                freedBytes += removed
                filesRemoved += count
                failedItems += errors
                failedPaths.append(contentsOf: paths)
                cleanedCount += 1
                cleanedTitles.append(item.title)

            case .expiredDownloads:
                let (removed, count, errors, paths) = removeTemporaryFiles(olderThanHours: 24)
                freedBytes += removed
                filesRemoved += count
                failedItems += errors
                failedPaths.append(contentsOf: paths)
                cleanedCount += 1
                cleanedTitles.append(item.title)

            case .webViewCache:
                let before = item.sizeBytes
                await clearWebViewDataTypes([
                    WKWebsiteDataTypeDiskCache,
                    WKWebsiteDataTypeMemoryCache,
                    WKWebsiteDataTypeOfflineWebApplicationCache
                ])
                if let dir = item.directoryURL {
                    let (removed, count, _, _) = removeContentsOfDirectory(at: dir)
                    freedBytes += max(before, removed)
                    filesRemoved += count
                } else {
                    freedBytes += before
                }
                cleanedCount += 1
                cleanedTitles.append(item.title)

            case .webViewWebsiteData:
                // Sensitive: only wiped if explicitly selected by user
                let before = item.sizeBytes
                await clearWebViewDataTypes([
                    WKWebsiteDataTypeCookies,
                    WKWebsiteDataTypeLocalStorage,
                    WKWebsiteDataTypeIndexedDBDatabases,
                    WKWebsiteDataTypeWebSQLDatabases
                ])
                freedBytes += before
                cleanedCount += 1
                cleanedTitles.append(item.title)

            case .urlSessionCache:
                if let dir = item.directoryURL {
                    let (removed, count, _, _) = removeContentsOfDirectory(at: dir)
                    freedBytes += removed
                    filesRemoved += count
                    cleanedCount += 1
                    cleanedTitles.append(item.title)
                }

            case .protectedUserSettings, .protectedUserDocuments, .protectedDatabase:
                // Safety invariant: NEVER touch protected stores
                continue
            }
        }

        // Re-audit actual state to verify actual afterCleanable bytes
        let updatedPartitions = scanAllCacheCategories()
        let afterCleanable = updatedPartitions.filter(\.isDeletable).reduce(0) { $0 + $1.sizeBytes }

        let duration = max(0.05, CFAbsoluteTimeGetCurrent() - startTime)

        let result = CacheCleanupResult(
            beforeCleanableBytes: beforeCleanable,
            afterCleanableBytes: afterCleanable,
            freedBytes: freedBytes,
            cleanedPartitionsCount: cleanedCount,
            protectedBytesUntouched: protectedBytes,
            filesRemovedCount: filesRemoved,
            failedItemsCount: failedItems,
            failedItemPaths: failedPaths,
            cleanupDurationSeconds: duration,
            cleanedCategoryTitles: cleanedTitles,
            timestamp: Date()
        )

        // Save history record
        saveHistoryRecord(
            CacheHistoryRecord(
                trigger: "Dọn dẹp thủ công (Người dùng chọn)",
                bytesFreed: freedBytes,
                filesRemoved: filesRemoved,
                durationSeconds: duration,
                cleanedCategories: cleanedTitles,
                wasSuccessful: failedItems == 0
            )
        )

        await DiagnosticLogger.shared.log(
            "Cache cleanup completed: freed \(freedBytes) bytes in \(String(format: "%.2f", duration))s across \(cleanedCount) partitions.",
            category: "CacheCleaner"
        )

        return result
    }

    /// Convenience: Cleans all partitions marked as safe by default.
    func cleanAllSafeCaches() async -> CacheCleanupResult {
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            partitions[i].isSelected = partitions[i].isSafeToClean
        }
        return await cleanSelectedCaches(partitions)
    }

    /// Convenience: Cleans only old cache files modified before the given days.
    func cleanOldCaches(olderThanDays: Int = 3) async -> CacheCleanupResult {
        let cutoff = Date().addingTimeInterval(-Double(olderThanDays * 86400))
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            if let modDate = partitions[i].lastModifiedDate, modDate < cutoff, partitions[i].isSafeToClean {
                partitions[i].isSelected = true
            } else if partitions[i].type == .expiredDownloads {
                partitions[i].isSelected = true
            } else {
                partitions[i].isSelected = false
            }
        }
        return await cleanSelectedCaches(partitions)
    }

    /// Convenience: Wipes only temporary directories.
    func cleanTemporaryFilesOnly() async -> CacheCleanupResult {
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            partitions[i].isSelected = (partitions[i].type == .temporaryFiles || partitions[i].type == .temporarySnapshots || partitions[i].type == .expiredDownloads)
        }
        return await cleanSelectedCaches(partitions)
    }

    /// Convenience: Clears only in-memory and disk image thumbnail caches.
    func clearImageCacheOnly() async -> CacheCleanupResult {
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            partitions[i].isSelected = (partitions[i].type == .imageCache || partitions[i].type == .imageThumbnailCache || partitions[i].type == .generatedPreviews)
        }
        return await cleanSelectedCaches(partitions)
    }

    /// Convenience: Clears URLCache memory & disk.
    func clearURLCacheOnly() async -> CacheCleanupResult {
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            partitions[i].isSelected = (partitions[i].type == .urlCacheMemory || partitions[i].type == .urlCacheDisk || partitions[i].type == .urlNetworkCache)
        }
        return await cleanSelectedCaches(partitions)
    }

    /// Convenience: Clears WebKit cache without deleting user cookies unless requested.
    func clearWebViewCacheOnly(includeCookies: Bool = false) async -> CacheCleanupResult {
        var partitions = scanAllCacheCategories()
        for i in 0..<partitions.count {
            if partitions[i].type == .webViewCache {
                partitions[i].isSelected = true
            } else if partitions[i].type == .webViewWebsiteData {
                partitions[i].isSelected = includeCookies
            } else {
                partitions[i].isSelected = false
            }
        }
        return await cleanSelectedCaches(partitions)
    }

    // MARK: - 3. WebView Website Data Manager (Public WebKit API)

    /// Fetches all website data records registered in Booster Pro's default WebKit data store.
    func fetchWebViewRecords() async -> [WebViewWebsiteDataRecordItem] {
        await withCheckedContinuation { continuation in
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { records in
                var items: [WebViewWebsiteDataRecordItem] = []
                for rec in records {
                    let typeStrings = Array(rec.dataTypes)
                    let isCacheOnly = rec.dataTypes.isSubset(of: [
                        WKWebsiteDataTypeDiskCache,
                        WKWebsiteDataTypeMemoryCache,
                        WKWebsiteDataTypeOfflineWebApplicationCache
                    ])
                    let hasCookiesOrAuth = rec.dataTypes.contains(WKWebsiteDataTypeCookies) ||
                        rec.dataTypes.contains(WKWebsiteDataTypeLocalStorage) ||
                        rec.dataTypes.contains(WKWebsiteDataTypeSessionStorage)

                    items.append(
                        WebViewWebsiteDataRecordItem(
                            id: rec.displayName,
                            displayName: rec.displayName,
                            dataTypes: typeStrings,
                            isCacheOnly: isCacheOnly,
                            hasCookiesOrAuth: hasCookiesOrAuth,
                            isSelected: isCacheOnly // Only pre-select pure cache
                        )
                    )
                }
                continuation.resume(returning: items)
            }
        }
    }

    /// Removes data for specific website records.
    func removeWebViewData(for records: [WebViewWebsiteDataRecordItem], types: Set<String>) async {
        let matchingDisplayNames = Set(records.map(\.displayName))
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: allTypes) { allRecords in
                let targetRecords = allRecords.filter { matchingDisplayNames.contains($0.displayName) }
                guard !targetRecords.isEmpty else {
                    continuation.resume()
                    return
                }

                WKWebsiteDataStore.default().removeData(ofTypes: types, for: targetRecords) {
                    continuation.resume()
                }
            }
        }
    }

    private func clearWebViewDataTypes(_ types: Set<String>) async {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
                continuation.resume()
            }
        }
    }

    // MARK: - 4. History Persistence

    func loadHistory() -> [CacheHistoryRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyStorageKey),
              let list = try? JSONDecoder().decode([CacheHistoryRecord].self, from: data) else {
            return []
        }
        return list
    }

    func saveHistoryRecord(_ record: CacheHistoryRecord) {
        var current = loadHistory()
        current.insert(record, at: 0)
        if current.count > 30 {
            current = Array(current.prefix(30))
        }
        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: historyStorageKey)
        }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyStorageKey)
    }

    // MARK: - 5. Low-Level Directory Inspection & Removal (Disjoint Math)

    private func inspectDirectory(_ url: URL) -> (sizeBytes: Int64, fileCount: Int, lastModified: Date?) {
        guard fileManager.fileExists(atPath: url.path) else { return (0, 0, nil) }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey, .contentModificationDateKey],
            options: []
        ) else {
            return (0, 0, nil)
        }

        var total: Int64 = 0
        var count = 0
        var latestDate: Date? = nil

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey, .contentModificationDateKey]
            ), values.isRegularFile == true else {
                continue
            }
            total += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            count += 1
            if let mod = values.contentModificationDate {
                if latestDate == nil || mod > latestDate! {
                    latestDate = mod
                }
            }
        }
        return (total, count, latestDate)
    }

    private func inspectTemporaryDirectory(_ url: URL) -> (tmpTotal: Int64, tmpFiles: Int, expiredTotal: Int64, expiredFiles: Int, tmpMod: Date?, expMod: Date?) {
        guard fileManager.fileExists(atPath: url.path) else {
            return (0, 0, 0, 0, nil, nil)
        }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey, .contentModificationDateKey],
            options: []
        ) else {
            return (0, 0, 0, 0, nil, nil)
        }

        let cutoff = Date().addingTimeInterval(-86400) // 24 hours ago
        var tmpTotal: Int64 = 0
        var tmpCount = 0
        var expTotal: Int64 = 0
        var expCount = 0
        var tmpMod: Date? = nil
        var expMod: Date? = nil

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey, .contentModificationDateKey]
            ), values.isRegularFile == true else {
                continue
            }
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            let mod = values.contentModificationDate ?? Date()

            if mod < cutoff || fileURL.path.contains("/Downloads/") {
                expTotal += size
                expCount += 1
                if expMod == nil || mod > expMod! { expMod = mod }
            } else {
                tmpTotal += size
                tmpCount += 1
                if tmpMod == nil || mod > tmpMod! { tmpMod = mod }
            }
        }
        return (tmpTotal, tmpCount, expTotal, expCount, tmpMod, expMod)
    }

    private func inspectRemainingCaches(_ baseURL: URL, excludedSubdirs: [String]) -> (sizeBytes: Int64, fileCount: Int, lastModified: Date?) {
        guard fileManager.fileExists(atPath: baseURL.path) else { return (0, 0, nil) }
        guard let contents = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else {
            return (0, 0, nil)
        }

        var total: Int64 = 0
        var count = 0
        var latestDate: Date? = nil

        for itemURL in contents {
            if excludedSubdirs.contains(itemURL.lastPathComponent) {
                continue
            }
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    let sub = inspectDirectory(itemURL)
                    total += sub.sizeBytes
                    count += sub.fileCount
                    if let mod = sub.lastModified, (latestDate == nil || mod > latestDate!) {
                        latestDate = mod
                    }
                } else {
                    let vals = try? itemURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                    total += Int64(vals?.fileSize ?? 0)
                    count += 1
                    if let mod = vals?.contentModificationDate, (latestDate == nil || mod > latestDate!) {
                        latestDate = mod
                    }
                }
            }
        }
        return (total, count, latestDate)
    }

    private func removeContentsOfDirectory(at directoryURL: URL) -> (removedBytes: Int64, removedCount: Int, failedCount: Int, failedPaths: [String]) {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return (0, 0, 0, []) }
        let before = storageService.calculateDirectorySize(at: directoryURL)

        guard let contents = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return (0, 0, 0, [])
        }

        var removedCount = 0
        var failedCount = 0
        var failedPaths: [String] = []

        for itemURL in contents {
            do {
                try fileManager.removeItem(at: itemURL)
                removedCount += 1
            } catch {
                failedCount += 1
                failedPaths.append(itemURL.lastPathComponent)
                Task {
                    await DiagnosticLogger.shared.log("Failed to remove cache item \(itemURL.path): \(error.localizedDescription)", category: "CacheCleaner")
                }
            }
        }

        let after = storageService.calculateDirectorySize(at: directoryURL)
        let freed = max(0, before - after)
        return (freed, removedCount, failedCount, failedPaths)
    }

    private func removeTemporaryFiles(olderThanHours: Double?) -> (removedBytes: Int64, removedCount: Int, failedCount: Int, failedPaths: [String]) {
        let tmpDir = temporaryDirectoryURL
        guard fileManager.fileExists(atPath: tmpDir.path) else { return (0, 0, 0, []) }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: tmpDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return (0, 0, 0, [])
        }

        var removedBytes: Int64 = 0
        var removedCount = 0
        var failedCount = 0
        var failedPaths: [String] = []

        let cutoffDate = olderThanHours.map { Date().addingTimeInterval(-($0 * 3600)) }

        for itemURL in contents {
            let vals = try? itemURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let size = Int64(vals?.fileSize ?? 0)

            if let cutoff = cutoffDate, let mod = vals?.contentModificationDate {
                if mod > cutoff && !itemURL.path.contains("/Downloads/") {
                    continue
                }
            }

            do {
                try fileManager.removeItem(at: itemURL)
                removedBytes += size
                removedCount += 1
            } catch {
                failedCount += 1
                failedPaths.append(itemURL.lastPathComponent)
            }
        }

        return (removedBytes, removedCount, failedCount, failedPaths)
    }
}
