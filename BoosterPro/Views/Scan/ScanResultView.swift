import SwiftUI

struct ScanResultView: View {
    let report: ComprehensiveScanReport
    let onDone: () -> Void

    @State private var animateCheckmark = false

    var body: some View {
        VStack(spacing: 18) {
            celebrationHeader
            metricsSummaryCard
            beforeAfterCard

            Button(action: onDone) {
                Text("Hoàn tất")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.optimalGreen)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                animateCheckmark = true
            }
        }
    }

    private var celebrationHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.optimalGreen.opacity(0.16))
                    .frame(width: 96, height: 96)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.6)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.optimalGreen)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.4)
            }

            Text("Dọn dẹp hoàn tất!")
                .font(.title2.weight(.bold))

            Text("Đã giải phóng thực tế \(ByteFormatterUtil.formatFileSize(report.totalCombinedFreedBytes))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.optimalGreen)
        }
        .frame(maxWidth: .infinity)
        .premiumCard(cornerRadius: 22, padding: 20)
    }

    private var metricsSummaryCard: some View {
        VStack(spacing: 12) {
            resultRow(
                label: "Dung lượng phát hiện có thể dọn",
                value: ByteFormatterUtil.formatFileSize(report.totalReclaimableBytesFound)
            )
            Divider()
            resultRow(
                label: "Tổng số mục/phân vùng đã xử lý",
                value: "\(report.totalFilesProcessed) mục"
            )
            Divider()
            resultRow(
                label: "Dung lượng ổ đĩa đã giải phóng",
                value: ByteFormatterUtil.formatFileSize(report.actualFreedDiskBytes)
            )
            Divider()
            resultRow(
                label: "RAM nội bộ đã thu hồi",
                value: ByteFormatterUtil.formatMemorySize(max(0, report.actualReclaimedRAMBytes))
            )
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var beforeAfterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("So sánh Trước & Sau khi dọn")
                .font(.subheadline.weight(.bold))

            HStack(spacing: 12) {
                comparisonBox(
                    title: "Trước khi dọn",
                    storageText: ByteFormatterUtil.formatFileSize(report.beforeStorageAvailableBytes),
                    ramText: ByteFormatterUtil.formatMemorySize(report.beforeAppFootprintBytes),
                    tint: AppTheme.warningAmber
                )

                comparisonBox(
                    title: "Sau khi dọn",
                    storageText: ByteFormatterUtil.formatFileSize(report.afterStorageAvailableBytes),
                    ramText: ByteFormatterUtil.formatMemorySize(report.afterAppFootprintBytes),
                    tint: AppTheme.optimalGreen
                )
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func comparisonBox(title: String, storageText: String, ramText: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text("Trống: \(storageText)")
                .font(.caption)
            Text("App RAM: \(ramText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
        }
    }
}
