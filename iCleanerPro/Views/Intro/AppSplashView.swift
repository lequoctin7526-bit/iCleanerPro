import SwiftUI

/// Animated splash reveal screen shown briefly on app launch.
struct AppSplashView: View {
    let onFinished: () -> Void

    @State private var scaleEffect: CGFloat = 0.75
    @State private var opacity: Double = 0.0
    @State private var ringRotation: Double = 0
    @State private var ringPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark elegant background
            Color(red: 0.05, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            // Subtle glowing backdrop
            RadialGradient(
                colors: [AppTheme.primaryAccent.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Branded logo with animated neon rings
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent, GamingTheme.neonGreen, AppTheme.primaryAccent],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(ringRotation))
                        .scaleEffect(ringPulse)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 18, x: 0, y: 8)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("iCleaner Pro")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("DEVICE OPTIMIZER & GAME BOOSTER")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(AppTheme.secondaryAccent)
                        .tracking(1.5)
                }

                // Loading progress indicator
                ProgressView()
                    .tint(AppTheme.secondaryAccent)
                    .scaleEffect(0.9)
                    .padding(.top, 12)
            }
            .scaleEffect(scaleEffect)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                scaleEffect = 1.0
                opacity = 1.0
            }

            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                ringPulse = 1.08
            }

            // Automatically transition to main app after 1.25s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                onFinished()
            }
        }
    }
}
