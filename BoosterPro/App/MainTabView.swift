import SwiftUI

struct MainTabView: View {
    enum Tab: Hashable {
        case dashboard
        case gameBooster
        case junk
        case ram
        case storage
    }

    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Tổng quan", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(Tab.dashboard)

            GameBoosterDashboardView()
                .tabItem {
                    Label("Game Booster", systemImage: "gamecontroller.fill")
                }
                .tag(Tab.gameBooster)

            JunkCleanerView()
                .tabItem {
                    Label("Dọn rác", systemImage: "trash.slash")
                }
                .tag(Tab.junk)

            RAMCleanerView()
                .tabItem {
                    Label("RAM", systemImage: "memorychip")
                }
                .tag(Tab.ram)

            StorageManagerView()
                .tabItem {
                    Label("Dung lượng", systemImage: "externaldrive")
                }
                .tag(Tab.storage)
        }
        .tint(AppTheme.primaryAccent)
    }
}
