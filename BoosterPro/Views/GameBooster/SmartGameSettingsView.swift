import SwiftUI

/// Settings screen for configuring smart automation behaviors.
struct SmartGameSettingsView: View {
    @ObservedObject var viewModel: SmartGameManagerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var settings: SmartGameAutomationSettings
    @State private var showAutoCleanSettingsSheet: Bool = false

    init(viewModel: SmartGameManagerViewModel) {
        self.viewModel = viewModel
        _settings = State(initialValue: viewModel.automationSettings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    automationSection
                    autoCleanDetailCard
                    privacyNoticeCard
                }
                .padding(16)
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Cài Đặt Tự Động Hóa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        viewModel.saveSettings(settings)
                        dismiss()
                    }
                    .font(.headline.bold())
                    .foregroundStyle(GamingTheme.neonGreen)
                }
            }
            .sheet(isPresented: $showAutoCleanSettingsSheet) {
                AutoCleanSettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var autoCleanDetailCard: some View {
        Button {
            showAutoCleanSettingsSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(GamingTheme.neonGreen)
                    .frame(width: 36, height: 36)
                    .background(GamingTheme.neonGreen.opacity(0.18))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Cấu hình Lập lịch Auto Clean")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Tùy biến lịch chạy nền, điều kiện pin sạc và loại file dọn")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(14)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var automationSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("TỰ ĐỘNG HÓA THÔNG MINH")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonCyan)
                Spacer()
            }

            VStack(spacing: 12) {
                settingToggle(
                    title: "Tự động nhận diện game",
                    subtitle: "Kiểm tra game đã cài đặt trên máy thông qua URL Scheme được cấp phép.",
                    icon: "magnifyingglass.circle.fill",
                    tint: GamingTheme.neonGreen,
                    isOn: $settings.autoDetectGames
                )

                Divider().background(Color.white.opacity(0.08))

                settingToggle(
                    title: "Tự động kiểm tra bản cập nhật",
                    subtitle: "So sánh phiên bản đang cài với App Store để thông báo khi có bản mới.",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    tint: GamingTheme.neonOrange,
                    isOn: $settings.autoCheckUpdates
                )

                Divider().background(Color.white.opacity(0.08))

                settingToggle(
                    title: "Tối ưu hóa trước khi chơi",
                    subtitle: "Dọn dẹp cache & giải phóng bộ nhớ của Booster Pro ngay khi bạn bấm PLAY.",
                    icon: "bolt.shield.fill",
                    tint: GamingTheme.neonCyan,
                    isOn: $settings.autoOptimizeBeforePlay
                )

                Divider().background(Color.white.opacity(0.08))

                settingToggle(
                    title: "Tự động dọn dẹp sau khi chơi (Auto Clean)",
                    subtitle: "Thu hồi tài nguyên tệp tạm và lưu thống kê khi phiên chơi game kết thúc.",
                    icon: "sparkles.circle.fill",
                    tint: GamingTheme.neonPurple,
                    isOn: $settings.autoCleanAfterGaming
                )

                Divider().background(Color.white.opacity(0.08))

                settingToggle(
                    title: "Khuyến nghị Gaming Focus",
                    subtitle: "Đề xuất kích hoạt Chế độ Tập trung Chơi game để tránh bị gián đoạn.",
                    icon: "moon.stars.fill",
                    tint: GamingTheme.neonCyan,
                    isOn: $settings.gamingFocusRecommendations
                )

                Divider().background(Color.white.opacity(0.08))

                settingToggle(
                    title: "Thông báo cập nhật mới",
                    subtitle: "Gửi thông báo cục bộ khi phát hiện game của bạn có phiên bản mới.",
                    icon: "bell.badge.fill",
                    tint: GamingTheme.neonOrange,
                    isOn: $settings.updateNotifications
                )
            }
            .padding(16)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func settingToggle(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(GamingTheme.neonGreen)
        }
    }

    private var privacyNoticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(GamingTheme.neonGreen)
                Text("CAM KẾT MINH BẠCH & BẢO MẬT")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Text("• Booster Pro 100% sử dụng Apple Public APIs, không can thiệp vào tiến trình của ứng dụng bên thứ ba.\n• Quá trình kiểm tra phiên bản sử dụng trực tiếp Apple iTunes Search/Lookup API công khai, không thu thập hay tải lên bất kỳ dữ liệu cá nhân nào.\n• Quá trình Auto Clean hoạt động an toàn trong phạm vi sandbox của ứng dụng và tuân thủ tuyệt đối chuẩn iOS.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(3)
        }
        .padding(16)
        .background(GamingTheme.cardBackgroundAlt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
