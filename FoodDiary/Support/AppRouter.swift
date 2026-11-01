import Foundation
import Observation

/// Navigasi lintas tab + tanggal yang sedang dilihat (dipakai deep link widget).
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case today
        case history
        case settings
    }

    var selectedTab: Tab = .today
    var selectedDate: Date = .now
}
