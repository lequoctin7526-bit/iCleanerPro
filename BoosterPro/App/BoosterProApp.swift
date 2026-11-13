import SwiftUI

@main
struct BoosterProApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isShowingSplash: Bool = true

    init() {
        // Configure standard URLCache bounds for network operations within iOS memory limits.
        URLCache.shared.memoryCapacity = 16 * 1024 * 1024
        URLCache.shared.diskCapacity = 64 * 1024 * 1024

        // Register BGTaskScheduler tasks early during launch
        AutoCleanSchedulerService.shared.registerBackgroundTasks()
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
            .onChange(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            AutoCleanSchedulerService.shared.scheduleNextBackgroundTask()
        case .active:
            checkOnAppOpenTriggers()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func checkOnAppOpenTriggers() {
        let config = AutoCleanSchedulerService.shared.loadConfiguration()
        guard config.isMasterEnabled else { return }

        if config.schedule.frequency == .onAppOpen {
            Task {
                _ = await AutoCleanSchedulerService.shared.executeClean(
                    trigger: "Khi mở ứng dụng (On App Open)",
                    isBackground: false
                )
            }
        }
    }
}
