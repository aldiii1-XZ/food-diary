import XCTest
@testable import FoodDiary

final class WidgetSnapshotTests: XCTestCase {
    func testCodableRoundtrip() throws {
        let snapshot = WidgetSnapshot(
            dateText: "Sabtu, 31 Oktober 2026",
            dateISO: "2026-10-31",
            totalCount: 2,
            firstTimeText: "07:30",
            lastTimeText: "19:45",
            items: [
                .init(id: UUID(), name: "Nasi goreng", timeText: "07:30", thumbFilename: "a.jpg"),
                .init(id: UUID(), name: nil, timeText: "19:45", thumbFilename: nil),
            ]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

        XCTAssertEqual(decoded.totalCount, 2)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.firstTimeText, "07:30")
        XCTAssertNil(decoded.items.last?.name)
        XCTAssertEqual(decoded.items.first?.thumbFilename, "a.jpg")
    }

    func testEmptyDefault() {
        XCTAssertEqual(WidgetSnapshot.empty.totalCount, 0)
        XCTAssertTrue(WidgetSnapshot.empty.items.isEmpty)
        XCTAssertNil(WidgetSnapshot.empty.firstTimeText)
        XCTAssertNil(WidgetSnapshot.empty.lastTimeText)
    }
}
