import SwiftUI

/// Premium cyber-styled card displaying an individual smart-managed game.
struct SmartGameCardView: View {
    let game: SmartGameModel
    let onPlay: () -> Void
    let onUpdate: () -> Void
    let onOptimize: () -> Void
    let onEditVersion: (String) -> Void
    let onDelete: () -> Void

    @State private var showEditVersionAlert = false
    @State private var editedVersionText = ""

    var body: some View {
        VStack(spacing: 12) {
            // Main Top Row: Icon + Details
            HStack(alignment: .top, spacing: 14) {
                gameIconView

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(game.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer()

                        if game.hasUpdateAvailable {
                            updateBadge
                        }
                    }

                    HStack(spacing: 6) {
                        Text(game.category.rawValue)
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(GamingTheme.neonCyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GamingTheme.neonCyan.opacity(0.14))
                            .clipShape(Capsule())

                        if let size = game.fileSizeBytes, size > 0 {
                            Text(ByteFormatterUtil.formatFileSize(size))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        if game.isInstalled {
                            HStack(spacing: 3) {
                                Circle().fill(GamingTheme.neonGreen).frame(width: 5, height: 5)
                                Text("Đã cài")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(GamingTheme.neonGreen)
                            }
                        }
                    }

                    // Version status row
                    versionStatusView
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Action Buttons Row
            HStack(spacing: 10) {
                // Play Button
                Button {
                    onPlay()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.caption.weight(.black))
                        Text("PLAY")
                            .font(.caption.weight(.black))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(GamingTheme.neonGradient)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: GamingTheme.neonGreen.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                // Update Button (if update available)
                if game.hasUpdateAvailable {
                    Button {
                        onUpdate()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.bold))
                            Text("UPDATE")
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(GamingTheme.neonOrange)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                // Quick Optimize Button
                Button {
                    onOptimize()
                } label: {
                    Image(systemName: "bolt.shield.fill")
                        .font(.body)
                        .foregroundStyle(GamingTheme.neonCyan)
                        .frame(width: 38, height: 38)
                        .background(GamingTheme.cardBackgroundAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(GamingTheme.neonCyan.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tối ưu hóa nhanh")

                // More Menu
                Menu {
                    Button {
                        editedVersionText = game.installedVersion
                        showEditVersionAlert = true
                    } label: {
                        Label("Sửa phiên bản đang cài", systemImage: "pencil")
                    }

                    Button {
                        onUpdate()
                    } label: {
                        Label("Mở trang App Store", systemImage: "arrow.up.forward.app")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Xóa khỏi thư viện", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 38, height: 38)
                        .background(GamingTheme.cardBackgroundAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(GamingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    game.hasUpdateAvailable
                        ? GamingTheme.neonOrange.opacity(0.6)
                        : GamingTheme.cardBorder,
                    lineWidth: 1
                )
        )
        .shadow(
            color: game.hasUpdateAvailable ? GamingTheme.neonOrange.opacity(0.18) : Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        .alert("Cập nhật phiên bản đã cài", isPresented: $showEditVersionAlert) {
            TextField("Ví dụ: 1.54.2", text: $editedVersionText)
            Button("Lưu") {
                onEditVersion(editedVersionText)
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Nhập phiên bản thực tế trên máy của bạn để hệ thống so sánh chính xác với App Store.")
        }
    }

    // MARK: - Subviews
    private var gameIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(GamingTheme.cardBackgroundAlt)
                .frame(width: 58, height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            game.hasUpdateAvailable ? GamingTheme.neonOrange : GamingTheme.colorForHex(game.colorHex),
                            lineWidth: 1.5
                        )
                )

            if let iconUrlStr = game.iconUrl, let url = URL(string: iconUrlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    case .failure, .empty:
                        fallbackIcon
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: game.iconSymbol)
            .font(.title2)
            .foregroundStyle(GamingTheme.colorForHex(game.colorHex))
    }

    private var updateBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 9))
            Text("UPDATE")
                .font(.system(size: 9, weight: .black, design: .monospaced))
        }
        .foregroundStyle(GamingTheme.neonOrange)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(GamingTheme.neonOrange.opacity(0.18))
        .clipShape(Capsule())
    }

    private var versionStatusView: some View {
        HStack(spacing: 6) {
            Text("v\(game.installedVersion)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))

            if let latest = game.latestStoreVersion {
                if game.hasUpdateAvailable {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GamingTheme.neonOrange)

                    Text("v\(latest)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(GamingTheme.neonOrange)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text("Mới nhất")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(GamingTheme.neonGreen)
                }
            } else {
                Text("• Chưa kiểm tra")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            if game.playCount > 0 {
                Text("\(game.playCount) trận")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GamingTheme.neonPurple)
            }
        }
    }
}
