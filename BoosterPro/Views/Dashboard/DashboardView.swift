import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var selectedTab: MainTabView.Tab

    @State private var showSmartScanSheet = false
    @State private var navigateToDeviceBooster = false
    @State private var showIntroSheet = false
    @State private var showAutoCleanSettingsSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroStatusCard
                    smartScanCTAButton
                    autoCleanBanner
                    gameBoosterBanner
                    storageOverviewCard
                    quickActionsGrid
                    deviceHealthBanner
                    creatorFooterCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Booster Pro")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showIntroSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("Giới thiệu ứng dụng")

                        Button {
                            showAutoCleanSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.2.fill")
                                .foregroundColor(AppTheme.primaryAccent)
                        }
                        .accessibilityLabel("Cài đặt Auto Clean")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refreshDashboard() }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .accessibilityLabel("Làm mới thông số")
                }
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .task {
                await viewModel.refreshDashboard()
            }
            .sheet(isPresented: $showIntroSheet) {
                OnboardingIntroView {
                    showIntroSheet = false
                }
            }
            .sheet(isPresented: $showAutoCleanSettingsSheet) {
                AutoCleanSettingsView()
            }
            .sheet(isPresented: $showSmartScanSheet, onDismiss: {
                Task { await viewModel.refreshDashboard() }
            }) {
                SmartScanView()
            }
            .navigationDestination(isPresented: $navigateToDeviceBooster) {
                DeviceBoosterView()
            }
        }
    }

    private var heroStatusCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                CircularProgressRing(
                    progress: viewModel.optimizationScore,
                    title: "Điểm tối ưu",
                    subtitle: viewModel.cpuMetrics.thermalStateTitle,
                    lineWidth: 14,
                    size: 136
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tình trạng thiết bị")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.deviceStatusSummary)
                        .font(.headline.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    HStack(spacing: 12) {
                        miniStat(
                            label: "RAM trống/còn",
                            value: ByteFormatterUtil.formatMemorySize(viewModel.ramSnapshot.reclaimableOrFreeBytes),
                            tint: AppTheme.secondaryAccent
                        )
                        miniStat(
                            label: "Cache ứng dụng",
                            value: ByteFormatterUtil.formatFileSize(viewModel.appCacheBytes),
                            tint: AppTheme.warningAmber
                        )
                    }
                }
            }

            HStack {
                Label(viewModel.lastUpdatedText, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Label(
                    "CPU App: \(String(format: "%.1f%%", viewModel.cpuMetrics.appCPUUsagePercent))",
                    systemImage: "cpu"
                )
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .premiumCard(cornerRadius: 22, padding: 18)
    }

    private func miniStat(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
        }
    }

    private var smartScanCTAButton: some View {
        Button {
            showSmartScanSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Scan")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Quét toàn diện file rác, cache, RAM & hiệu năng")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(AppTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.primaryAccent.opacity(0.28), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var storageOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StorageBarChart(storage: viewModel.storageInfo)

            Divider()

            HStack {
                Label(
                    "Khả dụng (Quan trọng): \(ByteFormatterUtil.formatFileSize(viewModel.storageInfo.importantAvailableBytes))",
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .premiumCard(cornerRadius: 20, padding: 16)
    }

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Công cụ tối ưu")
                .font(.headline.weight(.bold))
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                Button {
                    selectedTab = .junk
                } label: {
                    MetricCardView(
                        title: "Clean Junk",
                        value: ByteFormatterUtil.formatFileSize(viewModel.junkBytes),
                        subtitle: "Tệp tạm & log trong sandbox",
                        iconName: "trash.slash.fill",
                        tint: AppTheme.criticalRed
                    )
                }
                .buttonStyle(.plain)

                Button {
                    selectedTab = .ram
                } label: {
                    MetricCardView(
                        title: "RAM Cleaner",
                        value: ByteFormatterUtil.formatMemorySize(viewModel.ramSnapshot.appFootprintBytes),
                        subtitle: "Khả dụng: \(ByteFormatterUtil.formatMemorySize(viewModel.ramSnapshot.procAvailableBytes))",
                        iconName: "memorychip.fill",
                        tint: AppTheme.secondaryAccent
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CacheCleanerView()
                } label: {
                    MetricCardView(
                        title: "Cache Cleaner",
                        value: ByteFormatterUtil.formatFileSize(viewModel.appCacheBytes),
                        subtitle: "An toàn, giữ nguyên đăng nhập",
                        iconName: "tray.full.fill",
                        tint: AppTheme.warningAmber
                    )
                }
                .buttonStyle(.plain)

                Button {
                    selectedTab = .storage
                } label: {
                    MetricCardView(
                        title: "Storage Manager",
                        value: ByteFormatterUtil.formatFileSize(viewModel.storageInfo.availableBytes),
                        subtitle: "Ảnh trùng, video lớn & Files",
                        iconName: "externaldrive.fill",
                        tint: AppTheme.primaryAccent
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var autoCleanBanner: some View {
        Button {
            showAutoCleanSettingsSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#00F5A0"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#00F5A0").opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Auto Clean Settings")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("TỰ ĐỘNG")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: "#00F5A0"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#00F5A0").opacity(0.18))
                            .clipShape(Capsule())
                    }
                    Text("Lập lịch dọn rác, cache & tối ưu tự động theo tần suất")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .premiumCard(cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var gameBoosterBanner: some View {
        Button {
            selectedTab = .gameBooster
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(GamingTheme.neonGreen)
                    .frame(width: 44, height: 44)
                    .background(GamingTheme.neonGreen.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Game Booster")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("MỚI")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(GamingTheme.neonGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GamingTheme.neonGreen.opacity(0.18))
                            .clipShape(Capsule())
                    }
                    Text("Smart Game Manager, Kiểm tra cập nhật & Auto Clean sau trận")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .premiumCard(cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var deviceHealthBanner: some View {
        Button {
            navigateToDeviceBooster = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bolt.shield.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.optimalGreen)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.optimalGreen.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Device Booster & Phân tích hiệu năng")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Nhiệt độ: \(viewModel.cpuMetrics.thermalStateTitle) • Uptime: \(ByteFormatterUtil.formatDuration(viewModel.cpuMetrics.systemUptimeSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .premiumCard(cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var creatorFooterCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.10, green: 0.50, blue: 0.98), Color(red: 0.08, green: 0.72, blue: 0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.28), radius: 6, x: 0, y: 3)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(DeveloperInfo.appCreatedBy)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Nhà phát triển Booster Pro")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Link(destination: URL(string: DeveloperInfo.facebookURL)!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link.circle.fill")
                            .font(.caption.bold())
                        Text("Facebook")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.09, green: 0.45, blue: 0.95), Color(red: 0.05, green: 0.35, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .premiumCard(cornerRadius: 18, padding: 14)
    }
}
