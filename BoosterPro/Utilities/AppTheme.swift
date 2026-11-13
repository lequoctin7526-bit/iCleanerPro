import SwiftUI
import UIKit

/// Design tokens and adaptive Light/Dark Mode styles for Booster Pro.
enum AppTheme {
    static let primaryAccent = Color(red: 0.14, green: 0.45, blue: 0.98)
    static let secondaryAccent = Color(red: 0.08, green: 0.72, blue: 0.85)
    static let optimalGreen = Color(red: 0.11, green: 0.76, blue: 0.51)
    static let warningAmber = Color(red: 0.96, green: 0.62, blue: 0.14)
    static let criticalRed = Color(red: 0.93, green: 0.27, blue: 0.34)
    static let violetAccent = Color(red: 0.48, green: 0.34, blue: 0.96)

    static let background = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemGroupedBackground)
    static let separatorColor = Color(UIColor.separator)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primaryAccent, secondaryAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func scoreColor(for score: Double) -> Color {
        if score >= 0.80 {
            return optimalGreen
        } else if score >= 0.50 {
            return warningAmber
        } else {
            return criticalRed
        }
    }

    static func scoreGradient(for score: Double) -> LinearGradient {
        let base = scoreColor(for: score)
        return LinearGradient(
            colors: [base, base.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
