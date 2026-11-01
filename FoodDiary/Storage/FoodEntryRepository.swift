import Foundation
import SwiftData

/// Semua operasi simpan/hapus lewat sini supaya aturan integritas PRD §5.3
/// dijaga di satu tempat: file foto dulu, metadata kedua, cleanup saat gagal.
@MainActor
final class FoodEntryRepository {
    private let context: ModelContext
    private let imageStore: ImageStore
    private let snapshotService: WidgetSnapshotService?

    init(
        context: ModelContext,
        imageStore: ImageStore = .shared,
        snapshotService: WidgetSnapshotService? = nil
    ) {
        self.context = context
        self.imageStore = imageStore
        self.snapshotService = snapshotService
    }

    /// Simpan foto → metadata. Kalau metadata gagal, file foto dihapus lagi
    /// supaya tidak ada file yatim (T-06/§5.3).
    @discardableResult
    func createEntry(
        photoData: Data,
        foodName: String?,
        consumedAt: Date,
        foodDescription: String?
    ) throws -> FoodEntry {
        let filename = try imageStore.savePhotoData(photoData)
        let entry = FoodEntry(
            foodName: foodName,
            imagePath: filename,
            consumedAt: consumedAt,
            foodDescription: foodDescription
        )
        context.insert(entry)
        do {
            try context.save()
        } catch {
            context.delete(entry)
            imageStore.deletePhoto(named: filename)
            throw error
        }
        imageStore.writeThumbnail(forPhotoNamed: filename)
        snapshotService?.refresh(context: context)
        return entry
    }

    /// Dipakai setelah field di detail diedit.
    func updateEntry(_ entry: FoodEntry) throws {
        try context.save()
        snapshotService?.refresh(context: context)
    }

    /// Hapus metadata dulu; file foto baru dihapus kalau database sukses dan
    /// tidak ada catatan lain yang memakai file sama (§5.3).
    func deleteEntry(_ entry: FoodEntry) throws {
        let filename = entry.imagePath
        context.delete(entry)
        try context.save()

        let stillUsed = (try? context.fetchCount(
            FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.imagePath == filename })
        )) ?? 1
        if stillUsed == 0 {
            imageStore.deletePhoto(named: filename)
        }
        snapshotService?.refresh(context: context)
    }

    /// Catatan pada satu hari, urut waktu konsumsi (dipakai test + snapshot).
    func entries(on date: Date) throws -> [FoodEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return try context.fetch(FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.consumedAt >= start && $0.consumedAt < end },
            sortBy: [SortDescriptor(\.consumedAt, order: .forward)]
        ))
    }
}
