import SwiftUI

/// Master view for the Smart Game Manager module.
/// Provides automatic game detection, App Store update tracking, 1-tap play,
/// pre-game optimization, and auto clean after gaming.
public struct SmartGameManagerView: View {
    @StateObject private var viewModel = SmartGameManagerViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GamingTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Top HUD Metric Bar
                        topHUDBar

                        // Active Gaming Session Banner (if playing)
                        if viewModel.isSessionActive {
                            activeSessionHUDCard
                        }

                        // Search & Filter Section
                        searchAndFilterBar

                        // Games List
                        if viewModel.filteredGames.isEmpty {
                            emptyResultsView
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.filteredGames) { game in
                                    SmartGameCardView(
                                        game: game,
                                        onPlay: {
                                            viewModel.playGame(game)
                                        },
                                        onUpdate: {
                                            viewModel.openAppStore(for: game)
                                        },
                                        onOptimize: {
                                            viewModel.playGame(game)
                                        },
                                        onEditVersion: { newVer in
                                            viewModel.updateInstalledVersion(game: game, newVersion: newVer)
                                        },
                                        onDelete: {
                                            viewModel.deleteGame(id: game.id)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Smart Game Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(GamingTheme.neonCyan)
                    }
                    .accessibilityLabel("Cài đặt tự động hóa")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.checkAllUpdates() }
                    } label: {
                        if viewModel.isCheckingUpdates {
                            ProgressView().tint(GamingTheme.neonGreen)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(GamingTheme.neonGreen)
                        }
                    }
                    .accessibilityLabel("Kiểm tra bản cập nhật")

                    Button {
                        viewModel.showAddGameSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(GamingTheme.neonGreen)
                    }
                    .accessibilityLabel("Thêm game mới")
                }
            }
            .refreshable {
                await viewModel.checkAllUpdates()
            }
            .sheet(isPresented: $viewModel.showAddGameSheet) {
                AddSmartGameSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showSettingsSheet) {
                SmartGameSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showPostCleanSummary) {
                PostGameCleanSummarySheetView(
                    session: viewModel.lastCleanedSession,
                    snapshot: viewModel.lastOptimizationSnapshot
                ) {
                    viewModel.showPostCleanSummary = false
                }
            }
            .sheet(isPresented: $viewModel.showManualLaunchGuidance) {
                if let game = viewModel.selectedGameForGuidance {
                    ManualGameLaunchGuidanceSheet(
                        game: game,
                        onOpenAppStore: {
                            viewModel.openAppStore(for: game)
                        },
                        onDismiss: {
                            viewModel.showManualLaunchGuidance = false
                        }
                    )
                }
            }
            .overlay {
                if viewModel.showOptimizationModal, let game = viewModel.activeOptimizingGame {
                    PreGameOptimizationModalView(
                        game: game,
                        currentStep: viewModel.optimizationProgressStep,
                        snapshot: viewModel.lastOptimizationSnapshot
                    )
                    .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top HUD Metric Bar
    private var topHUDBar: some View {
        HStack(spacing: 10) {
            metricPill(
                title: "Tổng game",
                value: "\(viewModel.games.count)",
                icon: "gamecontroller.fill",
                tint: GamingTheme.neonGreen
            )

            metricPill(
                title: "Bản cập nhật",
                value: "\(viewModel.updatesCount)",
                icon: "arrow.triangle.2.circlepath",
                tint: viewModel.updatesCount > 0 ? GamingTheme.neonOrange : .white.opacity(0.6)
            )

            metricPill(
                title: "Đã cài",
                value: "\(viewModel.installedCount)",
                icon: "checkmark.circle.fill",
                tint: GamingTheme.neonCyan
            )
        }
    }

    private func metricPill(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(tint)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(GamingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Active Session HUD Card
    private var activeSessionHUDCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(GamingTheme.neonGreen)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(GamingTheme.neonGreen.opacity(0.5), lineWidth: 6)
                        .scaleEffect(1.4)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("ĐANG TRONG PHIÊN: \(viewModel.activeSessionGame?.name ?? "Game")")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)
                    .lineLimit(1)
                Text("Thời gian: \(viewModel.formattedSessionDuration)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                viewModel.endActiveSession()
            } label: {
                Text("KẾT THÚC & DỌN")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(GamingTheme.neonOrange)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(GamingTheme.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GamingTheme.neonGreen, lineWidth: 1)
        )
        .shadow(color: GamingTheme.neonGreen.opacity(0.2), radius: 8)
    }

    // MARK: - Search & Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(GamingTheme.neonCyan)
                TextField("Tìm game theo tên, bundle ID...", text: $viewModel.searchText)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(10)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Filter pills & sort menu
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GameFilter.allCases) { filter in
                            let isSelected = viewModel.selectedFilter == filter
                            Button {
                                viewModel.selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? GamingTheme.neonGreen : GamingTheme.cardBackground)
                                    .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()

                Menu {
                    Picker("Sắp xếp", selection: $viewModel.selectedSort) {
                        ForEach(GameSortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(GamingTheme.neonCyan)
                }
            }
        }
    }

    // MARK: - Empty Results View
    private var emptyResultsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundStyle(GamingTheme.neonGreen.opacity(0.6))

            Text("Không tìm thấy game phù hợp")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Thử đổi bộ lọc hoặc nhấn nút \"+\" ở góc trên để thêm game mới.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(GamingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
