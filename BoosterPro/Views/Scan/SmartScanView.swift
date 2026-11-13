import SwiftUI

struct SmartScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SmartScanViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let report = viewModel.finalReport, viewModel.phase == .cleaned {
                        ScanResultView(report: report) {
                            dismiss()
                        }
                    } else {
                        radarHeader
                        StatusStateBanner(phase: viewModel.phase) {
                            Task { await viewModel.startSmartScan() }
                        }
                        stagesList
                        if viewModel.phase == .completed {
                            selectionCard
                            cleanButton
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Smart Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .disabled(viewModel.phase.isBusy)
                }
            }
            .task {
                if viewModel.phase == .idle {
                    await viewModel.startSmartScan()
                }
            }
        }
    }

    private var radarHeader: some View {
        VStack(spacing: 8) {
            RadarScanAnimationView(
                isScanning: viewModel.phase.isBusy,
                progress: viewModel.overallProgress
            )
            if viewModel.phase == .completed {
                Text("Có thể giải phóng ngay \(ByteFormatterUtil.formatFileSize(viewModel.selectedReclaimableDiskBytes))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard(cornerRadius: 22, padding: 16)
    }

    private var stagesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chi tiết phân tích theo thời gian thực")
                .font(.subheadline.weight(.bold))

            ForEach(viewModel.stages) { stage in
                HStack(spacing: 12) {
                    Image(systemName: stage.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(stage.isCompleted ? AppTheme.optimalGreen : AppTheme.primaryAccent)
                        .frame(width: 34, height: 34)
                        .background((stage.isCompleted ? AppTheme.optimalGreen : AppTheme.primaryAccent).opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.title)
                            .font(.subheadline.weight(.semibold))
                        Text(stage.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if stage.isCompleted {
                        VStack(alignment: .trailing, spacing: 2) {
                            if stage.foundBytes > 0 {
                                Text(ByteFormatterUtil.formatFileSize(stage.foundBytes))
                                    .font(.caption.weight(.bold))
                            }
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.optimalGreen)
                                .font(.caption)
                        }
                    } else if viewModel.phase.isBusy {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chọn hạng mục muốn dọn dẹp")
                .font(.subheadline.weight(.bold))

            Toggle(isOn: $viewModel.includeJunkCleanup) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dọn file rác & tệp tạm sandbox")
                        .font(.subheadline.weight(.medium))
                    Text("\(viewModel.junkItems.filter(\.isSelected).count) mục • \(ByteFormatterUtil.formatFileSize(viewModel.junkItems.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(isOn: $viewModel.includeCacheCleanup) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Xóa bộ nhớ đệm an toàn")
                        .font(.subheadline.weight(.medium))
                    let cacheBytes = viewModel.cachePartitions.filter { $0.isDeletable && $0.isSelected }.reduce(Int64(0)) { $0 + $1.sizeBytes }
                    Text("Dung lượng: \(ByteFormatterUtil.formatFileSize(cacheBytes)) (Giữ nguyên cài đặt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(isOn: $viewModel.includeMemoryOptimization) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tối ưu bộ nhớ RAM nội bộ ứng dụng")
                        .font(.subheadline.weight(.medium))
                    Text("Giải phóng NSCache & URLCache đang chiếm \(ByteFormatterUtil.formatMemorySize(viewModel.ramSnapshot.appFootprintBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(AppTheme.primaryAccent)
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var cleanButton: some View {
        Button {
            Task { await viewModel.executeSelectedCleanup() }
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Thực hiện dọn dẹp an toàn")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.heroGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!viewModel.includeJunkCleanup && !viewModel.includeCacheCleanup && !viewModel.includeMemoryOptimization)
    }
}
