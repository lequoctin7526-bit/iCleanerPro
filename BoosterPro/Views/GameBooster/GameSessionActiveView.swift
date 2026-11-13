import SwiftUI

struct GameSessionActiveView: View {
    @ObservedObject var viewModel: GameBoosterViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmEnd = false

    var body: some View {
        ZStack {
            GamingTheme.darkBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                topBar
                gameHeaderCard
                stopwatchHUD
                liveMetricsGrid
                Spacer()
                endSessionButton
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Kết thúc phiên chơi game?",
            isPresented: $showConfirmEnd,
            titleVisibility: .visible
        ) {
            Button("Kết thúc và Lưu lịch sử", role: .destructive) {
                viewModel.endActiveSession()
                dismiss()
            }
            Button("Tiếp tục chơi", role: .cancel) {}
        } message: {
            Text("Thời gian chơi và các chỉ số phiên sẽ được lưu lại trong Lịch sử Game Booster.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                    Text("Thu nhỏ HUD")
                }
                .font(.caption.bold())
                .foregroundStyle(GamingTheme.neonCyan)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(GamingTheme.neonGreen)
                    .frame(width: 8, height: 8)
                Text("SESSION ACTIVE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(GamingTheme.neonGreen.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private var gameHeaderCard: some View {
        VStack(spacing: 8) {
            if let game = viewModel.activeGame {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(GamingTheme.cardBackgroundAlt)
                        .frame(width: 68, height: 68)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(GamingTheme.colorForHex(game.colorHex), lineWidth: 2)
                        )

                    Image(systemName: game.iconSymbol)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(GamingTheme.colorForHex(game.colorHex))
                }

                Text(game.name)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)

                Text("Cấu hình: \(viewModel.selectedPreset.rawValue)")
                    .font(.caption.bold())
                    .foregroundStyle(GamingTheme.neonPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(GamingTheme.neonPurple.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.18), cornerRadius: 22, padding: 18)
    }

    private var stopwatchHUD: some View {
        VStack(spacing: 6) {
            Text("THỜI GIAN TRONG TRẬN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            Text(viewModel.sessionDurationFormatted)
                .font(.system(size: 48, weight: .black, design: .monospaced))
                .foregroundStyle(GamingTheme.neonGreen)
                .contentTransition(.numericText())
                .shadow(color: GamingTheme.neonGreen.opacity(0.5), radius: 10, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(GamingTheme.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var liveMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHỈ SỐ THỰC TẾ HỆ THỐNG")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(GamingTheme.neonCyan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                sessionMetricBox(
                    title: "Nhiệt độ máy",
                    value: viewModel.thermalStateTitle,
                    tint: GamingTheme.neonOrange
                )
                sessionMetricBox(
                    title: "Pin hiện tại",
                    value: "\(viewModel.batteryLevelPercent)%",
                    tint: GamingTheme.neonGreen
                )
                sessionMetricBox(
                    title: "App RAM Footprint",
                    value: ByteFormatterUtil.formatMemorySize(viewModel.appRamFootprint),
                    tint: GamingTheme.neonPurple
                )
                sessionMetricBox(
                    title: "Bộ nhớ khả dụng",
                    value: ByteFormatterUtil.formatFileSize(viewModel.freeStorageBytes),
                    tint: GamingTheme.neonCyan
                )
            }
        }
        .gamingCard(glowColor: GamingTheme.neonCyan.opacity(0.15), cornerRadius: 20, padding: 16)
    }

    private func sessionMetricBox(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(GamingTheme.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var endSessionButton: some View {
        Button {
            showConfirmEnd = true
        } label: {
            HStack {
                Image(systemName: "flag.checkered")
                Text("KẾT THÚC PHIÊN CHƠI GAME")
                    .fontWeight(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GamingTheme.neonRed)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: GamingTheme.neonRed.opacity(0.4), radius: 10, x: 0, y: 4)
        }
    }
}
