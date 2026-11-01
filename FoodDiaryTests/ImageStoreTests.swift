import XCTest
@testable import FoodDiary

final class ImageStoreTests: XCTestCase {
    func testSaveAndDeletePhotoRoundtrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("food-diary-store-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ImageStore(directory: directory)

        let filename = try store.savePhotoData(Data([0xAA, 0xBB]))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.photoURL(for: filename).path))
        XCTAssertEqual(try Data(contentsOf: store.photoURL(for: filename)), Data([0xAA, 0xBB]))

        store.deletePhoto(named: filename)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.photoURL(for: filename).path))
    }

    /// Nama file selalu baru — tidak pernah menimpa foto lama.
    func testSavePhotoNeverOverwrites() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("food-diary-store-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ImageStore(directory: directory)

        let first = try store.savePhotoData(Data([0x01]))
        let second = try store.savePhotoData(Data([0x02]))
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: store.photoURL(for: first)), Data([0x01]))
        XCTAssertEqual(try Data(contentsOf: store.photoURL(for: second)), Data([0x02]))
    }

    func testTotalPhotoBytesCountsFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("food-diary-store-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ImageStore(directory: directory)

        _ = try store.savePhotoData(Data(repeating: 0x01, count: 100))
        _ = try store.savePhotoData(Data(repeating: 0x02, count: 50))
        XCTAssertEqual(store.totalPhotoBytes(), 150)
    }
}
