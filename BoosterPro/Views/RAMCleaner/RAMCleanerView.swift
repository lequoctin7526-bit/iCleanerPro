import SwiftUI

struct RAMCleanerView: View {
    @StateObject private var viewModel = RAMCleanerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ramRingCard
                    RAMUsageChartView(snapshot: viewModel.snapshot)
                        .premiumCard(cornerRadius: 20, padding: 16)

                    appFootprintCard

                    if let result = viewModel.lastResult {
                        cleanupResultCard(result)
                    }

                    cleanButton
                    transparencyNotice
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dọn RAM")
            .onAppear {
                viewModel.startLiveMonitoring()
            }
            .onDisappear {
                viewModel.stopLiveMonitoring()
            }
        }
    }

    private var ramRingCard: some View {
        HStack(spacing: 18) {
            CircularProgressRing(
                progress: viewModel.snapshot.usedRatio,
                title: "RAM đang dùng",
                subtitle: viewModel.snapshot.pressureLevel.rawValue,
                lineWidth: 14,
                size: 132,
                accentColors: [AppTheme.primaryAccent, AppTheme.violetAccent]
            )

            VStack(alignment: .leading, spacing: 8) {
                ramStatLine("Tổng RAM vật lý", ByteFormatterUtil.formatMemorySize(viewModel.snapshot.totalPhysicalBytes))
                ramStatLine("Đang sử dụng (Active+Wired)", ByteFormatterUtil.formatMemorySize(viewModel.snapshot.usedSystemBytes))
                ramStatLine("Có thể thu hồi / Trống", ByteFormatterUtil.formatMemorySize(viewModel.snapshot.reclaimableOrFreeBytes))
                ramStatLine("Cấp cho App (os_proc)", ByteFormatterUtil.formatMemorySize(viewModel.snapshot.procAvailableBytes))
            }
        }
        .premiumCard(cornerRadius: 22, padding: 16)
    }

    private func ramStatLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
        }
    }

    private var appFootprintCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Bộ nhớ của chính Booster Pro", systemImage: "app.badge.checkmark")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(ByteFormatterUtil.formatMemorySize(viewModel.snapshot.appFootprintBytes))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryAccent)
            }

            Text("Đo chính xác qua `task_info(TASK_VM_INFO).phys_footprint`. Khi tối ưu, ứng dụng sẽ giải phóng NSCache, URLCache và các đối tượng đệm không còn dùng thông qua cơ chế chuẩn của iOS.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private func cleanupResultCard(_ result: RAMCleanupResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.optimalGreen)
                Text("Đã tối ưu bộ nhớ ứng dụng")
                    .font(.subheadline.weight(.bold))
            }

            let deltaText = result.appFootprintDeltaBytes >= 0
                ? "Giảm \(ByteFormatterUtil.formatMemorySize(result.appFootprintDeltaBytes))"
                : "Thay đổi: \(ByteFormatterUtil.formatMemorySize(abs(result.appFootprintDeltaBytes)))"

            Text("App Footprint: \(ByteFormatterUtil.formatMemorySize(result.beforeSnapshot.appFootprintBytes)) → \(ByteFormatterUtil.formatMemorySize(result.afterSnapshot.appFootprintBytes)) (\(deltaText))")
                .font(.caption.weight(.semibold))

            ForEach(result.purgedComponents, id: \.self) { component in
                Text("• Đã giải phóng: \(component)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.optimalGreen.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var cleanButton: some View {
        Button {
            Task { await viewModel.cleanAppMemory() }
        } label: {
            HStack {
                if viewModel.isCleaning {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "memorychip")
                }
                Text(viewModel.isCleaning ? "Đang giải phóng bộ nhớ..." : "Giải phóng bộ nhớ nội bộ")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.heroGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(viewModel.isCleaning)
    }

    private var transparencyNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(AppTheme.primaryAccent)
            Text("Minh bạch kỹ thuật iOS: Hệ điều hành iOS tự quản lý RAM vật lý (Jetsam) và không cho phép ứng dụng bên thứ ba xóa RAM của các ứng dụng khác. Booster Pro hiển thị số liệu thực từ nhân hệ thống và chỉ giải phóng bộ nhớ do chính ứng dụng quản lý.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
