import SwiftUI

/// Main screen for Auto Clean Settings – Automatic Cleanup Scheduler.
/// Meets all requirements of Sections 1, 2, 3, 4, 8, 9, and 10.
struct AutoCleanSettingsView: View {
    @StateObject private var viewModel = AutoCleanSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        statusSummaryCard
                        generalSettingsSection
                        cleaningCategoriesSection
                        smartConditionsSection
                        historySummarySection
                        actionButtonsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // In-flight Cleaning Progress HUD
                if viewModel.isCleaning {
                    cleaningProgressOverlay
                }
            }
            .navigationTitle("Auto Clean Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        viewModel.saveConfiguration()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showHistorySheet) {
                AutoCleanHistoryView(viewModel: viewModel)
            }
            .alert("Khôi phục thiết lập mặc định?", isPresented: $viewModel.showResetConfirmation) {
                Button("Khôi phục", role: .destructive) {
                    viewModel.resetToDefaults()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Mọi tùy chọn tần suất, danh mục và điều kiện dọn dẹp sẽ trở về trạng thái tiêu chuẩn được khuyến nghị.")
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    // MARK: - 1. Status Summary Card
    private var statusSummaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TỰ ĐỘNG DỌN DẸP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Text(viewModel.statusBadgeText)
                        .font(.title2.bold())
                        .foregroundColor(viewModel.statusBadgeColor)
                }

                Spacer()

                Toggle("", isOn: $viewModel.config.isMasterEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "#00F5A0"))
                    .onChange(of: viewModel.config.isMasterEnabled) { _ in
                        viewModel.saveConfiguration()
                    }
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile(
                    title: "Dọn gần nhất",
                    value: viewModel.lastCleanTimeText,
                    icon: "clock.arrow.circlepath"
                )

                statTile(
                    title: "Lịch tiếp theo",
                    value: viewModel.nextScheduledTimeText,
                    icon: "calendar.badge.clock"
                )

                statTile(
                    title: "Đã giải phóng",
                    value: viewModel.totalFreedText,
                    icon: "arrow.down.circle.fill"
                )

                statTile(
                    title: "Số lần thành công",
                    value: "\(viewModel.config.successfulCleansCount) lần",
                    icon: "checkmark.seal.fill"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        )
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primaryAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
    }

    // MARK: - 2. General Settings & Frequency
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "LẬP LỊCH & TẦN SUẤT", icon: "timer")

            VStack(spacing: 12) {
                // Master Schedule Toggle
                Toggle("Bật lập lịch tự động", isOn: $viewModel.config.schedule.isScheduleEnabled)
                    .font(.subheadline.weight(.medium))
                    .tint(AppTheme.primaryAccent)
                    .onChange(of: viewModel.config.schedule.isScheduleEnabled) { _ in
                        viewModel.saveConfiguration()
                    }

                if viewModel.config.schedule.isScheduleEnabled {
                    Divider()

                    // Frequency Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tần suất dọn dẹp")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Tần suất", selection: $viewModel.config.schedule.frequency) {
                            ForEach(AutoCleanFrequency.allCases) { freq in
                                Label(freq.displayName, systemImage: freq.icon).tag(freq)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)
                        .onChange(of: viewModel.config.schedule.frequency) { _ in
                            viewModel.saveConfiguration()
                        }

                        Text(viewModel.config.schedule.frequency.detailDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Time Selection for Daily & Weekly
                    if viewModel.config.schedule.frequency == .daily || viewModel.config.schedule.frequency == .weekly {
                        Divider()

                        HStack {
                            Text("Giờ bắt đầu chạy")
                                .font(.subheadline)
                            Spacer()
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                        components.hour = viewModel.config.schedule.startHour
                                        components.minute = viewModel.config.schedule.startMinute
                                        return Calendar.current.date(from: components) ?? Date()
                                    },
                                    set: { newDate in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                        viewModel.config.schedule.startHour = components.hour ?? 2
                                        viewModel.config.schedule.startMinute = components.minute ?? 0
                                        viewModel.saveConfiguration()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }

                    // Day of Week Picker for Weekly
                    if viewModel.config.schedule.frequency == .weekly {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chọn ngày trong tuần")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                ForEach([
                                    (1, "CN"), (2, "T2"), (3, "T3"),
                                    (4, "T4"), (5, "T5"), (6, "T6"), (7, "T7")
                                ], id: \.0) { day, name in
                                    let isSelected = viewModel.config.schedule.selectedDaysOfWeek.contains(day)
                                    Button {
                                        viewModel.toggleDayOfWeek(day)
                                    } label: {
                                        Text(name)
                                            .font(.caption.bold())
                                            .foregroundColor(isSelected ? .black : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color(hex: "#00F5A0") : Color.secondary.opacity(0.15))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }

                // Apple Background Execution Transparency Notice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("Lưu ý hệ điều hành iOS: Lịch chạy nền là lịch yêu cầu thực hiện. Hệ thống Apple tự quyết định thời điểm thực tế dựa trên điều kiện pin và trạng thái rảnh của thiết bị.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    // MARK: - 3. Cleaning Options (Categories)
    private var cleaningCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "LOẠI DỮ LIỆU ĐƯỢC PHÉP DỌN", icon: "folder.badge.minus")

            VStack(spacing: 12) {
                categoryToggle(
                    title: "Auto Clean Junk Files",
                    subtitle: "Tệp rác phát sinh trong sandbox của ứng dụng.",
                    isOn: $viewModel.config.dataOptions.cleanJunkFiles
                )

                Divider()

                categoryToggle(
                    title: "Auto Clean Temporary Files",
                    subtitle: "Tệp trung gian trong thư mục tmp/ của ứng dụng.",
                    isOn: $viewModel.config.dataOptions.cleanTemporaryFiles
                )

                Divider()

                categoryToggle(
                    title: "Auto Clean Application Cache",
                    subtitle: "Bộ nhớ đệm hình ảnh thu nhỏ và dữ liệu tải tạm.",
                    isOn: $viewModel.config.dataOptions.cleanAppCache
                )

                Divider()

                categoryToggle(
                    title: "Auto Clean Application Logs",
                    subtitle: "Nhật ký chẩn đoán cũ trong Library/Logs của ứng dụng.",
                    isOn: $viewModel.config.dataOptions.cleanAppLogs
                )

                Divider()

                categoryToggle(
                    title: "Auto Release App-Owned Memory",
                    subtitle: "Giải phóng bộ nhớ URLCache và NSCache nội bộ của ứng dụng.",
                    isOn: $viewModel.config.dataOptions.cleanAppMemory
                )

                Divider()

                categoryToggle(
                    title: "Auto Optimize Game Resources",
                    subtitle: "Dọn dẹp ảnh chụp thông số và tài nguyên đệm Game Booster.",
                    isOn: $viewModel.config.dataOptions.cleanGameResources
                )

                // Safety Guarantee Callout Box
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield.checkmark.fill")
                        .foregroundColor(Color(hex: "#00F5A0"))
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cam kết an toàn tuyệt đối")
                            .font(.caption.bold())
                            .foregroundColor(.primary)

                        Text("Booster Pro KHÔNG BAO GIỜ xóa Documents, dữ liệu đăng nhập, ảnh/video trong Thư viện, hay file lưu game của bạn. Chỉ dọn dữ liệu tạm do Booster Pro tự quản lý.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#00F5A0").opacity(0.1))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    private func categoryToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .tint(Color(hex: "#00F5A0"))
        .onChange(of: isOn.wrappedValue) { _ in
            viewModel.saveConfiguration()
        }
    }

    // MARK: - 4. Smart Conditions
    private var smartConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "ĐIỀU KIỆN TỰ ĐỘNG DỌN", icon: "shield.lefthalf.filled")

            VStack(spacing: 12) {
                categoryToggle(
                    title: "Chỉ dọn khi thiết bị đang sạc",
                    subtitle: "Đảm bảo chỉ thực hiện khi pin đang nạp để tiết kiệm năng lượng.",
                    isOn: $viewModel.config.conditions.chargingOnly
                )

                Divider()

                categoryToggle(
                    title: "Bảo vệ khi pin thấp (< 20%)",
                    subtitle: "Tự động tạm dừng quá trình dọn nếu máy sắp hết pin và không cắm sạc.",
                    isOn: $viewModel.config.conditions.lowBatteryProtection
                )

                Divider()

                categoryToggle(
                    title: "Bảo vệ khi nhiệt độ cao (Critical)",
                    subtitle: "Tạm ngưng dọn dẹp khi hệ thống ở trạng thái nhiệt nghiêm trọng.",
                    isOn: $viewModel.config.conditions.thermalProtection
                )

                Divider()

                categoryToggle(
                    title: "Chỉ dọn khi ứng dụng đang mở",
                    subtitle: "Không kích hoạt tác vụ chạy ngầm khi đóng ứng dụng.",
                    isOn: $viewModel.config.conditions.activeAppOnly
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    // MARK: - 5. History Summary
    private var historySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "NHẬT KÝ HOẠT ĐỘNG", icon: "clock.arrow.circlepath")

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lịch sử dọn dẹp")
                            .font(.subheadline.weight(.medium))
                        Text("\(viewModel.history.count) phiên đã ghi nhận")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        viewModel.showHistorySheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Xem chi tiết")
                                .font(.caption.bold())
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundColor(AppTheme.primaryAccent)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    // MARK: - 6. Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Clean Now Button
            Button {
                viewModel.cleanNow()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.headline)
                    Text("CLEAN NOW")
                        .font(.headline.bold())
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#00F5A0"), Color(hex: "#00D9F5")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color(hex: "#00F5A0").opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isCleaning || !viewModel.config.isMasterEnabled)

            // Reset Settings Button
            Button {
                viewModel.showResetConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                    Text("RESET SETTINGS")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .padding(.top, 8)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(AppTheme.primaryAccent)
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
    }

    // MARK: - In-flight Cleaning Progress HUD
    private var cleaningProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 18) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(Color(hex: "#00F5A0"))

                Text("Đang thực hiện Auto Clean")
                    .font(.headline.bold())
                    .foregroundColor(.white)

                Text(viewModel.cleaningProgressStep)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#00F5A0"), Color(hex: "#00D9F5")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(viewModel.activeProgressRatio), height: 8)
                            .animation(.linear(duration: 0.25), value: viewModel.activeProgressRatio)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 24)

                Button {
                    viewModel.cancelCleaning()
                } label: {
                    Text("Hủy dọn dẹp")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.85))
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1A2234"))
                    .shadow(radius: 16)
            )
            .frame(maxWidth: 320)
        }
    }
}
