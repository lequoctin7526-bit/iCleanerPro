import SwiftUI

/// Animated multi-ring radar pulse and sweep indicator for Smart Scan & system analysis.
struct RadarScanAnimationView: View {
    let isScanning: Bool
    let progress: Double
    var centerIcon: String = "sparkles.rectangle.stack"

    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 0.85
    @State private var pulseOpacity: Double = 0.65

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { idx in
                Circle()
                    .stroke(
                        AppTheme.primaryAccent.opacity(isScanning ? 0.22 - Double(idx) * 0.05 : 0.12),
                        lineWidth: 1.5
                    )
                    .frame(width: CGFloat(120 + idx * 42), height: CGFloat(120 + idx * 42))
                    .scaleEffect(isScanning ? pulseScale : 1.0)
                    .opacity(isScanning ? pulseOpacity : 0.5)
                    .animation(
                        isScanning
                            ? .easeInOut(duration: 1.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(idx) * 0.22)
                            : .default,
                        value: isScanning
                    )
            }

            if isScanning {
                Circle()
                    .trim(from: 0, to: 0.28)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.primaryAccent.opacity(0.0), AppTheme.secondaryAccent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 158, height: 158)
                    .rotationEffect(.degrees(rotationAngle))
            }

            Circle()
                .fill(AppTheme.heroGradient)
                .frame(width: 96, height: 96)
                .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 14, x: 0, y: 6)

            VStack(spacing: 4) {
                Image(systemName: centerIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(Int((min(1.0, max(0.0, progress)) * 100).rounded()))%")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .frame(height: 215)
        .onAppear {
            updateAnimationState(active: isScanning)
        }
        .onChange(of: isScanning) { active in
            updateAnimationState(active: active)
        }
    }

    private func updateAnimationState(active: Bool) {
        if active {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulseScale = 1.07
                pulseOpacity = 0.25
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                rotationAngle = 0
                pulseScale = 1.0
                pulseOpacity = 0.55
            }
        }
    }
}
