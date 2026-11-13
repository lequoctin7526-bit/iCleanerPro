import SwiftUI

/// Summary sheet presented when a gaming session ends and Auto Clean finishes.
struct PostGameCleanSummarySheetView: View {
    let session: GameSessionRecord?
    let snapshot: GameOptimizationSnapshot?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(GamingTheme.neonGreen.opacity(0.18))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(GamingTheme.neonGreen)
            }

            VStack(spacing: 4) {
                Text("AUTO CLEAN HOÀN TẤT!")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)

                Text("Tổng kết phiên chơi game")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                if let s = session {
                    summaryRow(label: "Game đã chơi", value: s.gameName, tint: .white)
                    summaryRow(label: "Thời gian chiến game", value: s.formattedDuration, tint: GamingTheme.neonCyan)
                    summaryRow(label: "Nhiệt độ kết thúc", value: s.finalThermalTitle, tint: GamingTheme.neonOrange)
                }

                if let snap = snapshot {
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(
                        label: "Bộ nhớ đệm Booster Pro đã thu hồi",
                        value: ByteFormatterUtil.formatFileSize(snap.freedAppMemoryBytes + snap.freedCacheBytes),
                        tint: GamingTheme.neonGreen
                    )
                    summaryRow(
                        label: "Dung lượng bộ nhớ khả dụng",
                        value: ByteFormatterUtil.formatFileSize(snap.storageFreeAfter),
                        tint: GamingTheme.neonCyan
                    )
                }
            }
            .padding(16)
            .background(GamingTheme.cardBackgroundAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                onDismiss()
            } label: {
                Text("XÁC NHẬN")
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
        .presentationDetents([.height(440)])
    }

    private func summaryRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
        }
    }
}
