import SwiftUI

struct DeviceBoosterView: View {
    @StateObject private var viewModel = DeviceBoosterViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                cpuAndThermalCard
                optimizeRoutineCard
                slowdownFactorsSection
                iosOptimizationGuideCard
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Tăng tốc thiết bị")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refreshMetrics()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.refreshMetrics()
        }
    }

    private var cpuAndThermalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Giám sát CPU & Trạng thái hệ thống")
                        .font(.subheadline.weight(.bold))
                    Text("Đo từ Mach thread_info & ProcessInfo công khai")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(viewModel.cpuMetrics.thermalStateTitle)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(thermalTint.opacity(0.15))
                    .foregroundStyle(thermalTint)
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricBox(title: "CPU Tiến trình App", value: String(format: "%.1f%%", viewModel.cpuMetrics.appCPUUsagePercent), icon: "cpu")
                metricBox(title: "Luồng hoạt động", value: "\(viewModel.cpuMetrics.activeThreadCount) threads", icon: "point.3.connected.trianglepath.dotted")
                metricBox(title: "Nhân xử lý", value: "\(viewModel.cpuMetrics.activeProcessorCount)/\(viewModel.cpuMetrics.processorCount) cores", icon: "square.grid.2x2")
                metricBox(title: "Pin & Nguồn", value: batteryDisplay, icon: "battery.75")
            }

            HStack {
                Label(
                    viewModel.cpuMetrics.isLowPowerMode ? "Low Power Mode: Đang bật" : "Low Power Mode: Tắt",
                    systemImage: "bolt.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text("Uptime: \(ByteFormatterUtil.formatDuration(viewModel.cpuMetrics.systemUptimeSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var batteryDisplay: String {
        if viewModel.cpuMetrics.batteryLevel < 0 {
            return viewModel.cpuMetrics.batteryStateDescription
        }
        return "\(Int(viewModel.cpuMetrics.batteryLevel * 100))% (\(viewModel.cpuMetrics.batteryStateDescription))"
    }

    private var thermalTint: Color {
        switch viewModel.cpuMetrics.thermalState {
        case .nominal: return AppTheme.optimalGreen
        case .fair: return AppTheme.warningAmber
        case .serious, .critical: return AppTheme.criticalRed
        @unknown default: return AppTheme.primaryAccent
        }
    }

    private func metricBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var optimizeRoutineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quy trình tối ưu hóa an toàn")
                .font(.subheadline.weight(.bold))

            Text("Giải phóng bộ nhớ đệm nội bộ, xóa tệp tạm và thu gọn nhật ký trong phạm vi quyền iOS cho phép — không can thiệp tiến trình hệ thống.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.runSafeOptimization() }
            } label: {
                HStack {
                    if viewModel.isOptimizing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(viewModel.isOptimizing ? "Đang tối ưu..." : "Chạy tối ưu hóa an toàn")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.heroGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(viewModel.isOptimizing)

            if viewModel.hasOptimized {
                ForEach(viewModel.optimizationResults) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.optimalGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.stepName)
                                .font(.caption.weight(.bold))
                            Text(step.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if step.bytesReclaimed > 0 {
                            Text(ByteFormatterUtil.formatFileSize(step.bytesReclaimed))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.optimalGreen)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var slowdownFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yếu tố có thể làm thiết bị chậm (\(viewModel.slowdownFactors.count))")
                .font(.subheadline.weight(.bold))

            if viewModel.slowdownFactors.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(AppTheme.optimalGreen)
                    Text("Không phát hiện yếu tố gây chậm bất thường.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.slowdownFactors) { factor in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(factor.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(factor.severity.rawValue)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(severityColor(factor.severity).opacity(0.14))
                                .foregroundStyle(severityColor(factor.severity))
                                .clipShape(Capsule())
                        }
                        Text(factor.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Khuyến nghị: \(factor.recommendation)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.primaryAccent)
                    }
                    .padding(12)
                    .background(AppTheme.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var iosOptimizationGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hướng dẫn tối ưu iOS thủ công")
                .font(.subheadline.weight(.bold))

            guideRow("1. Giữ dung lượng trống tối thiểu 10–15% để iOS có không gian cho bộ nhớ ảo.")
            guideRow("2. Khởi động lại iPhone định kỳ 1–2 tuần để làm mới hoàn toàn kernel cache.")
            guideRow("3. Tắt Làm mới ứng dụng trong nền đối với các app ít sử dụng.")

            Button {
                viewModel.openSystemSettings()
            } label: {
                Label("Mở Cài đặt iOS", systemImage: "gear")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func guideRow(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func severityColor(_ severity: SlowdownFactor.Severity) -> Color {
        switch severity {
        case .low: return AppTheme.primaryAccent
        case .medium: return AppTheme.warningAmber
        case .high: return AppTheme.criticalRed
        }
    }
}
