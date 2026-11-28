import SwiftUI
import WebKit

/// Dedicated sheet view for inspecting and selectively managing WebKit cache & website data records.
struct WebViewDataSheetView: View {
    @ObservedObject var viewModel: CacheCleanerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var filterMode: Int = 0 // 0: All, 1: Cache Only, 2: Cookies & Auth
    @State private var showConfirmDeleteCookies = false

    var filteredRecords: [WebViewWebsiteDataRecordItem] {
        switch filterMode {
        case 1:
            return viewModel.webViewRecords.filter(\.isCacheOnly)
        case 2:
            return viewModel.webViewRecords.filter(\.hasCookiesOrAuth)
        default:
            return viewModel.webViewRecords
        }
    }

    var selectedCount: Int {
        viewModel.webViewRecords.filter(\.isSelected).count
    }

    var hasSelectedCookies: Bool {
        viewModel.webViewRecords.contains { $0.isSelected && $0.hasCookiesOrAuth }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pickerHeader
                recordsList
                bottomActionBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Quản lý WebView")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                }
            }
            .confirmationDialog(
                "Xác nhận xóa dữ liệu phiên / Cookies?",
                isPresented: $showConfirmDeleteCookies,
                titleVisibility: .visible
            ) {
                Button("Xác nhận xóa (Mất phiên đăng nhập)", role: .destructive) {
                    Task {
                        await viewModel.deleteSelectedWebViewRecords(types: WKWebsiteDataStore.allWebsiteDataTypes())
                    }
                }
                Button("Chỉ xóa Cache (Giữ Cookies)") {
                    Task {
                        let cacheTypes: Set<String> = [
                            WKWebsiteDataTypeDiskCache,
                            WKWebsiteDataTypeMemoryCache,
                            WKWebsiteDataTypeOfflineWebApplicationCache
                        ]
                        await viewModel.deleteSelectedWebViewRecords(types: cacheTypes)
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn đã chọn các bản ghi chứa Cookies hoặc Dữ liệu phiên. Thao tác này có thể khiến bạn phải đăng nhập lại vào các website tương ứng.")
            }
        }
    }

    private var pickerHeader: some View {
        VStack(spacing: 12) {
            Picker("Bộ lọc", selection: $filterMode) {
                Text("Tất cả (\(viewModel.webViewRecords.count))").tag(0)
                Text("Chỉ Cache").tag(1)
                Text("Cookies/Lưu trữ").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack {
                Text("Booster Pro tôn trọng tuyệt đối dữ liệu đăng nhập. Cookies mặc định KHÔNG được chọn.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(AppTheme.cardBackground)
    }

    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredRecords.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "#00F5A0"))
                            .padding(.top, 40)
                        Text("Không có dữ liệu website trong danh mục này.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(filteredRecords) { item in
                        Button {
                            viewModel.toggleWebViewRecord(id: item.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(item.isSelected ? AppTheme.primaryAccent : .secondary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 6) {
                                        if item.isCacheOnly {
                                            Text("Cache")
                                                .font(.caption2.bold())
                                                .foregroundStyle(Color(hex: "#00F5A0"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(hex: "#00F5A0").opacity(0.12))
                                                .clipShape(Capsule())
                                        }

                                        if item.hasCookiesOrAuth {
                                            Text("Cookies/Storage")
                                                .font(.caption2.bold())
                                                .foregroundStyle(AppTheme.warningAmber)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.warningAmber.opacity(0.12))
                                                .clipShape(Capsule())
                                        }

                                        Text(item.dataTypes.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.clearWebViewCache(includeCookies: false)
                }
            } label: {
                Text("Xóa sạch Cache Web")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.08))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }

            if selectedCount > 0 {
                Button {
                    if hasSelectedCookies {
                        showConfirmDeleteCookies = true
                    } else {
                        Task {
                            await viewModel.deleteSelectedWebViewRecords(types: [
                                WKWebsiteDataTypeDiskCache,
                                WKWebsiteDataTypeMemoryCache,
                                WKWebsiteDataTypeOfflineWebApplicationCache
                            ])
                        }
                    }
                } label: {
                    Text("Xóa (\(selectedCount)) mục")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(hasSelectedCookies ? AppTheme.criticalRed : AppTheme.primaryAccent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
}
