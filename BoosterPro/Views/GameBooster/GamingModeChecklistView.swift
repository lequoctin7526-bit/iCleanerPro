import SwiftUI

struct GamingModeChecklistView: View {
    @ObservedObject var viewModel: GameBoosterViewModel
    @Environment(\.dismiss) private var dismiss

    private var completedCount: Int {
        viewModel.checklistItems.filter(\.isCompleted).count
    }

    private var totalCount: Int {
        viewModel.checklistItems.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerStatusCard
                    checklistItemsSection
                    openSettingsCard
                }
                .padding(16)
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Gaming Mode Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(GamingTheme.neonCyan)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetChecklist()
                    } label: {
                        Text("Đặt lại")
                            .font(.caption.bold())
                            .foregroundStyle(GamingTheme.neonOrange)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerStatusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 68, height: 68)

                Circle()
                    .trim(from: 0, to: Double(completedCount) / Double(max(1, totalCount)))
                    .stroke(GamingTheme.neonGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completedCount)

                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(completedCount == totalCount ? "SẴN SÀNG CHIẾN GAME" : "CHUẨN BỊ THIẾT BỊ")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(completedCount == totalCount ? GamingTheme.neonGreen : GamingTheme.neonOrange)

                Text("Hoàn thành các bước chuẩn bị bên dưới để tránh bị làm phiền và đạt hiệu năng tối đa khi chơi game.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .gamingCard(glowColor: completedCount == totalCount ? GamingTheme.neonGreen : GamingTheme.neonOrange, cornerRadius: 20, padding: 16)
    }

    private var checklistItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CÁC BƯỚC KHUYẾN NGHỊ")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(GamingTheme.neonPurple)

            ForEach(viewModel.checklistItems) { item in
                Button {
                    viewModel.toggleChecklistItem(id: item.id)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isCompleted ? GamingTheme.neonGreen : .white.opacity(0.4))
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(item.isCompleted ? GamingTheme.neonGreen : .white)
                                Spacer()
                                if item.isOptional {
                                    Text("Tùy chọn")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }

                            Text(item.detail)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 9))
                                Text(item.targetSettingDescription)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(GamingTheme.neonCyan)
                            .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .background(GamingTheme.cardBackgroundAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .gamingCard(glowColor: GamingTheme.neonPurple.opacity(0.2), cornerRadius: 20, padding: 16)
    }

    private var openSettingsCard: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.openSettings()
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Mở Cài đặt iOS")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(GamingTheme.cardBackgroundAlt)
                .foregroundStyle(GamingTheme.neonCyan)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(GamingTheme.neonCyan.opacity(0.4), lineWidth: 1)
                )
            }

            Text("iOS không cho phép ứng dụng bên thứ ba tự ý bật/tắt Focus Mode hoặc Low Power Mode ngoài hệ thống. Booster Pro hỗ trợ hướng dẫn và phím tắt tiện lợi nhất.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}
