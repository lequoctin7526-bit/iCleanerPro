import Foundation
import SwiftUI
import Combine

public enum GameFilter: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case updateAvailable = "Có bản cập nhật"
    case installed = "Đã cài đặt"

    public var id: String { rawValue }
}

public enum GameSortOption: String, CaseIterable, Identifiable {
    case recent = "Gần đây nhất"
    case name = "Tên (A-Z)"
    case version = "Phiên bản"
    case playCount = "Chơi nhiều nhất"

    public var id: String { rawValue }
}

@MainActor
public final class SmartGameManagerViewModel: ObservableObject {
    @Published public var games: [SmartGameModel] = []
    @Published public var searchText: String = ""
    @Published public var selectedFilter: GameFilter = .all
    @Published public var selectedSort: GameSortOption = .recent

    @Published public var isLoading: Bool = false
    @Published public var isCheckingUpdates: Bool = false
    @Published public var statusMessage: String = ""

    // Sheets & modals
    @Published public var showAddGameSheet: Bool = false
    @Published public var showSettingsSheet: Bool = false
    @Published public var showOptimizationModal: Bool = false
    @Published public var showPostCleanSummary: Bool = false
    @Published public var showManualLaunchGuidance: Bool = false
    @Published public var selectedGameForGuidance: SmartGameModel? = nil

    // Active optimization state
    @Published public var activeOptimizingGame: SmartGameModel? = nil
    @Published public var optimizationProgressStep: Int = 0 // 0: Check, 1: Clean, 2: Done
    @Published public var lastOptimizationSnapshot: GameOptimizationSnapshot? = nil

    // Active gaming session state
    @Published public var activeSessionGame: SmartGameModel? = nil
    @Published public var sessionElapsedSeconds: TimeInterval = 0
    @Published public var lastCleanedSession: GameSessionRecord? = nil

    @Published public var automationSettings: SmartGameAutomationSettings = .default

    private let service = SmartGameManagerService.shared
    private var sessionTimer: AnyCancellable?
    private var sessionStartDate: Date?

    public init() {
        loadSettings()
        loadLibrary()
    }

    // MARK: - Computed Properties
    public var filteredGames: [SmartGameModel] {
        var list = games

        // Filter by category / status
        switch selectedFilter {
        case .all:
            break
        case .updateAvailable:
            list = list.filter { $0.hasUpdateAvailable }
        case .installed:
            list = list.filter { $0.isInstalled }
        }

        // Filter by search text
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(query) ||
                $0.bundleId.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        // Sort
        switch selectedSort {
        case .recent:
            list.sort { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .version:
            list.sort { $0.installedVersion > $1.installedVersion }
        case .playCount:
            list.sort { $0.playCount > $1.playCount }
        }

        return list
    }

    public var updatesCount: Int {
        games.filter { $0.hasUpdateAvailable }.count
    }

    public var installedCount: Int {
        games.filter { $0.isInstalled }.count
    }

    public var isSessionActive: Bool {
        activeSessionGame != nil
    }

    public var formattedSessionDuration: String {
        let mins = Int(sessionElapsedSeconds) / 60
        let secs = Int(sessionElapsedSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Library Loading & Update Check
    public func loadSettings() {
        automationSettings = service.loadSettings()
    }

    public func saveSettings(_ settings: SmartGameAutomationSettings) {
        automationSettings = settings
        service.saveSettings(settings)
    }

    public func loadLibrary() {
        isLoading = true
        var loaded = service.loadGames()

        // Auto-detect installed status via canOpenURL
        if automationSettings.autoDetectGames {
            for i in 0..<loaded.count {
                loaded[i].isInstalled = service.isGameInstalled(loaded[i])
            }
            service.saveGames(loaded)
        }

        games = loaded
        isLoading = false

        if automationSettings.autoCheckUpdates {
            Task {
                await checkAllUpdates()
            }
        }
    }

    public func checkAllUpdates() async {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        statusMessage = "Đang kiểm tra App Store..."

        let updated = await service.checkUpdates(for: games)
        games = updated

        isCheckingUpdates = false
        statusMessage = updatesCount > 0 ? "Phát hiện \(updatesCount) bản cập nhật!" : "Tất cả game đã ở bản mới nhất"
    }

    // MARK: - Launch & Play Flow
    public func playGame(_ game: SmartGameModel) {
        if automationSettings.autoOptimizeBeforePlay {
            activeOptimizingGame = game
            optimizationProgressStep = 0
            showOptimizationModal = true

            Task {
                // Step 1: Device inspection
                try? await Task.sleep(nanoseconds: 400_000_000)
                optimizationProgressStep = 1

                // Step 2: Auto clean iCleaner Pro memory & cache
                let snapshot = await service.executePreGameOptimization(for: game)
                lastOptimizationSnapshot = snapshot
                try? await Task.sleep(nanoseconds: 400_000_000)
                optimizationProgressStep = 2

                // Brief pause on completion screen then launch
                try? await Task.sleep(nanoseconds: 500_000_000)
                showOptimizationModal = false
                proceedToLaunch(game)
            }
        } else {
            proceedToLaunch(game)
        }
    }

    private func proceedToLaunch(_ game: SmartGameModel) {
        startSession(for: game)

        service.launchGame(game) { [weak self] success in
            guard let self = self else { return }
            if !success {
                self.selectedGameForGuidance = game
                self.showManualLaunchGuidance = true
            }
        }
    }

    // MARK: - Active Gaming Session Tracking
    private func startSession(for game: SmartGameModel) {
        activeSessionGame = game
        sessionStartDate = Date()
        sessionElapsedSeconds = 0

        sessionTimer?.cancel()
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.sessionElapsedSeconds += 1
            }
    }

    public func endActiveSession() {
        guard let game = activeSessionGame else { return }
        sessionTimer?.cancel()
        sessionTimer = nil

        let duration = max(1, sessionElapsedSeconds)

        if automationSettings.autoCleanAfterGaming {
            Task {
                let (snapshot, session) = await service.executePostGameAutoClean(
                    game: game,
                    duration: duration
                )
                self.lastOptimizationSnapshot = snapshot
                self.lastCleanedSession = session
                self.showPostCleanSummary = true
                self.activeSessionGame = nil
                self.loadLibrary()
            }
        } else {
            activeSessionGame = nil
        }
    }

    // MARK: - Actions
    public func openAppStore(for game: SmartGameModel) {
        service.openAppStore(for: game)
    }

    public func addGame(_ game: SmartGameModel) {
        let updated = service.addGame(game)
        games = updated
    }

    public func deleteGame(id: UUID) {
        let updated = service.deleteGame(id: id)
        games = updated
    }

    public func updateInstalledVersion(game: SmartGameModel, newVersion: String) {
        var copy = game
        copy.installedVersion = newVersion
        let updated = service.updateGame(copy)
        games = updated
    }
}
