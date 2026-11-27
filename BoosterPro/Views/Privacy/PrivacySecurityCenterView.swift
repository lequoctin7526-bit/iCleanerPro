import SwiftUI
import Photos

/// Dedicated Privacy & Security Center screen conforming to Apple Privacy Manifest & iOS Guidelines.
/// Displays on-device processing guarantees, PhotoKit permission status, Diagnostic Log viewer & cleaner.
struct PrivacySecurityCenterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var photoStatus: PhotoPermissionState = .notDetermined
    @State private var diagnosticLogs: [DiagnosticLogItem] = []
    @State private var showClearLogsConfirm: Bool = false
    @State private var clearNotice: String? = nil

    private let photoService = PhotoAnalysisService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        heroPrivacyBadge
                        onDeviceGuaranteeCard
                        photoPermissionStatusCard
                        privacyManifestSection
                        diagnosticLogsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Quyền Riêng Tư & Bảo Mật")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Xóa toàn bộ nhật ký chẩn đoán?",
                isPresented: $showClearLogsConfirm,
                titleVisibility: .visible
            ) {
                Button("Xóa nhật ký", role: .destructive) {
                    Task {
                        _ = await DiagnosticLogger.shared.clearLogs()
                        await loadLogs()
                        clearNotice = "Đã xóa toàn bộ nhật ký chẩn đoán nội bộ."
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Thao tác này chỉ xóa các file log chẩn đoán nội bộ của Booster Pro trong sandbox, không ảnh hưởng đến dữ liệu của bạn.")
            }
            .alert("Thông báo", isPresented: Binding(
                get: { clearNotice != nil },
                set: { if !$0 { clearNotice = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(clearNotice ?? "")
            }
            .task {
                refreshPhotoStatus()
                await loadLogs()
            }
        }
    }

    // MARK: - 1. Hero Privacy Badge
    private var heroPrivacyBadge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#00F5A0"), Color(hex: "#00D9F5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "#00F5A0").opacity(0.35), radius: 10, x: 0, y: 4)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.black)
            }

            VStack(spacing: 4) {
                Text("100% XỬ LÝ TRÊN THIẾT BỊ")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Không máy chủ từ xa • Không theo dõi người dùng • Không thu thập dữ liệu cá nhân")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: "#00F5A0").opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - 2. On-Device Guarantee Card
    private var onDeviceGuaranteeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.laptopcomputer")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("NGUYÊN TẮC BẢO VỆ DỮ LIỆU")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                guaranteeRow(
                    icon: "photo.stack",
                    title: "Thư viện Ảnh & Video",
                    detail: "Toàn bộ việc quét ảnh trùng lặp (dHash + Vision FeaturePrint) diễn ra trực tiếp bằng bộ xử lý Neural Engine của iPhone. Ảnh không bao giờ rời khỏi thiết bị."
                )

                Divider()

                guaranteeRow(
                    icon: "folder.badge.minus",
                    title: "Bộ nhớ & Sandbox",
                    detail: "Booster Pro chỉ được phép dọn tệp rác trong sandbox riêng của ứng dụng (tmp, Caches, Logs). Tuyệt đối không can thiệp Documents, file cá nhân hay app khác."
                )

                Divider()

                guaranteeRow(
                    icon: "antenna.radiowaves.left.and.right.slash",
                    title: "Không Telemetry & Tracking",
                    detail: "Ứng dụng không tích hợp bất kỳ SDK theo dõi, không gửi IDFA, và không có máy chủ thu thập dữ liệu hành vi người dùng."
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func guaranteeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "#00F5A0"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - 3. Photo Permission Status Card
    private var photoPermissionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.subheadline.bold())
                    .foregroundStyle(GamingTheme.neonPurple)
                Text("QUYỀN TRUY CẬP THƯ VIỆN ẢNH (PHOTOKIT)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(photoStatusBadgeColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: photoStatusIcon)
                        .font(.title3)
                        .foregroundStyle(photoStatusBadgeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(photoStatusTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(photoStatus.descriptionText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if photoStatus == .denied || photoStatus == .limited {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Cài đặt")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryAccent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var photoStatusTitle: String {
        switch photoStatus {
        case .authorized: return "Quyền đầy đủ (Full Access)"
        case .limited: return "Quyền giới hạn (Limited Access)"
        case .denied: return "Bị từ chối (Denied)"
        case .restricted: return "Bị giới hạn (Restricted)"
        case .notDetermined: return "Chưa yêu cầu quyền"
        }
    }

    private var photoStatusBadgeColor: Color {
        switch photoStatus {
        case .authorized: return Color(hex: "#00F5A0")
        case .limited: return Color.orange
        case .denied, .restricted: return Color.red
        case .notDetermined: return Color.secondary
        }
    }

    private var photoStatusIcon: String {
        switch photoStatus {
        case .authorized: return "checkmark.seal.fill"
        case .limited: return "exclamationmark.triangle.fill"
        case .denied, .restricted: return "xmark.octagon.fill"
        case .notDetermined: return "questionmark.circle.fill"
        }
    }

    // MARK: - 4. Apple Privacy Manifest (PrivacyInfo.xcprivacy)
    private var privacyManifestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.gearshape")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.secondaryAccent)
                Text("APPLE PRIVACY MANIFEST COMPLIANCE")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text("Booster Pro khai báo đầy đủ 4 danh mục API yêu cầu lý do hợp lệ (Required Reason API) theo chính sách Apple App Store:")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                manifestItem(
                    apiCategory: "DiskSpace",
                    reasonCode: "E174.1",
                    purpose: "Đo dung lượng bộ nhớ khả dụng của thiết bị để cảnh báo khi máy sắp đầy."
                )

                manifestItem(
                    apiCategory: "FileTimestamp",
                    reasonCode: "C617.1 & 0A2A.1",
                    purpose: "Kiểm tra thời gian tệp tạm trong sandbox và hiển thị cho người dùng."
                )

                manifestItem(
                    apiCategory: "SystemBootTime",
                    reasonCode: "35F9.1",
                    purpose: "Đo thời gian hoạt động hệ thống (ProcessInfo.systemUptime) để đánh giá độ ổn định."
                )

                manifestItem(
                    apiCategory: "UserDefaults",
                    reasonCode: "CA92.1",
                    purpose: "Lưu trữ cài đặt Auto Clean, danh sách game và cấu hình cá nhân cục bộ."
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func manifestItem(apiCategory: String, reasonCode: String, purpose: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(apiCategory)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text(reasonCode)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#00F5A0"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#00F5A0").opacity(0.14))
                    .clipShape(Capsule())
            }

            Text(purpose)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - 5. Diagnostic Logs Section
    private var diagnosticLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.clipboard")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.warningAmber)
                    Text("NHẬT KÝ CHẨN ĐOÁN NỘI BỘ")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !diagnosticLogs.isEmpty {
                    Button(role: .destructive) {
                        showClearLogsConfirm = true
                    } label: {
                        Text("Xóa log")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }
            }

            if diagnosticLogs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#00F5A0"))
                        Text("Nhật ký sạch, không có lỗi ghi nhận.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(diagnosticLogs.prefix(8)) { log in
                        HStack(alignment: .top, spacing: 8) {
                            Text(formatLogTime(log.timestamp))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Text("[\(log.category)]")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.primaryAccent)

                            Text(log.message)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(.vertical, 3)
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    // MARK: - Helpers
    private func refreshPhotoStatus() {
        photoStatus = photoService.currentPermissionState()
    }

    private func loadLogs() async {
        let logs = await DiagnosticLogger.shared.readRecentLogs(limit: 15)
        self.diagnosticLogs = logs
    }

    private func formatLogTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
