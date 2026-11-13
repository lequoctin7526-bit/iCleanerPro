import SwiftUI

@main
struct iCleanerProApp: App {
    init() {
        // Configure standard URLCache bounds for network operations within iOS memory limits.
        URLCache.shared.memoryCapacity = 16 * 1024 * 1024
        URLCache.shared.diskCapacity = 64 * 1024 * 1024
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
