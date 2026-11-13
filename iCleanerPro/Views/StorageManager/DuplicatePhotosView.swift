import Photos
import SwiftUI

struct DuplicatePhotosView: View {
    @ObservedObject var viewModel: StorageManagerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.photoPermission.canAccessPhotos {
                    permissionPromptCard
                } else {
                    scanHeaderCard

                    if viewModel.isScanningMedia {
                        ProgressView(value: viewModel.scanProgress) {
                            Text("Đang phân tích ảnh trùng lặp bằng dHash & Vision...")
                                .font(.caption)
                        }
                        .padding()
                        .premiumCard(cornerRadius: 18, padding: 14)
                    } else if viewModel.duplicateGroups.isEmpty {
                        emptyResultCard
                    } else {
                        ForEach(viewModel.duplicateGroups) { group in
                            duplicateGroupCard(group)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Ảnh trùng lặp")
        .safeAreaInset(edge: .bottom) {
            if !viewModel.selectedDuplicateAssets.isEmpty {
                deleteFooterBar
            }
        }
        .confirmationDialog(
            "Xóa \(viewModel.selectedDuplicateAssets.count) ảnh đã chọn?",
            isPresented: $viewModel.showDeleteDuplicatesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa ảnh đã chọn (~\(ByteFormatterUtil.formatFileSize(viewModel.selectedDuplicateBytes)))", role: .destructive) {
                Task { await viewModel.deleteConfirmedDuplicates() }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("iOS sẽ hiển thị hộp thoại xác nhận cuối cùng và chuyển ảnh vào Đã xóa gần đây trong 30 ngày.")
        }
    }

    private var permissionPromptCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.warningAmber)
            Text("Cần quyền truy cập Ảnh")
                .font(.headline)
            Text("Vui lòng cấp quyền truy cập Thư viện Ảnh (đầy đủ hoặc giới hạn) để phân tích ảnh trùng lặp hoàn toàn trên thiết bị.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Cấp quyền ngay") {
                Task { await viewModel.requestPhotosAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .premiumCard(cornerRadius: 20, padding: 20)
    }

    private var scanHeaderCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tìm ảnh trùng & ảnh chụp liên tiếp")
                    .font(.subheadline.weight(.bold))
                Text("Giữ lại bản độ phân giải cao nhất, chỉ xóa khi bạn xác nhận.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.scanDuplicates() }
            } label: {
                Label("Quét ảnh", systemImage: "sparkle.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.violetAccent)
            .disabled(viewModel.isScanningMedia)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func duplicateGroupCard(_ group: DuplicatePhotoGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.matchType.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.violetAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.violetAccent.opacity(0.14))
                    .clipShape(Capsule())

                Text("Tương đồng \(Int(group.similarityScore * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(group.assets.count) ảnh")
                    .font(.caption.weight(.semibold))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.assets) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                PHAssetThumbnailView(
                                    asset: item.asset,
                                    photoService: viewModel.photoService,
                                    size: CGSize(width: 128, height: 128)
                                )
                                .frame(width: 128, height: 128)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            item.isSelected ? AppTheme.criticalRed : (item.id == group.recommendedKeepAssetID ? AppTheme.optimalGreen : Color.clear),
                                            lineWidth: 2.5
                                        )
                                )

                                Button {
                                    viewModel.toggleDuplicateSelection(groupID: group.id, assetID: item.id)
                                } label: {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.isSelected ? AppTheme.criticalRed : .white)
                                        .shadow(radius: 2)
                                        .padding(6)
                                }
                            }

                            HStack {
                                Text(item.id == group.recommendedKeepAssetID ? "Bản gốc gợi ý" : "Bản sao")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(item.id == group.recommendedKeepAssetID ? AppTheme.optimalGreen : .secondary)
                                Spacer()
                            }
                            Text("\(ByteFormatterUtil.formatFileSize(item.fileSizeBytes)) • \(item.resolutionLabel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 128)
                    }
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 14)
    }

    private var emptyResultCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.stack")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.optimalGreen)
            Text("Chưa tìm thấy ảnh trùng lặp")
                .font(.headline)
            Text("Nhấn \"Quét ảnh\" để phân tích tối đa 500 ảnh gần nhất trong thư viện của bạn.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .premiumCard(cornerRadius: 20, padding: 24)
    }

    private var deleteFooterBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã chọn \(viewModel.selectedDuplicateAssets.count) ảnh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedDuplicateBytes))
                    .font(.headline.weight(.bold))
            }
            Spacer()
            Button {
                viewModel.showDeleteDuplicatesConfirmation = true
            } label: {
                Text("Xóa ảnh chọn")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.criticalRed)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

/// Reusable async PhotoKit thumbnail loader.
struct PHAssetThumbnailView: View {
    let asset: PHAsset
    let photoService: PhotoAnalysisService
    let size: CGSize

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .task(id: asset.localIdentifier) {
            let scale = UIScreen.main.scale
            let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
            image = await photoService.loadThumbnail(for: asset, targetSize: pixelSize)
        }
    }
}
