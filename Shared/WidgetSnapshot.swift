import Foundation

/// Snapshot kecil untuk widget (PRD §7): bukan database kedua, hanya ringkasan
/// hari ini yang ditulis ulang setiap aplikasi menyimpan/menghapus data.
struct WidgetSnapshot: Codable {
    struct Item: Codable, Identifiable {
        let id: UUID
        let name: String?
        let timeText: String
        /// Nama file thumbnail di folder Thumbnails App Group (foto asli tidak disalin).
        let thumbFilename: String?
    }

    var dateText: String
    var dateISO: String
    var totalCount: Int
    var firstTimeText: String?
    var lastTimeText: String?
    var items: [Item]

    static let empty = WidgetSnapshot(
        dateText: "", dateISO: "", totalCount: 0,
        firstTimeText: nil, lastTimeText: nil, items: []
    )

    func write() {
        guard let url = AppGroup.snapshotURL,
              let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    static func read() -> WidgetSnapshot {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
