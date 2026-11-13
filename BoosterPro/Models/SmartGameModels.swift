import Foundation
import SwiftUI

// MARK: - Version Comparator Utility
/// Safely compares semantic versions (e.g., "1.54.2" vs "1.55.0") using integer components.
enum VersionComparator {
    static func isNewer(storeVersion: String, installedVersion: String) -> Bool {
        let storeComponents = parse(storeVersion)
        let installedComponents = parse(installedVersion)

        let maxCount = max(storeComponents.count, installedComponents.count)
        for i in 0..<maxCount {
            let s = i < storeComponents.count ? storeComponents[i] : 0
            let cur = i < installedComponents.count ? installedComponents[i] : 0
            if s > cur { return true }
            if s < cur { return false }
        }
        return false
    }

    private static func parse(_ version: String) -> [Int] {
        let clean = version.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-").first.map(String.init) ?? version
        return clean.split(separator: ".")
            .compactMap { Int($0.filter { $0.isNumber }) }
    }
}

// MARK: - Smart Game Model
/// Full entity representing a game managed by the Smart Game Manager.
struct SmartGameModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bundleId: String
    var appStoreId: String
    var urlScheme: String?
    var category: GameCategory
    var installedVersion: String
    var latestStoreVersion: String?
    var appStoreUrl: String?
    var iconUrl: String?
    var iconSymbol: String
    var colorHex: String
    var fileSizeBytes: Int64?
    var releaseNotes: String?
    var isInstalled: Bool
    var lastCheckedDate: Date?
    var lastPlayedDate: Date?
    var playCount: Int
    var customNotes: String?

    init(
        id: UUID = UUID(),
        name: String,
        bundleId: String,
        appStoreId: String,
        urlScheme: String? = nil,
        category: GameCategory = .moba,
        installedVersion: String = "1.0.0",
        latestStoreVersion: String? = nil,
        appStoreUrl: String? = nil,
        iconUrl: String? = nil,
        iconSymbol: String = "gamecontroller.fill",
        colorHex: String = "#00F5A0",
        fileSizeBytes: Int64? = nil,
        releaseNotes: String? = nil,
        isInstalled: Bool = true,
        lastCheckedDate: Date? = nil,
        lastPlayedDate: Date? = nil,
        playCount: Int = 0,
        customNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.appStoreId = appStoreId
        self.urlScheme = urlScheme
        self.category = category
        self.installedVersion = installedVersion
        self.latestStoreVersion = latestStoreVersion
        self.appStoreUrl = appStoreUrl
        self.iconUrl = iconUrl
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.fileSizeBytes = fileSizeBytes
        self.releaseNotes = releaseNotes
        self.isInstalled = isInstalled
        self.lastCheckedDate = lastCheckedDate
        self.lastPlayedDate = lastPlayedDate
        self.playCount = playCount
        self.customNotes = customNotes
    }

    /// True if App Store reports a newer version than current installed version.
    var hasUpdateAvailable: Bool {
        guard let latest = latestStoreVersion, !latest.isEmpty else { return false }
        return VersionComparator.isNewer(storeVersion: latest, installedVersion: installedVersion)
    }

    var formattedSize: String {
        guard let bytes = fileSizeBytes, bytes > 0 else { return "N/A" }
        return ByteFormatterUtil.formatFileSize(bytes)
    }
}

// MARK: - App Store iTunes Search API Models
/// Apple Public iTunes Search/Lookup response root.
struct AppStoreLookupResponse: Codable {
    let resultCount: Int
    let results: [AppStoreLookupItem]
}

struct AppStoreLookupItem: Codable, Identifiable, Hashable {
    var id: Int { trackId }
    let trackId: Int
    let trackName: String
    let bundleId: String?
    let version: String
    let artworkUrl100: String?
    let artworkUrl512: String?
    let trackViewUrl: String?
    let fileSizeBytes: String?
    let releaseNotes: String?
    let primaryGenreName: String?
    let sellerName: String?
    let currentVersionReleaseDate: String?

    var parsedFileSizeBytes: Int64? {
        guard let s = fileSizeBytes else { return nil }
        return Int64(s)
    }
}

