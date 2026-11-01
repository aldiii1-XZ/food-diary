import XCTest
import SwiftData
@testable import FoodDiary

final class FoodEntryRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var store: ImageStore!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: FoodEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        store = ImageStore(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("food-diary-tests-\(UUID().uuidString)"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: store.photosDirectory)
    }

    @MainActor
    private func makeRepository() -> FoodEntryRepository {
        FoodEntryRepository(context: ModelContext(container), imageStore: store)
    }

    /// T-01/T-02/T-03: metadata + file tersimpan, dan tetap ada dari context baru.
    @MainActor
    func testCreateEntrySavesMetadataAndPhoto() throws {
        let repository = makeRepository()
        let entry = try repository.createEntry(
            photoData: Data([0x01, 0x02]),
            foodName: "Nasi goreng",
            consumedAt: .now,
            foodDescription: "Sarapan"
        )

        XCTAssertEqual(entry.foodName, "Nasi goreng")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.photoURL(for: entry.imagePath).path))

        let freshContext = ModelContext(container)
        let entries = try freshContext.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.foodName, "Nasi goreng")
    }

    /// T-05: quick capture tanpa nama tetap valid.
    @MainActor
    func testCreateEntryWithoutName() throws {
        let repository = makeRepository()
        let entry = try repository.createEntry(
            photoData: Data([0x01]),
            foodName: nil,
            consumedAt: .now,
            foodDescription: nil
        )
        XCTAssertNil(entry.foodName)
        XCTAssertNil(entry.foodDescription)
    }

    /// T-06: hapus -> metadata dan file foto sama-sama hilang.
    @MainActor
    func testDeleteEntryRemovesMetadataAndPhoto() throws {
        let repository = makeRepository()
        let entry = try repository.createEntry(
            photoData: Data([0x01]),
            foodName: "Mie ayam",
            consumedAt: .now,
            foodDescription: nil
        )
        let path = store.photoURL(for: entry.imagePath).path

        try repository.deleteEntry(entry)

        XCTAssertEqual(try repository.entries(on: .now).count, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    /// §5.3: file foto tidak dihapus selama masih dipakai catatan lain.
    @MainActor
    func testDeleteKeepsPhotoUsedByAnotherEntry() throws {
        // Satu context untuk insert + hapus — sama seperti alur app.
        let context = ModelContext(container)
        let repository = FoodEntryRepository(context: context, imageStore: store)
        let filename = try store.savePhotoData(Data([0x01]))
        let first = FoodEntry(imagePath: filename, consumedAt: .now)
        let second = FoodEntry(imagePath: filename, consumedAt: .now)
        context.insert(first)
        context.insert(second)
        try context.save()

        try repository.deleteEntry(first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.photoURL(for: filename).path))

        try repository.deleteEntry(second)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.photoURL(for: filename).path))
    }

    /// T-04: edit nama/catatan/waktu ikut tersimpan.
    @MainActor
    func testUpdateEntryPersistsChanges() throws {
        let repository = makeRepository()
        let entry = try repository.createEntry(
            photoData: Data([0x01]),
            foodName: nil,
            consumedAt: .now,
            foodDescription: nil
        )
        entry.foodName = "Bubur ayam"
        entry.foodDescription = "Pagi"
        try repository.updateEntry(entry)

        let freshContext = ModelContext(container)
        let fetched = try freshContext.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(fetched.first?.foodName, "Bubur ayam")
        XCTAssertEqual(fetched.first?.foodDescription, "Pagi")
    }

    /// Catatan difilter per hari, urut waktu konsumsi.
    @MainActor
    func testEntriesOnDateFiltersByDay() throws {
        let repository = makeRepository()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        try repository.createEntry(photoData: Data([0x01]), foodName: "Hari ini", consumedAt: today, foodDescription: nil)
        try repository.createEntry(photoData: Data([0x02]), foodName: "Kemarin", consumedAt: yesterday, foodDescription: nil)

        let todayEntries = try repository.entries(on: today)
        XCTAssertEqual(todayEntries.count, 1)
        XCTAssertEqual(todayEntries.first?.foodName, "Hari ini")
    }
}
