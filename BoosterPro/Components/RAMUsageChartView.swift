import SwiftUI

/// Interactive segmented RAM breakdown chart displaying Wired, Active, Compressed, Inactive, and Free RAM.
struct RAMUsageChartView: View {
    let snapshot: RAMSnapshot

    private struct Segment: Identifiable {
        let id: String
        let label: String
        let bytes: UInt64
        let color: Color
    }

    private var segments: [Segment] {
        [
            Segment(id: "wired", label: "Wired (Kernel)", bytes: snapshot.wiredBytes, color: AppTheme.criticalRed),
            Segment(id: "active", label: "Đang hoạt động", bytes: snapshot.activeBytes, color: AppTheme.primaryAccent),
            Segment(id: "compressed", label: "Đã nén", bytes: snapshot.compressedBytes, color: AppTheme.violetAccent),
            Segment(id: "inactive", label: "Không hoạt động", bytes: snapshot.inactiveBytes, color: AppTheme.warningAmber),
            Segment(id: "free", label: "Trống", bytes: snapshot.freeBytes, color: AppTheme.optimalGreen)
        ]
    }

    private var sumMeasured: Double {
        let sum = segments.reduce(UInt64(0)) { $0 + $1.bytes }
        return Double(max(1, sum))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phân bổ RAM hệ thống")
                        .font(.subheadline.weight(.semibold))
                    Text("Tổng RAM vật lý: \(ByteFormatterUtil.formatMemorySize(snapshot.totalPhysicalBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(snapshot.pressureLevel.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(pressureColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(pressureColor.opacity(0.14))
                    .clipShape(Capsule())
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(segments) { seg in
                        let ratio = CGFloat(Double(seg.bytes) / sumMeasured)
                        if ratio > 0.01 {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(seg.color)
                                .frame(width: max(4, geo.size.width * ratio - 2))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: snapshot.activeBytes)
            }
            .frame(height: 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                ForEach(segments) { seg in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(seg.color)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(seg.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(ByteFormatterUtil.formatMemorySize(seg.bytes))
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    private var pressureColor: Color {
        switch snapshot.pressureLevel {
        case .normal: return AppTheme.optimalGreen
        case .elevated: return AppTheme.warningAmber
        case .high: return AppTheme.criticalRed
        }
    }
}
