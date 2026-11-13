import SwiftUI

/// Smooth animated circular ring for Optimization Health score or Storage usage.
struct CircularProgressRing: View {
    let progress: Double
    let title: String
    let subtitle: String
    var lineWidth: CGFloat = 16
    var size: CGFloat = 168
    var accentColors: [Color]?

    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    private var gradientColors: [Color] {
        if let accentColors {
            return accentColors
        }
        let base = AppTheme.scoreColor(for: clampedProgress)
        return [base, AppTheme.secondaryAccent]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.primary.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.75, dampingFraction: 0.82), value: clampedProgress)

            VStack(spacing: 4) {
                Text("\(Int((clampedProgress * 100).rounded()))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.scoreColor(for: clampedProgress))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.scoreColor(for: clampedProgress).opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(width: size, height: size)
    }
}
