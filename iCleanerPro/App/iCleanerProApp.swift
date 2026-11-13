import SwiftUI

@main
struct iCleanerProApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isShowingSplash: Bool = true

    init() {
        // Configure standard URLCache bounds for network operations within iOS memory limits.
        URLCache.shared.memoryCapacity = 16 * 1024 * 1024
        URLCache.shared.diskCapacity = 64 * 1024 * 1024
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingSplash {
                    AppSplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isShowingSplash = false
                        }
                    }
                    .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    OnboardingIntroView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.96))))
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isShowingSplash)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        }
    }
}
