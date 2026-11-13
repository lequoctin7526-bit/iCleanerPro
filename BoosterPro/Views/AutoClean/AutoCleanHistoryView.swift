import SwiftUI

/// Displays persistent history of all automated and manual cleanup passes.
struct AutoCleanHistoryView: View {
    @ObservedObject var viewModel: AutoCleanSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRecord: AutoCleanHistoryRecord? = nil
    @State private var showClearConfirm: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.history.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Lịch sử dọn dẹp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.history.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Xác nhận xóa toàn bộ lịch sử?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Xóa tất cả", role: .destructive) {
                    viewModel.clearHistory()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Hành động này sẽ xóa vĩnh viễn nhật ký các phiên dọn dẹp trước đây.")
            }
            .sheet(item: $selectedRecord) { record in
                HistoryDetailSheet(record: record)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 54))
                .foregroundColor(.secondary.opacity(0.6))

            Text("Chưa có lịch sử dọn dẹp")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Các phiên tự động dọn dẹp hoặc dọn thủ công sẽ được ghi lại chi tiết tại đây.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var historyListView: some View {
        List {
            ForEach(viewModel.history) { record in
                Button {
                    selectedRecord = record
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(record.wasSuccessful ? Color(hex: "#00F5A0") : Color.orange)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.triggerReason)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(formatDate(record.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Text(record.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            if record.bytesFreed > 0 {
                                Text("Đã giải phóng: +\(ByteFormatterUtil.format(record.bytesFreed))")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#00F5A0"))
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm - dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - History Detail Sheet
struct HistoryDetailSheet: View {
    let record: AutoCleanHistoryRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tổng quan phiên dọn dẹp")) {
                    detailRow(title: "Thời gian", value: formatFullDate(record.timestamp))
                    detailRow(title: "Nguồn kích hoạt", value: record.triggerReason)
                    detailRow(
                        title: "Trạng thái",
                        value: record.wasSuccessful ? "Thành công" : "Bỏ qua / Thất bại",
                        valueColor: record.wasSuccessful ? Color(hex: "#00F5A0") : .orange
                    )
                    detailRow(title: "Thời lượng", value: String(format: "%.2f giây", record.durationSeconds))
                    detailRow(
                        title: "Dung lượng giải phóng",
                        value: ByteFormatterUtil.format(record.bytesFreed),
                        valueColor: Color(hex: "#00F5A0")
                    )
                }

                if !record.categoriesCleaned.isEmpty {
                    Section(header: Text("Các hạng mục đã dọn")) {
                        ForEach(record.categoriesCleaned, id: \.self) { cat in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#00F5A0"))
                                Text(cat)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }

                if let skip = record.skippedReason {
                    Section(header: Text("Lý do chi tiết")) {
                        Text(skip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Chi tiết phiên dọn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(valueColor)
        }
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm:ss, EEEE dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
