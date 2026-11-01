import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            TodayView()
                .tabItem { Label("Hari Ini", systemImage: "clock") }
                .tag(AppRouter.Tab.today)

            HistoryView()
                .tabItem { Label("Riwayat", systemImage: "calendar") }
                .tag(AppRouter.Tab.history)

            SettingsView()
                .tabItem { Label("Pengaturan", systemImage: "gearshape") }
                .tag(AppRouter.Tab.settings)
        }
    }
}
