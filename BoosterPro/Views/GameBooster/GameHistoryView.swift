import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var viewModel: GameBoosterViewModel
    @Environment(\.dismiss) private var dismiss

    enum HistoryTab: String, CaseIterable, Identifiable {
        case sessions = "Phiên Chơi Game"
        case optimizations = "Lịch Sử Tối Ưu"
        var id: String { rawValue }
    }

    @State private var selectedTab: HistoryTab = .sessions

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("Loại lịch sử", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == .sessions {
                            if viewModel.sessionHistory.isEmpty {
                                emptyStateCard(title: "Chưa có phiên chơi game nào", icon: "gamecontroller")
                            } else {
                                ForEach(viewModel.sessionHistory) { record in
                                    sessionRecordRow(record)
                                }
                            }
                        } else {
                            if viewModel.optimizationHistory.isEmpty {
                                emptyStateCard(title: "Chưa có lịch sử tối ưu nào", icon: "bolt.shield")
                            } else {
                                ForEach(viewModel.optimizationHistory) { opt in
                                    optimizationRow(opt)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Lịch Sử Game Booster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(GamingTheme.neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sessionRecordRow(_ record: GameSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.gameName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Spacer()
                Text(record.formattedDuration)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonGreen)
            }

            HStack {
                Text(record.presetMode)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(GamingTheme.neonPurple.opacity(0.18))
                    .foregroundStyle(GamingTheme.neonPurple)
                    .clipShape(Capsule())

                Text(record.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                if record.batteryLevelStart >= 0 && record.batteryLevelEnd >= 0 {
                    let drop = Int((record.batteryLevelStart - record.batteryLevelEnd) * 100)
                    if drop > 0 {
                        Text("-\(drop)% pin")
                            .font(.caption2.bold())
                            .foregroundStyle(GamingTheme.neonOrange)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                Label("Nhiệt độ: \(record.initialThermalTitle) → \(record.finalThermalTitle)", systemImage: "thermometer.medium")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
        }
        .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.15), cornerRadius: 16, padding: 12)
    }

    private func optimizationRow(_ opt: GameOptimizationSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("BOOST NOW", systemImage: "bolt.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(GamingTheme.neonGreen)
                Spacer()
                Text(opt.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 16) {
                statItem("RAM thu hồi", ByteFormatterUtil.formatMemorySize(opt.freedAppMemoryBytes), GamingTheme.neonPurple)
                statItem("Cache đã xóa", ByteFormatterUtil.formatFileSize(opt.freedCacheBytes), GamingTheme.neonCyan)
                statItem("Trống khả dụng", ByteFormatterUtil.formatFileSize(opt.storageFreeAfter), GamingTheme.neonGreen)
            }
        }
        .gamingCard(glowColor: GamingTheme.neonCyan.opacity(0.15), cornerRadius: 16, padding: 12)
    }

    private func statItem(_ label: String, _ val: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
            Text(val)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
    }

    private func emptyStateCard(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(GamingTheme.neonGreen)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.1))
    }
}