// MARK: - Smart Automation Settings
struct SmartGameAutomationSettings: Codable, Equatable {
    var autoDetectGames: Bool
    var autoCheckUpdates: Bool
    var autoOptimizeBeforePlay: Bool
    var autoCleanAfterGaming: Bool
    var gamingFocusRecommendations: Bool
    var updateNotifications: Bool

    static let `default` = SmartGameAutomationSettings(
        autoDetectGames: true,
        autoCheckUpdates: true,
        autoOptimizeBeforePlay: true,
        autoCleanAfterGaming: true,
        gamingFocusRecommendations: true,
        updateNotifications: true
    )
}

// MARK: - Preset Popular Games Catalog
struct GamePresetCatalog {
    static let presets: [SmartGameModel] = [
        SmartGameModel(
            name: "Liên Quân Mobile",
            bundleId: "com.garena.game.kgvn",
            appStoreId: "1150288114",
            urlScheme: "aov://",
            category: .moba,
            installedVersion: "1.54.1",
            iconSymbol: "shield.lefthalf.filled",
            colorHex: "#00F5A0"
        ),
        SmartGameModel(
            name: "PUBG Mobile VN",
            bundleId: "com.vng.pubgmobile",
            appStoreId: "1438396636",
            urlScheme: "pubgmobile://",
            category: .battleRoyale,
            installedVersion: "3.2.0",
            iconSymbol: "cross.vial.fill",
            colorHex: "#FF9500"
        ),
        SmartGameModel(
            name: "Tốc Chiến (Wild Rift)",
            bundleId: "com.riotgames.league.wildrift",
            appStoreId: "1480644895",
            urlScheme: "wildrift://",
            category: .moba,
            installedVersion: "5.1.0",
            iconSymbol: "bolt.shield.fill",
            colorHex: "#00D9F5"
        ),
        SmartGameModel(
            name: "Garena Free Fire",
            bundleId: "com.dts.freefireth",
            appStoreId: "1300146617",
            urlScheme: "freefire://",
            category: .battleRoyale,
            installedVersion: "1.104.1",
            iconSymbol: "flame.fill",
            colorHex: "#FF3B30"
        ),
        SmartGameModel(
            name: "Genshin Impact",
            bundleId: "com.miHoYo.GenshinImpact",
            appStoreId: "1517783697",
            urlScheme: "genshinimpact://",
            category: .rpg,
            installedVersion: "4.7.0",
            iconSymbol: "wand.and.stars",
            colorHex: "#AF52DE"
        ),
        SmartGameModel(
            name: "Roblox",
            bundleId: "com.roblox.robloxmobile",
            appStoreId: "431946152",
            urlScheme: "roblox://",
            category: .casual,
            installedVersion: "2.628.530",
            iconSymbol: "cube.fill",
            colorHex: "#E02424"
        ),
        SmartGameModel(
            name: "Call of Duty: Mobile VN",
            bundleId: "com.vng.codmvn",
            appStoreId: "1485660509",
            urlScheme: "codm://",
            category: .fps,
            installedVersion: "1.0.44",
            iconSymbol: "scope",
            colorHex: "#30D158"
        ),
        SmartGameModel(
            name: "Honkai: Star Rail",
            bundleId: "com.HoYoverse.hkrpgoversea",
            appStoreId: "1588196778",
            urlScheme: "honkaistarrail://",
            category: .rpg,
            installedVersion: "2.2.0",
            iconSymbol: "sparkles",
            colorHex: "#5E5CE6"
        ),
        SmartGameModel(
            name: "FC Mobile VN",
            bundleId: "com.ea.gp.fifamobile",
            appStoreId: "1094930513",
            urlScheme: "fifamobile://",
            category: .strategy,
            installedVersion: "21.0.04",
            iconSymbol: "sportscourt.fill",
            colorHex: "#32ADE6"
        ),
        SmartGameModel(
            name: "Play Together VNG",
            bundleId: "com.vng.playtogether",
            appStoreId: "1618776882",
            urlScheme: "playtogether://",
            category: .casual,
            installedVersion: "1.74.0",
            iconSymbol: "person.3.fill",
            colorHex: "#FFD60A"
        )
    ]
}
