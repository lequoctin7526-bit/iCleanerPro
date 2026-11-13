import Photos
import SwiftUI

struct LargeMediaView: View {
    @ObservedObject var viewModel: StorageManagerViewModel

    private let thresholdsMB: [Int64] = [10, 25, 50, 100]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.photoPermission.canAccessPhotos {
                    VStack(spacing: 12) {
                        Text("Vui lòng cấp quyền Thư viện Ảnh để quét video và ảnh dung lượng lớn.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Button("Cấp quyền truy cập") {
                            Task { await viewModel.requestPhotosAccess() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .premiumCard(cornerRadius: 20, padding: 20)
                } else {
                    filterHeader

                    if viewModel.isScanningMedia {
                        ProgressView(value: viewModel.scanProgress) {
                            Text("Đang kiểm tra dung lượng từng tệp media...")
                                .font(.caption)
                        }
                        .premiumCard(cornerRadius: 18, padding: 16)
                    } else if viewModel.largeMediaItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "film.stack")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.optimalGreen)
                            Text("Không có ảnh/video nào lớn hơn \(viewModel.largeMediaThresholdMB) MB")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .premiumCard(cornerRadius: 20, padding: 24)
                    } else {
                        ForEach(viewModel.largeMediaItems) { item in
                            mediaRow(item)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Media dung lượng lớn")
        .safeAreaInset(edge: .bottom) {
            if !viewModel.selectedLargeMedia.isEmpty {
                deleteBar
            }
        }
        .confirmationDialog(
            "Xóa \(viewModel.selectedLargeMedia.count) tệp media đã chọn?",
            isPresented: $viewModel.showDeleteMediaConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa \(ByteFormatterUtil.formatFileSize(viewModel.selectedLargeMediaBytes))", role: .destructive) {
                Task { await viewModel.deleteConfirmedLargeMedia() }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Thao tác cần xác nhận từ hệ thống iOS và sẽ chuyển ảnh/video vào mục Đã xóa gần đây.")
        }
        .task {
            if viewModel.photoPermission.canAccessPhotos && viewModel.largeMediaItems.isEmpty {
                await viewModel.scanLargeMedia()
            }
        }
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ngưỡng dung lượng tối thiểu")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button("Quét lại") {
                    Task { await viewModel.scanLargeMedia() }
                }
                .font(.caption.weight(.bold))
            }

            Picker("Ngưỡng", selection: $viewModel.largeMediaThresholdMB) {
                ForEach(thresholdsMB, id: \.self) { mb in
                    Text("> \(mb) MB").tag(mb)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.largeMediaThresholdMB) { _ in
                Task { await viewModel.scanLargeMedia() }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 14)
    }

    private func mediaRow(_ item: MediaAssetItem) -> some View {
        Button {
            viewModel.toggleLargeMediaSelection(id: item.id)
        } label: {
            HStack(spacing: 12) {
                PHAssetThumbnailView(
                    asset: item.asset,
                    photoService: viewModel.photoService,
                    size: CGSize(width: 64, height: 64)
                )
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: item.isVideo ? "video.fill" : "photo.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text(item.isVideo ? "Video (\(ByteFormatterUtil.formatMediaDuration(item.duration)))" : "Ảnh độ phân giải cao")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    Text("\(item.resolutionLabel) • \(ByteFormatterUtil.formatFileSize(item.fileSizeBytes))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.criticalRed)
                    if let date = item.creationDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isSelected ? AppTheme.criticalRed : .secondary)
            }
            .premiumCard(cornerRadius: 16, padding: 12)
        }
        .buttonStyle(.plain)
    }

    private var deleteBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã chọn \(viewModel.selectedLargeMedia.count) mục")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedLargeMediaBytes))
                    .font(.headline.weight(.bold))
            }
            Spacer()
            Button {
                viewModel.showDeleteMediaConfirmation = true
            } label: {
                Text("Xác nhận xóa")
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
