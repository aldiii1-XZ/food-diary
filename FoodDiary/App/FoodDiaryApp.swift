import SwiftUI
import SwiftData

@main
struct FoodDiaryApp: App {
    @State private var router = AppRouter()

    /// Database lokal (PRD §5.4). Kalau inisialisasi gagal, lebih baik berhenti
    /// dengan pesan jelas daripada diam-diam tidak menyimpan apa pun.
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: FoodEntry.self)
        } catch {
            fatalError("Gagal menyiapkan database Food Diary: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .onOpenURL(perform: openDeepLink)
                .task { DemoSeed.seedIfRequested(context: container.mainContext) }
        }
        .modelContainer(container)
    }

    /// fooddiary://today?date=yyyy-MM-dd — dipakai widget (PRD §7 "membuka
    /// aplikasi pada konteks tanggal").
    private func openDeepLink(_ url: URL) {
        guard url.scheme == "fooddiary" else { return }
        router.selectedTab = .today

        guard let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "date" })?.value else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: value) {
            router.selectedDate = date
        }
    }
}
