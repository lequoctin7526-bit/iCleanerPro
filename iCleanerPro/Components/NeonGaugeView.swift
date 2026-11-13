import SwiftUI

/// Futuristic Neon Gaming Gauge showing Game Readiness Score (0-100) with glowing pulse.
struct NeonGaugeView: View {
    let score: Int
    let level: GameReadinessLevel
    var isPulsing: Bool = false

    private var normalizedProgress: Double {
        min(1.0, max(0.0, Double(score) / 100.0))
    }

    private var levelColor: Color {
        switch level {
        case .optimal: return GamingTheme.neonGreen
        case .moderate: return GamingTheme.neonOrange
        case .needsOptimization: return GamingTheme.neonRed
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(90))

            // Neon glowing progress track
            Circle()
                .trim(from: 0.15, to: 0.15 + (0.70 * normalizedProgress))
                .stroke(
                    AngularGradient(
                        colors: [GamingTheme.neonPurple, levelColor],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .shadow(color: levelColor.opacity(0.6), radius: 10, x: 0, y: 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.75), value: score)

            VStack(spacing: 3) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(level.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(levelColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(levelColor.opacity(0.16))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(levelColor.opacity(0.4), lineWidth: 1)
                    )

                Text("GAME READINESS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 2)
            }
        }
        .frame(width: 170, height: 170)
    }
}
