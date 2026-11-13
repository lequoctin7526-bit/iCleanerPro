import SwiftUI

/// Clear guidance modal presented when a game does not support direct URL Scheme launching.
struct ManualGameLaunchGuidanceSheet: View {
    let game: SmartGameModel
    let onOpenAppStore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(GamingTheme.neonOrange.opacity(0.18))
                    .frame(width: 72, height: 72)

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(GamingTheme.neonOrange)
            }

            VStack(spacing: 6) {
                Text("HƯỚNG DẪN MỞ GAME THỦ CÔNG")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonOrange)

                Text(game.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("iOS bảo vệ quyền riêng tư và yêu cầu URL Scheme đăng ký chính thức để mở trực tiếp.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(
                    step: "1",
                    title: "Mở game từ Màn hình chính",
                    detail: "Vuốt lên về Home Screen và mở \(game.name) như thông thường."
                )

                instructionRow(
                    step: "2",
                    title: "Phiên chơi đang được tính giờ",
                    detail: "Hệ thống iCleaner Pro đã tự động kích hoạt bộ đếm theo dõi thời gian chơi của bạn."
                )

                instructionRow(
                    step: "3",
                    title: "Tự động dọn dẹp khi hoàn tất",
                    detail: "Khi chơi xong, mở lại iCleaner Pro và bấm 'Kết thúc' để kích hoạt Auto Clean."
                )
            }
            .padding(16)
            .background(GamingTheme.cardBackgroundAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 10) {
                if !game.appStoreId.isEmpty {
                    Button {
                        onOpenAppStore()
                        onDismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                            Text("KIỂM TRA TRÊN APP STORE")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Button {
                    onDismiss()
                } label: {
                    Text("ĐÃ HIỂU, ĐỂ TÔI MỞ THỦ CÔNG")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(GamingTheme.neonGradient)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(24)
        .background(GamingTheme.darkBackground.ignoresSafeArea())
        .presentationDetents([.height(520)])
    }

    private func instructionRow(step: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption.bold())
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
                .background(GamingTheme.neonOrange)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
