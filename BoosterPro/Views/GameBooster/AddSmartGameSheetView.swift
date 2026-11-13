import SwiftUI

/// Sheet allowing user to add games from preset catalog, live App Store search, or manual entry.
struct AddSmartGameSheetView: View {
    @ObservedObject var viewModel: SmartGameManagerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0

    // Live App Store search state
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [AppStoreLookupItem] = []
    @State private var searchError: String?

    // Manual form state
    @State private var manualName: String = ""
    @State private var manualBundleId: String = ""
    @State private var manualAppStoreId: String = ""
    @State private var manualUrlScheme: String = ""
    @State private var manualVersion: String = "1.0.0"
    @State private var manualCategory: GameCategory = .moba
    @State private var manualColorHex: String = "#00F5A0"

    private let presetColors = ["#00F5A0", "#00D9F5", "#FF9500", "#FF3B30", "#AF52DE", "#5E5CE6", "#FFD60A"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Nguồn thêm", selection: $selectedTab) {
                    Text("Phổ biến").tag(0)
                    Text("App Store").tag(1)
                    Text("Tự nhập").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                TabView(selection: $selectedTab) {
                    popularPresetsTab.tag(0)
                    appStoreSearchTab.tag(1)
                    manualEntryTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Thêm Game Mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(GamingTheme.neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Tab 1: Popular Presets
    private var popularPresetsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(GamePresetCatalog.presets) { preset in
                    let isAlreadyAdded = viewModel.games.contains { $0.bundleId == preset.bundleId || $0.appStoreId == preset.appStoreId }
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(GamingTheme.cardBackgroundAlt)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(GamingTheme.colorForHex(preset.colorHex), lineWidth: 1)
                                )
                            Image(systemName: preset.iconSymbol)
                                .font(.title3)
                                .foregroundStyle(GamingTheme.colorForHex(preset.colorHex))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            HStack(spacing: 6) {
                                Text(preset.category.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(GamingTheme.neonCyan)
                                if let scheme = preset.urlScheme {
                                    Text("• \(scheme)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                        }

                        Spacer()

                        Button {
                            if !isAlreadyAdded {
                                viewModel.addGame(preset)
                            }
                        } label: {
                            Text(isAlreadyAdded ? "ĐÃ THÊM" : "THÊM")
                                .font(.caption2.weight(.black))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(isAlreadyAdded ? Color.white.opacity(0.12) : GamingTheme.neonGreen)
                                .foregroundStyle(isAlreadyAdded ? .white.opacity(0.5) : .black)
                                .clipShape(Capsule())
                        }
                        .disabled(isAlreadyAdded)
                    }
                    .padding(12)
                    .background(GamingTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(16)
        }
    }

    // MARK: - Tab 2: App Store Live Search
    private var appStoreSearchTab: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(GamingTheme.neonCyan)
                TextField("Nhập tên game trên App Store...", text: $searchQuery)
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit { performSearch() }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Button("Tìm") {
                    performSearch()
                }
                .font(.subheadline.bold())
                .foregroundStyle(GamingTheme.neonGreen)
            }
            .padding(12)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if isSearching {
                Spacer()
                ProgressView("Đang tìm trên App Store...")
                    .tint(GamingTheme.neonCyan)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            } else if searchResults.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.app")
                        .font(.system(size: 40))
                        .foregroundStyle(GamingTheme.neonCyan.opacity(0.6))
                    Text("Tìm game trực tiếp từ Apple App Store")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Dữ liệu chính thức gồm icon, phiên bản mới nhất và dung lượng.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults) { item in
                            appStoreResultRow(item)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func appStoreResultRow(_ item: AppStoreLookupItem) -> some View {
        let isAlreadyAdded = viewModel.games.contains { $0.appStoreId == String(item.trackId) }
        return HStack(spacing: 12) {
            if let art = item.artworkUrl100, let url = URL(string: art) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GamingTheme.cardBackgroundAlt)
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.trackName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("v\(item.version)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(GamingTheme.neonGreen)
                    if let genre = item.primaryGenreName {
                        Text("• \(genre)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                if let bytes = item.parsedFileSizeBytes {
                    Text(ByteFormatterUtil.formatFileSize(bytes))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            Button {
                if !isAlreadyAdded {
                    let newGame = SmartGameModel(
                        name: item.trackName,
                        bundleId: item.bundleId ?? "com.appstore.\(item.trackId)",
                        appStoreId: String(item.trackId),
                        urlScheme: nil,
                        category: .other,
                        installedVersion: item.version,
                        latestStoreVersion: item.version,
                        appStoreUrl: item.trackViewUrl,
                        iconUrl: item.artworkUrl512 ?? item.artworkUrl100,
                        fileSizeBytes: item.parsedFileSizeBytes,
                        releaseNotes: item.releaseNotes
                    )
                    viewModel.addGame(newGame)
                    dismiss()
                }
            } label: {
                Text(isAlreadyAdded ? "ĐÃ CÓ" : "THÊM")
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isAlreadyAdded ? Color.white.opacity(0.12) : GamingTheme.neonGreen)
                    .foregroundStyle(isAlreadyAdded ? .white.opacity(0.5) : .black)
                    .clipShape(Capsule())
            }
            .disabled(isAlreadyAdded)
        }
        .padding(12)
        .background(GamingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchError = nil

        Task {
            do {
                let results = try await AppStoreLookupService.shared.search(term: searchQuery)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchError = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }

    // MARK: - Tab 3: Manual Entry
    private var manualEntryTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                formField(label: "Tên Game", text: $manualName, placeholder: "Ví dụ: Tốc Chiến")
                formField(label: "URL Scheme (nếu có)", text: $manualUrlScheme, placeholder: "Ví dụ: wildrift://")
                formField(label: "Bundle Identifier", text: $manualBundleId, placeholder: "Ví dụ: com.riotgames.league.wildrift")
                formField(label: "App Store ID (dãy số)", text: $manualAppStoreId, placeholder: "Ví dụ: 1480644895")
                formField(label: "Phiên bản hiện tại", text: $manualVersion, placeholder: "Ví dụ: 5.1.0")

                // Category Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Thể loại")
                        .font(.caption.bold())
                        .foregroundStyle(GamingTheme.neonCyan)
                    Picker("Thể loại", selection: $manualCategory) {
                        ForEach(GameCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GamingTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Color Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Màu chủ đạo")
                        .font(.caption.bold())
                        .foregroundStyle(GamingTheme.neonCyan)
                    HStack(spacing: 12) {
                        ForEach(presetColors, id: \.self) { colorHex in
                            Circle()
                                .fill(GamingTheme.colorForHex(colorHex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: manualColorHex == colorHex ? 2.5 : 0)
                                )
                                .onTapGesture {
                                    manualColorHex = colorHex
                                }
                        }
                    }
                }

                Button {
                    guard !manualName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let newGame = SmartGameModel(
                        name: manualName,
                        bundleId: manualBundleId,
                        appStoreId: manualAppStoreId,
                        urlScheme: manualUrlScheme.isEmpty ? nil : manualUrlScheme,
                        category: manualCategory,
                        installedVersion: manualVersion.isEmpty ? "1.0.0" : manualVersion,
                        colorHex: manualColorHex
                    )
                    viewModel.addGame(newGame)
                    dismiss()
                } label: {
                    Text("LƯU GAME VÀO THƯ VIỆN")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(GamingTheme.neonGradient)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(manualName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 12)
            }
            .padding(16)
        }
    }

    private func formField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(GamingTheme.neonCyan)
            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)
                .background(GamingTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
