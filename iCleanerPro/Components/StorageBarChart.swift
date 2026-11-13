import SwiftUI

/// Visualizes real device storage distribution (System & Other Used, App Sandbox, Available).
struct StorageBarChart: View {
    let storage: DeviceStorageInfo

    private var otherUsedBytes: Int64 {
        max(0, storage.usedBytes - storage.appSandboxUsedBytes)
    }

    private var total: Double {
        Double(max(1, storage.totalBytes))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dung lượng thiết bị")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(ByteFormatterUtil.formatFileSize(storage.usedBytes)) / \(ByteFormatterUtil.formatFileSize(storage.totalBytes))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let otherRatio = CGFloat(Double(otherUsedBytes) / total)
                let sandboxRatio = CGFloat(Double(storage.appSandboxUsedBytes) / total)

                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.primaryAccent)
                        .frame(width: max(4, width * otherRatio))

                    if storage.appSandboxUsedBytes > 0 {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(AppTheme.warningAmber)
                            .frame(width: max(4, width * sandboxRatio))
                    }

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }
                .animation(.easeInOut(duration: 0.45), value: storage.usedBytes)
            }
            .frame(height: 14)

            HStack(spacing: 16) {
                legendDot(color: AppTheme.primaryAccent, label: "Hệ thống & App khác", value: ByteFormatterUtil.formatFileSize(otherUsedBytes))
                legendDot(color: AppTheme.warningAmber, label: "iCleaner Pro", value: ByteFormatterUtil.formatFileSize(storage.appSandboxUsedBytes))
                legendDot(color: Color.secondary.opacity(0.4), label: "Còn trống", value: ByteFormatterUtil.formatFileSize(storage.availableBytes))
            }
            .font(.caption2)
        }
    }

    private func legendDot(color: Color, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(value)
                .font(.caption.weight(.semibold))
        }
    }
}
