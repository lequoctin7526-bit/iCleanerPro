import SwiftUI
import UniformTypeIdentifiers

struct StorageManagerView: View {
    @StateObject private var viewModel = StorageManagerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    storageSummaryCard
                    photosAccessCard
                    managementToolsSection

                    if let message = viewModel.lastActionMessage {
                        infoBanner(message, tint: AppTheme.optimalGreen, icon: "checkmark.circle.fill")
                    }
                    if let error = viewModel.errorMessage {
                        infoBanner(error, tint: AppTheme.criticalRed, icon: "exclamationmark.triangle.fill")
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Quản lý dung lượng")
            .onAppear {
                viewModel.loadInitialState()
            }
        }
    }

    private var storageSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StorageBarChart(storage: viewModel.storageInfo)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Khả dụng (Dữ liệu quan trọng)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(ByteFormatterUtil.formatFileSize(viewModel.storageInfo.importantAvailableBytes))
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Khả dụng (Tức thời)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(ByteFormatterUtil.formatFileSize(viewModel.storageInfo.opportunisticAvailableBytes))
                        .font(.subheadline.weight(.bold))
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var photosAccessCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Quyền Thư viện Ảnh (PhotoKit)", systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(permissionBadgeText)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(permissionTint.opacity(0.14))
                    .foregroundStyle(permissionTint)
                    .clipShape(Capsule())
            }

            Text(viewModel.photoPermission.descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                if viewModel.photoPermission == .notDetermined {
                    Button("Cấp quyền phân tích ảnh") {
                        Task { await viewModel.requestPhotosAccess() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primaryAccent)
                } else if viewModel.photoPermission == .limited {
                    Button("Chọn thêm ảnh cho phép") {
                        viewModel.openLimitedLibraryPicker()
                    }
                    .buttonStyle(.bordered)
                } else if viewModel.photoPermission == .denied || viewModel.photoPermission == .restricted {
                    Button("Mở Cài đặt quyền") {
                        viewModel.openAppSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.warningAmber)
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var permissionBadgeText: String {
        switch viewModel.photoPermission {
        case .authorized: return "Đầy đủ"
        case .limited: return "Giới hạn"
        case .notDetermined: return "Chưa hỏi"
        case .denied, .restricted: return "Bị từ chối"
        }
    }

    private var permissionTint: Color {
        switch viewModel.photoPermission {
        case .authorized: return AppTheme.optimalGreen
        case .limited: return AppTheme.warningAmber
        case .notDetermined: return AppTheme.primaryAccent
        case .denied, .restricted: return AppTheme.criticalRed
        }
    }

    private var managementToolsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                DuplicatePhotosView(viewModel: viewModel)
            } label: {
                toolRow(
                    title: "Tìm ảnh trùng lặp & tương tự",
                    subtitle: "So sánh trên thiết bị bằng dHash + Apple Vision",
                    icon: "square.on.square",
                    tint: AppTheme.violetAccent
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LargeMediaView(viewModel: viewModel)
            } label: {
                toolRow(
                    title: "Ảnh & Video dung lượng lớn",
                    subtitle: "Lọc tệp media chiếm nhiều bộ nhớ để xem xét xóa",
                    icon: "video.badge.waveform",
                    tint: AppTheme.criticalRed
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SandboxFilesManagerView(viewModel: viewModel)
            } label: {
                toolRow(
                    title: "Quản lý tệp qua Files Picker",
                    subtitle: "Đã quản lý \(viewModel.managedFiles.count) tệp người dùng chọn",
                    icon: "folder.badge.gearshape",
                    tint: AppTheme.primaryAccent
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func toolRow(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .premiumCard(cornerRadius: 18, padding: 14)
    }

    private func infoBanner(_ text: String, tint: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
            Spacer()
        }
        .padding(12)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
