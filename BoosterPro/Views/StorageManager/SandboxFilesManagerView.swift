import SwiftUI
import UniformTypeIdentifiers

struct SandboxFilesManagerView: View {
    @ObservedObject var viewModel: StorageManagerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                pickerHeaderCard

                if viewModel.managedFiles.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "folder.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("Chưa có tệp nào được chọn")
                            .font(.headline)
                        Text("Sử dụng nút \"Chọn tệp từ Tệp (Files)\" để nhập và kiểm tra dung lượng tài liệu trong ứng dụng Tệp.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .premiumCard(cornerRadius: 20, padding: 24)
                } else {
                    ForEach(viewModel.managedFiles) { file in
                        Button {
                            viewModel.toggleManagedFileSelection(id: file.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(file.isSelected ? AppTheme.criticalRed : .secondary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(file.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("\(file.contentTypeDescription) • \(file.modificationDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(ByteFormatterUtil.formatFileSize(file.sizeBytes))
                                    .font(.caption.weight(.bold))
                            }
                            .premiumCard(cornerRadius: 16, padding: 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Quản lý tệp (Files)")
        .safeAreaInset(edge: .bottom) {
            if !viewModel.selectedManagedFiles.isEmpty {
                deleteFooter
            }
        }
        .confirmationDialog(
            "Xóa \(viewModel.selectedManagedFiles.count) tệp đã chọn?",
            isPresented: $viewModel.showDeleteFilesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa \(ByteFormatterUtil.formatFileSize(viewModel.selectedManagedFilesBytes))", role: .destructive) {
                viewModel.deleteSelectedManagedFiles()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Chỉ xóa bản sao đang quản lý trong thư mục ManagedFiles của Booster Pro.")
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            viewModel.handlePickedFiles(result: result)
        }
    }

    private var pickerHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tích hợp iOS Files Picker")
                .font(.subheadline.weight(.bold))
            Text("iOS yêu cầu người dùng chủ động chọn tệp từ ứng dụng Tệp (iCloud Drive / Trên iPhone) để đảm bảo quyền riêng tư.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                viewModel.showFileImporter = true
            } label: {
                Label("Chọn tệp từ Tệp (Files)", systemImage: "doc.badge.plus")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primaryAccent)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var deleteFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã chọn \(viewModel.selectedManagedFiles.count) tệp")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedManagedFilesBytes))
                    .font(.headline.weight(.bold))
            }
            Spacer()
            Button {
                viewModel.showDeleteFilesConfirmation = true
            } label: {
                Text("Xóa tệp")
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
