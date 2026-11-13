import SwiftUI

struct CacheCleanerView: View {
    @StateObject private var viewModel = CacheCleanerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryHeader

                if let result = viewModel.lastResult {
                    resultBanner(result)
                }

                cleanableSection
                protectedSection
                scopeDisclaimer
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Dọn bộ nhớ đệm")
        .safeAreaInset(edge: .bottom) {
            if viewModel.selectedCleanableBytes > 0 {
                cleanBar
            }
        }
        .confirmationDialog(
            "Xóa bộ nhớ đệm đã chọn?",
            isPresented: $viewModel.showConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("Xóa \(ByteFormatterUtil.formatFileSize(viewModel.selectedCleanableBytes))", role: .destructive) {
                Task { await viewModel.cleanSelectedCaches() }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Dữ liệu đăng nhập, cài đặt và tài liệu được bảo vệ sẽ được giữ nguyên hoàn toàn.")
        }
        .onAppear {
            viewModel.scanCaches()
        }
    }

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bộ nhớ đệm có thể xóa an toàn")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.totalCleanableBytes))
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.warningAmber)
            }
            Spacer()
            Button {
                viewModel.scanCaches()
            } label: {
                Label("Kiểm tra", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func resultBanner(_ result: CacheCleanupResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.optimalGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã xóa \(ByteFormatterUtil.formatFileSize(result.freedBytes)) bộ nhớ đệm")
                    .font(.subheadline.weight(.bold))
                Text("Dữ liệu bảo vệ giữ nguyên: \(ByteFormatterUtil.formatFileSize(result.protectedBytesUntouched))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.optimalGreen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var cleanableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cache có thể xóa (An toàn)")
                .font(.subheadline.weight(.bold))

            ForEach(viewModel.deletablePartitions) { item in
                Button {
                    viewModel.togglePartition(id: item.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isSelected ? AppTheme.primaryAccent : .secondary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(ByteFormatterUtil.formatFileSize(item.sizeBytes))
                            .font(.caption.weight(.bold))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if item.id != viewModel.deletablePartitions.last?.id {
                    Divider()
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var protectedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Dữ liệu được bảo vệ (Không tự động xóa)", systemImage: "lock.shield.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.optimalGreen)

            ForEach(viewModel.protectedPartitions) { item in
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(AppTheme.optimalGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                        Text(item.protectionReason ?? item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(ByteFormatterUtil.formatFileSize(item.sizeBytes))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var scopeDisclaimer: some View {
        Text("Lưu ý: Trên iOS không Jailbreak, các ứng dụng không có quyền hệ thống để xóa cache của Safari hoặc ứng dụng bên thứ ba khác. Mọi dữ liệu hiển thị ở đây đều thuộc vùng lưu trữ hợp lệ do ứng dụng quản lý.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var cleanBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dung lượng cache sẽ xóa")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedCleanableBytes))
                    .font(.headline.weight(.bold))
            }
            Spacer()
            Button {
                viewModel.showConfirmDialog = true
            } label: {
                Text("Xóa Cache")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(AppTheme.warningAmber)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
