import SwiftUI

struct JunkCleanerView: View {
    @StateObject private var viewModel = JunkCleanerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard

                    if let summary = viewModel.lastSummary {
                        cleanupResultBanner(summary)
                    }

                    filterControls

                    if viewModel.phase == .scanningJunk {
                        ProgressView("Đang quét vùng lưu trữ sandbox...")
                            .padding(.vertical, 32)
                    } else if viewModel.filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        junkListSection
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dọn dẹp rác")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task { await viewModel.scan() }
                        } label: {
                            Label("Quét lại", systemImage: "arrow.clockwise")
                        }
                        Button {
                            viewModel.createSampleTempDiagnosticFile()
                            Task { await viewModel.scan() }
                        } label: {
                            Label("Tạo file tạm kiểm thử (512 KB)", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.selectedCount > 0 {
                    cleanActionBar
                }
            }
            .confirmationDialog(
                "Xác nhận xóa \(viewModel.selectedCount) tệp đã chọn?",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Xóa \(ByteFormatterUtil.formatFileSize(viewModel.selectedBytes))", role: .destructive) {
                    Task { await viewModel.cleanSelected() }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Các tệp tạm và bộ nhớ đệm được chọn trong sandbox sẽ bị xóa vĩnh viễn khỏi thiết bị.")
            }
            .task {
                if viewModel.phase == .idle {
                    await viewModel.scan()
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dữ liệu rác phát hiện trong Sandbox")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(ByteFormatterUtil.formatFileSize(viewModel.totalFoundBytes))
                        .font(.title.weight(.bold))
                        .foregroundStyle(viewModel.totalFoundBytes > 0 ? AppTheme.criticalRed : AppTheme.optimalGreen)
                }
                Spacer()
                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Label("Quét", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primaryAccent)
                .disabled(viewModel.phase.isBusy)
            }

            Text("iOS cách ly từng ứng dụng trong Sandbox riêng. Booster Pro chỉ quét và dọn dẹp tệp tạm, log và cache thuộc vùng lưu trữ hợp lệ của ứng dụng.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func cleanupResultBanner(_ summary: JunkCleanupSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.optimalGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã giải phóng \(ByteFormatterUtil.formatFileSize(summary.freedBytes))")
                    .font(.subheadline.weight(.bold))
                Text("Đã xóa \(summary.deletedFilesCount) file • Còn lại \(ByteFormatterUtil.formatFileSize(summary.afterTotalBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.optimalGreen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var filterControls: some View {
        VStack(spacing: 10) {
            Picker("Phân loại", selection: $viewModel.groupingMode) {
                ForEach(JunkCleanerViewModel.GroupingMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button(viewModel.allSelected ? "Bỏ chọn tất cả" : "Chọn tất cả") {
                    viewModel.toggleSelectAll()
                }
                .font(.caption.weight(.semibold))

                Spacer()

                Menu {
                    Button("Tất cả loại") {
                        viewModel.selectedCategoryFilter = nil
                    }
                    ForEach(JunkCategory.allCases) { category in
                        Button(category.title) {
                            viewModel.selectedCategoryFilter = category
                        }
                    }
                } label: {
                    Label(
                        viewModel.selectedCategoryFilter?.title ?? "Lọc theo loại",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                    .font(.caption.weight(.semibold))
                }
            }
        }
    }

    @ViewBuilder
    private var junkListSection: some View {
        if viewModel.groupingMode == .byCategory {
            let grouped = Dictionary(grouping: viewModel.filteredItems, by: \.category)
            ForEach(JunkCategory.allCases) { category in
                if let groupItems = grouped[category], !groupItems.isEmpty {
                    junkGroupCard(
                        title: category.title,
                        subtitle: category.safetyNote,
                        icon: category.iconName,
                        items: groupItems
                    )
                }
            }
        } else {
            let grouped = Dictionary(grouping: viewModel.filteredItems, by: \.sizeTier)
            ForEach(JunkSizeTier.allCases.reversed()) { tier in
                if let groupItems = grouped[tier], !groupItems.isEmpty {
                    junkGroupCard(
                        title: "Nhóm dung lượng \(tier.rawValue)",
                        subtitle: "\(groupItems.count) tệp",
                        icon: "internaldrive",
                        items: groupItems
                    )
                }
            }
        }
    }

    private func junkGroupCard(title: String, subtitle: String, icon: String, items: [JunkItem]) -> some View {
        let groupBytes = items.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(ByteFormatterUtil.formatFileSize(groupBytes))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Divider()

            ForEach(items) { item in
                Button {
                    viewModel.toggleSelection(for: item.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isSelected ? AppTheme.primaryAccent : .secondary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text("\(item.pathDescription) • \(item.sizeTier.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(ByteFormatterUtil.formatFileSize(item.sizeBytes))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .premiumCard(cornerRadius: 18, padding: 14)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.optimalGreen)
            Text("Vùng lưu trữ sạch sẽ")
                .font(.headline)
            Text("Không phát hiện file rác hoặc file tạm dư thừa nào trong sandbox.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .premiumCard(cornerRadius: 20, padding: 18)
    }

    private var cleanActionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã chọn \(viewModel.selectedCount) mục")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedBytes))
                    .font(.headline.weight(.bold))
            }
            Spacer()
            Button {
                viewModel.showDeleteConfirmation = true
            } label: {
                Text("Dọn dẹp ngay")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.criticalRed)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .disabled(viewModel.phase.isBusy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
