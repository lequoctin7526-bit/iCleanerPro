import SwiftUI

struct GameLibraryView: View {
    @ObservedObject var viewModel: GameBoosterViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddGameSheet = false
    @State private var selectedCategoryFilter: GameCategory?

    var filteredGames: [GameItem] {
        if let cat = selectedCategoryFilter {
            return viewModel.games.filter { $0.category == cat }
        }
        return viewModel.games
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoryFilterBar

                    if filteredGames.isEmpty {
                        emptyLibraryCard
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGames) { game in
                                gameRow(game)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(GamingTheme.darkBackground.ignoresSafeArea())
            .navigationTitle("Thư Viện Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(GamingTheme.neonCyan)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGameSheet = true
                    } label: {
                        Label("Thêm Game", systemImage: "plus.circle.fill")
                            .foregroundStyle(GamingTheme.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddGameSheet) {
                AddGameSheetView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCategoryFilter = nil
                } label: {
                    Text("Tất cả")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategoryFilter == nil ? GamingTheme.neonGreen : GamingTheme.cardBackground)
                        .foregroundStyle(selectedCategoryFilter == nil ? .black : .white)
                        .clipShape(Capsule())
                }

                ForEach(GameCategory.allCases) { cat in
                    let isSel = selectedCategoryFilter == cat
                    Button {
                        selectedCategoryFilter = cat
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: cat.iconName)
                            Text(cat.rawValue)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSel ? GamingTheme.neonGreen : GamingTheme.cardBackground)
                        .foregroundStyle(isSel ? .black : .white)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func gameRow(_ game: GameItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GamingTheme.cardBackgroundAlt)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(GamingTheme.colorForHex(game.colorHex), lineWidth: 1.5)
                    )

                Image(systemName: game.iconSymbol)
                    .font(.title2)
                    .foregroundStyle(GamingTheme.colorForHex(game.colorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(game.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(game.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(GamingTheme.neonCyan)
                    if let scheme = game.urlScheme, !scheme.isEmpty {
                        Text("• \(scheme)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }

                if game.playCount > 0 {
                    Text("Đã chơi \(game.playCount) trận")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Button {
                dismiss()
                viewModel.launchGame(game)
            } label: {
                Text("CHƠI")
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(GamingTheme.neonGradient)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }

            Menu {
                Button(role: .destructive) {
                    viewModel.deleteGame(id: game.id)
                } label: {
                    Label("Xóa khỏi thư viện", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(6)
            }
        }
        .gamingCard(glowColor: GamingTheme.colorForHex(game.colorHex).opacity(0.2), cornerRadius: 18, padding: 12)
    }

    private var emptyLibraryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 44))
                .foregroundStyle(GamingTheme.neonGreen)
            Text("Không có game nào trong mục này")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Nhấn nút \"+\" ở góc trên bên phải để thêm game yêu thích.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .gamingCard(glowColor: GamingTheme.neonGreen.opacity(0.1))
    }
}

// MARK: - Add Game Sheet
struct AddGameSheetView: View {
    @ObservedObject var viewModel: GameBoosterViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var gameName = ""
    @State private var selectedCategory: GameCategory = .moba
    @State private var urlScheme = ""
    @State private var selectedIcon = "gamecontroller.fill"
    @State private var selectedColorHex = "#00F5A0"

    private let iconPresets = [
        "gamecontroller.fill", "bolt.shield.fill", "flame.fill", "wand.and.stars",
        "scope", "flag.checkered", "crown.fill", "star.fill", "cross.vial.fill"
    ]

    private let colorPresets = [
        "#00F5A0", "#00D9F5", "#AF52DE", "#FF2D55", "#FF9500", "#FFCC00"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên Game") {
                    TextField("Nhập tên game (ví dụ: Liên Quân Mobile)", text: $gameName)
                }

                Section("Thể Loại") {
                    Picker("Phân loại", selection: $selectedCategory) {
                        ForEach(GameCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section {
                    TextField("Ví dụ: aov://, wildrift://, pubgmobile://", text: $urlScheme)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("URL Scheme (Tùy chọn)")
                } footer: {
                    Text("Nếu để trống, bạn vẫn có thể bắt đầu phiên chơi và mở game thủ công.")
                }

                Section("Biểu Tượng") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(iconPresets, id: \.self) { sym in
                                Button {
                                    selectedIcon = sym
                                } label: {
                                    Image(systemName: sym)
                                        .font(.title2)
                                        .foregroundStyle(selectedIcon == sym ? .black : .white)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == sym ? GamingTheme.neonGreen : GamingTheme.cardBackgroundAlt)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Màu Sắc") {
                    HStack(spacing: 14) {
                        ForEach(colorPresets, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(GamingTheme.colorForHex(hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Thêm Game Mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        viewModel.addNewGame(
                            name: gameName,
                            category: selectedCategory,
                            urlScheme: urlScheme.isEmpty ? nil : urlScheme,
                            iconSymbol: selectedIcon,
                            colorHex: selectedColorHex
                        )
                        dismiss()
                    }
                    .disabled(gameName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
