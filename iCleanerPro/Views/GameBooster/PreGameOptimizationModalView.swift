import SwiftUI

/// Animated 3-step HUD displayed when Auto-Optimize Before Gaming executes.
struct PreGameOptimizationModalView: View {
    let game: SmartGameModel
    let currentStep: Int // 0: Check, 1: Clean, 2: Complete
    let snapshot: GameOptimizationSnapshot?

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                // Header Game Icon
                ZStack {
                    Circle()
                        .fill(GamingTheme.neonGreen.opacity(0.18))
                        .frame(width: 80, height: 80)

                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(GamingTheme.neonGreen)
                }

                VStack(spacing: 4) {
                    Text("TỰ ĐỘNG TỐI ƯU TRƯỚC TRẬN")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(GamingTheme.neonCyan)

                    Text(game.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                // 3 Step Indicator
                VStack(spacing: 12) {
                    stepRow(
                        stepIndex: 0,
                        title: "Bước 1: Phân tích thiết bị & dung lượng",
                        detail: "Kiểm tra swap, nhiệt độ máy & pin",
                        isActive: currentStep == 0,
                        isDone: currentStep > 0
                    )

                    stepRow(
                        stepIndex: 1,
                        title: "Bước 2: Thu hồi RAM & dọn cache sandbox",
                        detail: "Giải phóng tài nguyên không cần thiết của iCleaner Pro",
                        isActive: currentStep == 1,
                        isDone: currentStep > 1
                    )

                    stepRow(
                        stepIndex: 2,
                        title: "Bước 3: Sẵn sàng khởi động game",
                        detail: snapshot != nil ? "Đã dọn \(ByteFormatterUtil.formatFileSize((snapshot?.freedAppMemoryBytes ?? 0) + (snapshot?.freedCacheBytes ?? 0)))" : "Khởi tạo môi trường mượt mà",
                        isActive: currentStep == 2,
                        isDone: currentStep == 2
                    )
                }
                .padding(16)
                .background(GamingTheme.cardBackgroundAlt)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Spinner or Success
                if currentStep < 2 {
                    HStack(spacing: 10) {
                        ProgressView().tint(GamingTheme.neonGreen)
                        Text("Đang thực hiện quy trình tối ưu...")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(GamingTheme.neonGreen)
                        Text("Tối ưu thành công! Đang mở game...")
                            .font(.caption.bold())
                            .foregroundStyle(GamingTheme.neonGreen)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(GamingTheme.neonGreen.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: GamingTheme.neonGreen.opacity(0.35), radius: 20)
        }
    }

    private func stepRow(stepIndex: Int, title: String, detail: String, isActive: Bool, isDone: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isDone ? GamingTheme.neonGreen : (isActive ? GamingTheme.neonCyan : Color.white.opacity(0.1)))
                    .frame(width: 28, height: 28)

                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                } else if isActive {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.6)
                } else {
                    Text("\(stepIndex + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isDone || isActive ? .white : .white.opacity(0.5))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(isDone || isActive ? GamingTheme.neonCyan : .white.opacity(0.3))
            }

            Spacer()
        }
    }
}
