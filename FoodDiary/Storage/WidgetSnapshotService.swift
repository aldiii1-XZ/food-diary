import Foundation
import SwiftData
import WidgetKit

/// Menyusun ulang snapshot hari ini lalu minta iOS me-refresh widget (PRD §7).
/// Dipanggil setelah setiap simpan/hapus — widget sendiri tidak pernah menyentuh SwiftData.
@MainActor
final class WidgetSnapshotService {
    static let shared = WidgetSnapshotService()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let dayTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter
    }()

    private static let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func refresh(context: ModelContext) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now

        let entries = (try? context.fetch(FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.consumedAt >= start && $0.consumedAt < end },
            sortBy: [SortDescriptor(\.consumedAt, order: .forward)]
        ))) ?? []

        // ponytail: 8 entri terbesar cukup untuk widget besar; kalau need lebih,
        // kirim subset per family lewat AppIntent — tidak perlu sekarang.
        let items = entries.suffix(8).map { entry -> WidgetSnapshot.Item in
            ImageStore.shared.writeThumbnail(forPhotoNamed: entry.imagePath)
            return WidgetSnapshot.Item(
                id: entry.id,
                name: entry.foodName,
                timeText: Self.timeFormatter.string(from: entry.consumedAt),
                thumbFilename: entry.imagePath
            )
        }

        let snapshot = WidgetSnapshot(
            dateText: Self.dayTitleFormatter.string(from: .now),
            dateISO: Self.isoDayFormatter.string(from: .now),
            totalCount: entries.count,
            firstTimeText: entries.first.map { Self.timeFormatter.string(from: $0.consumedAt) },
            lastTimeText: entries.last.map { Self.timeFormatter.string(from: $0.consumedAt) },
            items: Array(items)
        )
        snapshot.write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
