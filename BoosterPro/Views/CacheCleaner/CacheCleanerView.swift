import SwiftUI

/// Ultimate Cyberpunk Neon + Liquid Glass App Cache Cleaner for Booster Pro.
/// Features granular multi-category scanning, safe/sensitive classification,
/// verified before/after telemetry, WebView manager, and Other Apps Storage Guide.
struct CacheCleanerView: View {
    @StateObject private var viewModel = CacheCleanerViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Hero Overview Card
                heroOverviewCard

                // 2. Before / After Comparison Banner (Shown after cleaning)
                if let result = viewModel.lastResult {
                    beforeAfterComparisonCard(result)
                }

                // 3. Quick Action Buttons Row
                quickActionsRow

                // 4. Two-Zone Architecture & Other Apps Guide Banner
                otherAppsGuideBanner

                // 5. Filter Chips
                filterChipsRow

                // 6. Cache Categories List
                categoriesSection

                // 7. Protected Data Guarantee Section
                protectedDataCard

                // 8. Scope & Technology Disclosure
                scopeDisclaimer
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Dọn bộ nhớ đệm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.showHistorySheet = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color(hex: "#00F5A0"))
                    }
                    .accessibilityLabel("Lịch sử dọn cache")

                    Button {
                        viewModel.showOtherAppsGuideSheet = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(AppTheme.primaryAccent)
                    }
                    .accessibilityLabel("Hướng dẫn dọn cache app khác")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.selectedCleanableBytes > 0 {
                bottomCleanBar
            }
        }
        .sheet(isPresented: $viewModel.showOtherAppsGuideSheet) {
            OtherAppsCacheGuideView()
        }
        .sheet(isPresented: $viewModel.showWebViewSheet) {
            WebViewDataSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showHistorySheet) {
            CacheHistorySheetView(viewModel: viewModel)
        }
        .confirmationDialog(
            "Xóa bộ nhớ đệm đã chọn?",
            isPresented: $viewModel.showConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("Xóa \(ByteFormatterUtil.formatFileSize(viewModel.selectedCleanableBytes))", role: .destructive) {
                HapticManager.impact(style: .medium)
                Task { await viewModel.cleanSelectedCaches() }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text(confirmationMessageText)
        }
        .onAppear {
            if viewModel.partitions.isEmpty {
                viewModel.scanCaches()
            }
        }
    }

    // MARK: - 1. Hero Overview Card
    private var heroOverviewCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                        .frame(width: 96, height: 96)

                    Circle()
                        .trim(from: 0, to: viewModel.totalCleanableBytes > 0 ? 0.75 : 0.05)
                        .stroke(
                            LinearGradient(
                                colors: [GamingTheme.neonOrange, GamingTheme.neonPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: viewModel.totalCleanableBytes)

                    VStack(spacing: 2) {
                        Image(systemName: "tray.full.fill")
                            .font(.title3)
                            .foregroundStyle(GamingTheme.neonOrange)
                        Text("\(viewModel.deletablePartitions.count) mục")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("TỔNG CACHE ỨNG DỤNG")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text(ByteFormatterUtil.formatFileSize(viewModel.totalCleanableBytes))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.warningAmber)

                    Text("\(viewModel.totalFileCount) tệp rác & bản ghi đệm")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button {
                            viewModel.scanCaches()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .rotationEffect(.degrees(viewModel.isScanning ? 360 : 0))
                                    .animation(
                                        viewModel.isScanning && !reduceMotion
                                            ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                            : .default,
                                        value: viewModel.isScanning
                                    )
                                Text("Quét lại")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primaryAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.primaryAccent.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Button {
                            viewModel.showWebViewSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                Text("WebView (\(viewModel.webViewRecords.count))")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#00F5A0"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#00F5A0").opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
            }

            if viewModel.safeCleanableBytes > 0 {
                Divider()

                Button {
                    HapticManager.impact(style: .medium)
                    Task { await viewModel.cleanAllSafeCaches() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("DỌN TOÀN BỘ CACHE AN TOÀN (\(ByteFormatterUtil.formatFileSize(viewModel.safeCleanableBytes)))")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#00F5A0"), Color(hex: "#00D9F5")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#00F5A0").opacity(0.25), radius: 8, x: 0, y: 3)
                }
                .disabled(viewModel.isCleaning)
            }
        }
        .liquidGlassCard(glowColor: AppTheme.warningAmber.opacity(0.2), cornerRadius: 22, padding: 18)
    }

    // MARK: - 2. Before / After Comparison Banner
    private func beforeAfterComparisonCard(_ result: CacheCleanupResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#00F5A0"))
                    Text("KẾT QUẢ ĐO LƯỜNG THỰC TẾ")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(hex: "#00F5A0"))
                }
                Spacer()
                Text(String(format: "%.2fs", result.cleanupDurationSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 12) {
                metricCell(
                    title: "Trước khi dọn",
                    value: ByteFormatterUtil.formatFileSize(result.beforeCleanableBytes),
                    color: .secondary
                )
                metricCell(
                    title: "Đã giải phóng",
                    value: ByteFormatterUtil.formatFileSize(result.freedBytes),
                    color: Color(hex: "#00F5A0"),
                    isBold: true
                )
                metricCell(
                    title: "Cache còn lại",
                    value: ByteFormatterUtil.formatFileSize(result.afterCleanableBytes),
                    color: .secondary
                )
            }

            HStack(spacing: 12) {
                Text("• \(result.filesRemovedCount) tệp đã dọn")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if result.failedItemsCount > 0 {
                    Text("• \(result.failedItemsCount) tệp không thể xóa (đang mở)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warningAmber)
                }

                Spacer()

                Text("Đã bảo vệ \(ByteFormatterUtil.formatFileSize(result.protectedBytesUntouched))")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.optimalGreen)
            }
        }
        .padding(16)
        .background(Color(hex: "#00F5A0").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "#00F5A0").opacity(0.3), lineWidth: 1)
        )
    }

    private func metricCell(title: String, value: String, color: Color, isBold: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(isBold ? .subheadline.bold() : .caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 3. Quick Actions Row
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionButton(title: "Dọn tệp tạm", icon: "clock.arrow.circlepath", color: AppTheme.primaryAccent) {
                    Task { await viewModel.cleanTemporaryFiles() }
                }

                quickActionButton(title: "Dọn Cache cũ", icon: "calendar.badge.clock", color: GamingTheme.neonPurple) {
                    Task { await viewModel.cleanOldCaches() }
                }

                quickActionButton(title: "Xóa URLCache", icon: "network", color: GamingTheme.neonCyan) {
                    Task { await viewModel.clearURLCache() }
                }

                quickActionButton(title: "Xóa Image Cache", icon: "photo.stack", color: GamingTheme.neonPink) {
                    Task { await viewModel.clearImageCache() }
                }

                quickActionButton(title: "WebView Cache", icon: "globe", color: Color(hex: "#00F5A0")) {
                    viewModel.showWebViewSheet = true
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - 4. Two-Zone Architecture & Other Apps Guide Banner
    private var otherAppsGuideBanner: some View {
        Button {
            viewModel.showOtherAppsGuideSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "app.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryAccent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.primaryAccent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Dung lượng Ứng dụng khác?")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Text("Hướng dẫn iOS")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primaryAccent)
                            .clipShape(Capsule())
                    }

                    Text("Tìm hiểu cách dọn cache Facebook, TikTok... qua Cài đặt iPhone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .premiumCard(cornerRadius: 18, padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 5. Filter Chips Row
    private var filterChipsRow: some View {
        HStack(spacing: 8) {
            ForEach(CacheFilterOption.allCases) { opt in
                Button {
                    HapticManager.selection()
                    viewModel.selectedFilter = opt
                } label: {
                    Text(opt.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.selectedFilter == opt ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedFilter == opt
                                ? AppTheme.primaryAccent
                                : AppTheme.cardBackground
                        )
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    // MARK: - 6. Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.filteredPartitions) { item in
                partitionRowCard(item)
            }
        }
    }

    private func partitionRowCard(_ item: CachePartitionItem) -> some View {
        Button {
            if item.isDeletable {
                HapticManager.selection()
                viewModel.togglePartition(id: item.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if item.isDeletable {
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(item.isSelected ? AppTheme.primaryAccent : .secondary)
                        .padding(.top, 2)
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.optimalGreen)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.type.iconName)
                            .font(.caption.bold())
                            .foregroundStyle(item.isDeletable ? AppTheme.primaryAccent : AppTheme.optimalGreen)

                        Text(item.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(ByteFormatterUtil.formatFileSize(item.sizeBytes))
                            .font(.subheadline.bold())
                            .foregroundStyle(item.isDeletable ? .primary : AppTheme.optimalGreen)
                    }

                    Text(item.protectionReason ?? item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if item.fileCount > 0 {
                            Text("\(item.fileCount) tệp")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let mod = item.lastModifiedDate {
                            Text("Cập nhật: \(formatModDate(mod))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        if item.isSafeToClean {
                            badge(text: "An toàn", color: Color(hex: "#00F5A0"))
                        } else if item.isDeletable && item.requiresExplicitConfirmation {
                            badge(text: "Lưu ý", color: AppTheme.warningAmber)
                        } else if !item.isDeletable {
                            badge(text: "Bảo vệ", color: AppTheme.optimalGreen)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        item.isSelected ? AppTheme.primaryAccent.opacity(0.4) : Color.clear,
                        lineWidth: 1.2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - 7. Protected Data Card
    private var protectedDataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("DỮ LIỆU ĐƯỢC BẢO VỆ TUYỆT ĐỐI", systemImage: "shield.lefthalf.filled")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.optimalGreen)

            Text("Booster Pro không bao giờ xóa hoặc làm hỏng: Cài đặt cá nhân (Preferences), Danh sách game, Tiến trình Auto Clean và Tài liệu người dùng.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)

            HStack {
                Text("Dung lượng được bảo vệ an toàn: ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(ByteFormatterUtil.formatFileSize(viewModel.totalProtectedBytes))
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.optimalGreen)
            }
        }
        .premiumCard(cornerRadius: 18, padding: 14)
    }

    // MARK: - 8. Scope Disclaimer
    private var scopeDisclaimer: some View {
        Text("Lưu ý: Mọi tác vụ phân tích và dọn dẹp đều tuân thủ 100% nguyên tắc Sandbox của Apple. Ứng dụng chỉ xử lý các tài nguyên do chính Booster Pro tạo ra và cung cấp hướng dẫn chính thống để quản lý ứng dụng khác.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.bottom, 60)
    }

    // MARK: - 9. Bottom Floating Clean Bar
    private var bottomCleanBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã chọn dọn dẹp")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatterUtil.formatFileSize(viewModel.selectedCleanableBytes))
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.warningAmber)
            }

            Spacer()

            Button {
                HapticManager.impact(style: .medium)
                viewModel.showConfirmDialog = true
            } label: {
                Text("Xóa Cache")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.warningAmber)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.warningAmber.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var confirmationMessageText: String {
        if viewModel.hasSensitiveSelection {
            return "Bạn đã chọn một số mục nhạy cảm (như Cookies hoặc dữ liệu phiên). Các mục này có thể cần đăng nhập lại. Cài đặt và tài liệu được bảo vệ vẫn được giữ an toàn tuyệt đối."
        } else {
            return "Các ảnh xem trước, tệp tạm và bộ nhớ đệm mạng sẽ được dọn sạch an toàn. Dữ liệu cài đặt và tài liệu cá nhân được giữ nguyên hoàn toàn."
        }
    }

    private func formatModDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM"
        return formatter.string(from: date)
    }
}
