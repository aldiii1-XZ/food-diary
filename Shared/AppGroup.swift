import Foundation

/// Akses App Group bersama aplikasi + widget (PRD §7).
/// Identifier harus sama dengan yang di project.yml + entitlements dua target.
enum AppGroup {
    static let identifier = "group.id.aldiii.fooddiary"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Folder thumbnail yang dibaca widget. Foto asli TIDAK ikut ke sini.
    static var thumbnailsURL: URL? {
        guard let base = containerURL else { return nil }
        let dir = base.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent("widget-snapshot.json")
    }
}
