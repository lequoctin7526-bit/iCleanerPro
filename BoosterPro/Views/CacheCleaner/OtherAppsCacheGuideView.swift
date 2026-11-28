import SwiftUI

/// Educational and practical guide explaining Apple iOS App Sandbox boundaries
/// and guiding users on managing third-party app storage via official Apple settings.
struct OtherAppsCacheGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroBadge
                    securityArchitectureCard
                    twoZoneComparisonCard
                    stepByStepGuideCard
                    offloadVsDeleteCard
                    openSettingsButton
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Hướng dẫn Cache App khác")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                }
            }
        }
    }

    // MARK: - 1. Hero Badge
    private var heroBadge: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#00F5A0").opacity(0.2), Color(hex: "#00D9F5").opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)

                Image(systemName: "app.connected.to.app.below.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(hex: "#00F5A0"))
            }

            Text("QUẢN LÝ DUNG LƯỢNG ỨNG DỤNG KHÁC")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)

            Text("Minh bạch công nghệ theo kiến trúc bảo mật Sandbox của Apple iOS")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - 2. Security Architecture Card
    private var securityArchitectureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(AppTheme.optimalGreen)
                Text("NGUYÊN TẮC BẢO MẬT APP SANDBOX")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text("Trên iOS không can thiệp hệ thống (No-Jailbreak), mỗi ứng dụng hoạt động trong một không gian bảo mật độc lập (**Sandbox**). Ứng dụng này tuyệt đối không thể đọc trộm, chỉnh sửa hoặc xóa bộ nhớ đệm của ứng dụng khác (như Facebook, TikTok, YouTube, Messenger...).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("Booster Pro cam kết **nói không với số liệu giả mạo** và không bao giờ quảng cáo sai sự thật rằng có thể xóa cache của ứng dụng bên thứ ba bằng một nút bấm.")
                .font(.caption)
                .foregroundStyle(AppTheme.primaryAccent)
                .padding(.top, 4)
        }
        .premiumCard(cornerRadius: 18, padding: 16)
    }

    // MARK: - 3. Two-Zone Comparison Card
    private var twoZoneComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PHÂN BIỆT 2 NHÓM DỮ LIỆU TRÊN THIẾT BỊ")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "#00F5A0"))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("1. Cache do Booster Pro quản lý")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("Bao gồm URLCache, ảnh thu nhỏ, tệp tạm thời trong sandbox. Booster Pro có thể phân tích chính xác từng byte và dọn dẹp trực tiếp tức thì.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(hex: "#00F5A0").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundStyle(AppTheme.warningAmber)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("2. Cache của các ứng dụng khác")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("Chỉ có thể quản lý thông qua tính năng chính thức của Apple trong Cài đặt iOS. Người dùng cần tự thao tác theo hướng dẫn bên dưới.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(AppTheme.warningAmber.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .premiumCard(cornerRadius: 18, padding: 16)
    }

    // MARK: - 4. Step-by-Step Guide
    private var stepByStepGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("CÁC BƯỚC DỌN DUNG LƯỢNG ỨNG DỤNG TRÊN IPHONE")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                stepRow(number: "1", title: "Mở Cài đặt (Settings)", detail: "Truy cập ứng dụng Cài đặt có sẵn trên màn hình chính của iPhone.")
                stepRow(number: "2", title: "Vào Cài đặt chung > Dung lượng iPhone", detail: "Chọn 'General' sau đó nhấn vào 'iPhone Storage'.")
                stepRow(number: "3", title: "Kiểm tra danh sách ứng dụng", detail: "Đợi vài giây để iOS thống kê dung lượng ứng dụng từ cao xuống thấp.")
                stepRow(number: "4", title: "Chọn ứng dụng chiếm nhiều dữ liệu", detail: "Nhấn vào ứng dụng bạn muốn tối ưu (như mạng xã hội, ứng dụng xem video).")
            }
        }
        .premiumCard(cornerRadius: 18, padding: 16)
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline.bold())
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
                .background(Color(hex: "#00F5A0"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 5. Offload App vs Delete App
    private var offloadVsDeleteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(GamingTheme.neonPurple)
                Text("PHÂN BIỆT: GỠ BỎ ỨNG DỤNG VS XÓA ỨNG DỤNG")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.down.app.fill")
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("Gỡ bỏ ứng dụng (Offload App)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Khuyên dùng")
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: "#00F5A0"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#00F5A0").opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text("• **Tác dụng**: Giải phóng dung lượng của chính ứng dụng (.ipa).\n• **Bảo vệ**: Giữ lại toàn bộ tài liệu, dữ liệu cá nhân và tài khoản.\n• **Khôi phục**: Khi cần dùng, chỉ cần chạm lại vào icon ứng dụng để tải lại mà không mất dữ liệu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(12)
                .background(AppTheme.primaryAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(AppTheme.criticalRed)
                        Text("Xóa ứng dụng (Delete App)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Xóa vĩnh viễn")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.criticalRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppTheme.criticalRed.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text("• **Tác dụng**: Xóa sạch ứng dụng VÀ tất cả tài liệu, tệp đệm, dữ liệu liên quan.\n• **Cảnh báo**: Dữ liệu chưa đồng bộ lên Cloud sẽ bị mất vĩnh viễn không thể khôi phục lại.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(12)
                .background(AppTheme.criticalRed.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .premiumCard(cornerRadius: 18, padding: 16)
    }

    // MARK: - 6. Action Button
    private var openSettingsButton: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                Text("Mở Cài đặt iPhone")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppTheme.primaryAccent, Color(hex: "#00F5A0")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 8, x: 0, y: 3)
        }
    }
}
