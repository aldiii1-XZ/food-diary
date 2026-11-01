import Foundation
import ImageIO
import UIKit

/// Penyimpanan file foto (PRD §5.3).
/// Foto asli di Application Support (bukan cache/temporary), thumbnail hanya
/// untuk widget di App Group.
final class ImageStore {
    static let shared = ImageStore()

    let photosDirectory: URL

    /// `directory` bisa diisi folder lain untuk unit test.
    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FoodDiary/Photos", isDirectory: true)
        photosDirectory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    func photoURL(for filename: String) -> URL {
        photosDirectory.appendingPathComponent(filename)
    }

    /// Nama file selalu UUID baru — tidak pernah menimpa foto lama.
    func savePhotoData(_ data: Data) throws -> String {
        let filename = UUID().uuidString + ".jpg"
        try data.write(to: photoURL(for: filename), options: [.atomic])
        return filename
    }

    func deletePhoto(named filename: String) {
        try? FileManager.default.removeItem(at: photoURL(for: filename))
        deleteThumbnail(named: filename)
    }

    // MARK: - Thumbnail (App Group, dibaca widget)

    func thumbnailURL(for filename: String) -> URL? {
        AppGroup.thumbnailsURL?.appendingPathComponent(filename)
    }

    func deleteThumbnail(named filename: String) {
        guard let url = thumbnailURL(for: filename) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Thumbnail 600 px untuk widget; foto asli tidak diubah (PRD §5.3, §7).
    /// Gagal senyap kalau file bukan gambar — tampilan widget punya placeholder.
    func writeThumbnail(forPhotoNamed filename: String) {
        guard let destination = thumbnailURL(for: filename),
              !FileManager.default.fileExists(atPath: destination.path),
              let source = CGImageSourceCreateWithURL(photoURL(for: filename) as CFURL, nil)
        else { return }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 600,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let data = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.8)
        else { return }

        try? data.write(to: destination, options: [.atomic])
    }

    /// Total ukuran foto tersimpan — untuk halaman Pengaturan.
    func totalPhotoBytes() -> Int {
        let keys: [URLResourceKey] = [.fileSizeKey]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: photosDirectory, includingPropertiesForKeys: keys
        )) ?? []
        return files.reduce(0) { total, url in
            total + ((try? url.resourceValues(forKeys: Set(keys)).fileSize) ?? 0)
        }
    }
}
