import SwiftUI

/// Historical log sheet displaying past cache cleanup records with timestamps and freed byte metrics.
struct CacheHistorySheetView: View {
    @ObservedObject var viewModel: CacheCleanerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.cacheHistory.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: "#00F5A0"))
                                .padding(.top, 40)
                            Text("Chưa có lịch sử dọn cache")
                                .font(.headline)
                            Text("Các phiên dọn dẹp bộ nhớ đệm sẽ được tự động ghi lại tại đây.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    } else {
                        ForEach(viewModel.cacheHistory) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(record.trigger)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(ByteFormatterUtil.formatFileSize(record.bytesFreed))
                                        .font(.headline.bold())
                                        .foregroundStyle(Color(hex: "#00F5A0"))
                                }

                                HStack(spacing: 8) {
                                    Label("\(record.filesRemoved) tệp", systemImage: "doc")
                                    Label(String(format: "%.1fs", record.durationSeconds), systemImage: "stopwatch")
                                    Spacer()
                                    Text(formatDate(record.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                if !record.cleanedCategories.isEmpty {
                                    Text("Đã dọn: " + record.cleanedCategories.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Lịch sử dọn Cache")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm"
        return formatter.string(from: date)
    }
}
