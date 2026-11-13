import SwiftUI

/// Neon cyberpunk palette and view modifiers for the Game Booster module.
enum GamingTheme {
    static let neonGreen = Color(red: 0.0, green: 0.98, blue: 0.58)
    static let neonCyan = Color(red: 0.0, green: 0.88, blue: 0.98)
    static let neonPurple = Color(red: 0.68, green: 0.28, blue: 0.98)
    static let neonPink = Color(red: 0.98, green: 0.18, blue: 0.62)
    static let neonOrange = Color(red: 1.0, green: 0.52, blue: 0.12)
    static let neonRed = Color(red: 0.98, green: 0.22, blue: 0.28)

    static let darkBackground = Color(red: 0.06, green: 0.07, blue: 0.11)
    static let cardBackground = Color(red: 0.10, green: 0.12, blue: 0.18)
    static let cardBackgroundAlt = Color(red: 0.13, green: 0.15, blue: 0.23)
    static let cardBorder = Color(red: 0.20, green: 0.24, blue: 0.35)

    static var neonGradient: LinearGradient {
        LinearGradient(
            colors: [neonGreen, neonCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cyberGradient: LinearGradient {
        LinearGradient(
            colors: [neonPurple, neonCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var fireGradient: LinearGradient {
        LinearGradient(
            colors: [neonOrange, neonPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func colorForHex(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch clean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 245, 160)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct GamingCardModifier: ViewModifier {
    var glowColor: Color = GamingTheme.neonGreen.opacity(0.2)
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(GamingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [glowColor, GamingTheme.cardBorder.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: glowColor.opacity(0.18), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func gamingCard(
        glowColor: Color = GamingTheme.neonGreen.opacity(0.25),
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16
    ) -> some View {
        modifier(GamingCardModifier(glowColor: glowColor, cornerRadius: cornerRadius, padding: padding))
    }
}
