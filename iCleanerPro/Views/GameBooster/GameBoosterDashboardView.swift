import SwiftUI

struct GameBoosterDashboardView: View {
    @StateObject private var viewModel = GameBoosterViewModel()

    @State private var showLibrarySheet = false
    @State private var showChecklistSheet = false
    @State private var showHistorySheet = false
    @State private var showActiveSessionView = false
    @State private var showSmartGameManagerSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isSessionActive {
                        activeSessionBanner
                    }

                    readinessHUDCard
                    boostNowButton
                    presetSelectorSection
                    smartGameManagerBanner
                    quickGameLauncherSection
                    gamingModeChecklistQuickCard
                    realTimeMonitorCard
                    transparencyDisclaimer
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Game Booster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistorySheet = true
                    } label: {
                        Label("Lịch sử", systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(GamingTheme.neonCyan)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSmartGameManagerSheet = true
                    } label: {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(GamingTheme.neonGreen)
                    }
                    .accessibilityLabel("Smart Game Manager")

                    Button {
                        viewModel.refreshLiveMetrics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(GamingTheme.neonGreen)
                    }
                    .accessibilityLabel("Làm mới")
                }
            }
            .sheet(isPresented: $showSmartGameManagerSheet) {
                SmartGameManagerView()
            }
            .sheet(isPresented: $showLibrarySheet) {
                GameLibraryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showChecklistSheet) {
                GamingModeChecklistView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHistorySheet) {
                GameHistoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showBoostSuccessSheet) {
                boostSuccessSheet
            }
            .sheet(isPresented: $viewModel.showSessionEndSummary) {
                sessionEndSummarySheet
            }
            .fullScreenCover(isPresented: $showActiveSessionView) {
                GameSessionActiveView(viewModel: viewModel)
            }
            .alert("Thông báo khởi động", isPresented: Binding(
                get: { viewModel.launchNotice != nil },
                set: { if !$0 { viewModel.launchNotice = nil } }
            )) {
                Button("Đã hiểu", role: .cancel) {}
            } message: {
                Text(viewModel.launchNotice ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Active Session Banner
    private var activeSessionBanner: some View {
        Button {
            showActiveSessionView = true
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(GamingTheme.neonGreen)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(GamingTheme.neonGreen.opacity(0.5), lineWidth: 6)
                            .scaleEffect(1.4)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("ĐANG TRONG TRẬN: \(viewModel.activeGame?.name ?? "Game")")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(GamingTheme.neonGreen)
                    Text("Thời gian: \(viewModel.sessionDurationFormatted) • Chạm để mở HUD")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(GamingTheme.neonGreen)
            }
            .padding(14)
            .background(GamingTheme.neonGreen.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(GamingTheme.neonGreen.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Device Readiness HUD Card
    private var readinessHUDCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                NeonGaugeView(
                    score: viewModel.readinessReport.score,
                    level: viewModel.readinessReport.level,
                    isPulsing: viewModel.isOptimizing
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("TRẠNG THÁI THIẾT BỊ")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GamingTheme.neonCyan)

                    Text(viewModel.readinessReport.summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider().background(Color.white.opacity(0.15))

                    HStack(spacing: 12) {
                        hudMetric(
                            title: "Nhiệt độ",
                            value: viewModel.readinessReport.thermalTitle,
                            color: thermalColor
                        )
                        hudMetric(
                            title: "Pin / Chế độ",
                            value: "\(viewModel.batteryLevelPercent)% \(viewModel.isLowPowerMode ? "(Low Power)" : "")",
                            color: viewModel.isLowPowerMode ? GamingTheme.neonOrange : GamingTheme.neonGreen
                        )
                    }
                }
            }
        }
        .gamingCard(glowColor: readinessGlowColor, cornerRadius: 22, padding: 18)
    }

    private var readinessGlowColor: Color {
        switch viewModel.readinessReport.level {
        case .optimal: return GamingTheme.neonGreen
        case .moderate: return GamingTheme.neonOrange
        case .needsOptimization: return GamingTheme.neonRed
        }
    }

    private var thermalColor: Color {
        switch viewModel.readinessReport.thermalState {
        case .nominal: return GamingTheme.neonGreen
        case .fair: return GamingTheme.neonOrange
        case .serious, .critical: return GamingTheme.neonRed
        @unknown default: return GamingTheme.neonCyan
        }
    }

    private func hudMetric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    // MARK: - BOOST NOW Button
    private var boostNowButton: some View {
        Button {
            Task { await viewModel.performBoostNow() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [GamingTheme.neonGreen, GamingTheme.neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: GamingTheme.neonGreen.opacity(0.4), radius: 14, x: 0, y: 6)

                HStack(spacing: 12) {
                    if viewModel.isOptimizing {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.black)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.isOptimizing ? "ĐANG TỐI ƯU..." : "BOOST NOW")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                        Text(viewModel.isOptimizing ? viewModel.optimizationStepMessage : "Giải phóng bộ nhớ đệm nội bộ & chuẩn bị chiến game")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.black.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "chevron.right.2")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.black.opacity(0.65))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isOptimizing)
    }

    // MARK: - Gaming Presets Section
    private var presetSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CẤU HÌNH GAMING PRESET")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonPurple)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GamePresetMode.allCases) { preset in
                        let isSelected = viewModel.selectedPreset == preset
                        Button {
                            viewModel.selectedPreset = preset
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: preset.iconName)
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? .black : GamingTheme.neonCyan)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.black)
                                    }
                                }

                                Text(preset.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(isSelected ? .black : .white)

                                Text(preset.tagline)
                                    .font(.caption2)
                                    .foregroundStyle(isSelected ? .black.opacity(0.8) : .white.opacity(0.6))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 170, height: 110, alignment: .topLeading)
                            .padding(12)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(GamingTheme.neonGradient)
                                    : AnyShapeStyle(GamingTheme.cardBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        isSelected ? GamingTheme.neonGreen : GamingTheme.cardBorder,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Smart Game Manager Banner
    private var smartGameManagerBanner: some View {
        Button {
            showSmartGameManagerSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(GamingTheme.neonGreen.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: "cpu.fill")
                        .font(.title2)
                        .foregroundStyle(GamingTheme.neonGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("SMART GAME MANAGER")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("AUTO")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(GamingTheme.neonCyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(GamingTheme.neonCyan.opacity(0.18))
                            .clipShape(Capsule())
                    }

                    Text("Tự nhận diện, Update Checker & Auto Clean sau trận")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(GamingTheme.neonGreen)
            }
            .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.2), cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Game Launcher Carousel
    private var quickGameLauncherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("THƯ VIỆN GAME")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)
                Spacer()
                Button {
                    showSmartGameManagerSheet = true
                } label: {
                    Text("Smart Manager (\(viewModel.games.count)) >")
                        .font(.caption.bold())
                        .foregroundStyle(GamingTheme.neonCyan)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.games.prefix(6)) { game in
                        Button {
                            viewModel.launchGame(game)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(GamingTheme.cardBackgroundAlt)
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(GamingTheme.colorForHex(game.colorHex).opacity(0.6), lineWidth: 1.5)
                                        )

                                    Image(systemName: game.iconSymbol)
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(GamingTheme.colorForHex(game.colorHex))
                                }

                                Text(game.name)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .frame(width: 72)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.15), cornerRadius: 20, padding: 14)
    }

    // MARK: - Pre-Game Checklist Quick Card
    private var gamingModeChecklistQuickCard: some View {
        Button {
            showChecklistSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "checklist.checked")
                    .font(.title2)
                    .foregroundStyle(GamingTheme.neonOrange)
                    .frame(width: 44, height: 44)
                    .background(GamingTheme.neonOrange.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    let completed = viewModel.checklistItems.filter(\.isCompleted).count
                    Text("Checklist chuẩn bị trước trận")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(completed)/\(viewModel.checklistItems.count) mục hoàn thành (Focus Mode, Low Power, v.v.)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
            }
            .gamingCard(glowColor: GamingTheme.neonOrange.opacity(0.18), cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Real-Time Performance Monitor
    private var realTimeMonitorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BẢNG THEO DÕI THỰC TẾ (APPLE PUBLIC API)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonCyan)
                Spacer()
                Text("Live")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(GamingTheme.neonGreen.opacity(0.15))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                monitorBox(
                    label: "RAM Ứng Dụng",
                    value: ByteFormatterUtil.formatMemorySize(viewModel.appRamFootprint),
                    detail: "task_info footprint",
                    tint: GamingTheme.neonPurple
                )
                monitorBox(
                    label: "CPU Ứng Dụng",
                    value: String(format: "%.1f%%", viewModel.appCpuUsagePercent),
                    detail: "Mach thread_info",
                    tint: GamingTheme.neonCyan
                )
                monitorBox(
                    label: "Bộ Nhớ Trống",
                    value: ByteFormatterUtil.formatFileSize(viewModel.freeStorageBytes),
                    detail: "Khả dụng cho swap",
                    tint: GamingTheme.neonGreen
                )
                monitorBox(
                    label: "Trạng Thái Nhiệt",
                    value: viewModel.thermalStateTitle,
                    detail: "ProcessInfo.thermalState",
                    tint: thermalColor
                )
            }
        }
        .gamingCard(glowColor: GamingTheme.neonCyan.opacity(0.2), cornerRadius: 20, padding: 16)
    }

    private func monitorBox(label: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
            Text(detail)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(GamingTheme.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Transparency Disclaimer
    private var transparencyDisclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(GamingTheme.neonGreen)
            Text("Minh bạch kỹ thuật: iCleaner Pro hiển thị số liệu đo thực tế từ API công khai của Apple, không tạo FPS giả, không can thiệp trái phép vào tiến trình game của bạn.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(12)
        .background(GamingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Boost Success Sheet
    private var boostSuccessSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(GamingTheme.neonGreen)

            Text("TỐI ƯU HOÀN TẤT!")
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(.white)

            if let snap = viewModel.lastOptimization {
                VStack(spacing: 8) {
                    resultLine(title: "RAM ứng dụng đã thu hồi", value: ByteFormatterUtil.formatMemorySize(snap.freedAppMemoryBytes))
                    resultLine(title: "Cache sandbox đã dọn", value: ByteFormatterUtil.formatFileSize(snap.freedCacheBytes))
                    resultLine(title: "Dung lượng trống khả dụng", value: ByteFormatterUtil.formatFileSize(snap.storageFreeAfter))
                }
                .padding(16)
                .background(GamingTheme.cardBackgroundAlt)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                viewModel.showBoostSuccessSheet = false
            } label: {
                Text("SẴN SÀNG CHIẾN GAME")
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GamingTheme.neonGradient)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(24)
        .background(GamingTheme.darkBackground.ignoresSafeArea())
        .presentationDetents([.height(380)])
    }

    private func resultLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(GamingTheme.neonGreen)
        }
    }

    // MARK: - Session End Summary Sheet
    private var sessionEndSummarySheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 52))
                .foregroundStyle(GamingTheme.neonOrange)

            Text("KẾT THÚC PHIÊN CHƠI")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(.white)

            if let s = viewModel.lastCompletedSession {
                VStack(spacing: 8) {
                    resultLine(title: "Game", value: s.gameName)
                    resultLine(title: "Thời gian chơi", value: s.formattedDuration)
                    resultLine(title: "Cấu hình preset", value: s.presetMode)
                    resultLine(title: "Nhiệt độ kết thúc", value: s.finalThermalTitle)
                }
                .padding(16)
                .background(GamingTheme.cardBackgroundAlt)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                viewModel.showSessionEndSummary = false
            } label: {
                Text("ĐÓNG")
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GamingTheme.neonCyan)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(24)
        .background(GamingTheme.darkBackground.ignoresSafeArea())
        .presentationDetents([.height(390)])
    }
}
