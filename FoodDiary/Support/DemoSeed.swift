import Foundation
import SwiftData
import UIKit

/// ponytail: data contoh untuk screenshot CI (dipicu argumen -uiDemoSeed).
/// Tidak aktif di pemakaian normal; hapus kalau tidak dipakai lagi.
@MainActor
enum DemoSeed {
    static func seedIfRequested(context: ModelContext) {
        guard CommandLine.arguments.contains("-uiDemoSeed") else { return }
        guard (try? context.fetchCount(FetchDescriptor<FoodEntry>())) == 0 else { return }

        let samples: [(name: String, hoursAgo: Double, note: String?)] = [
            ("Nasi goreng", 6, "Sarapan di warung depan kampus"),
            ("Kopi susu", 3, nil),
            ("Mie ayam", 1, "Makan malam"),
        ]
        let colors: [UIColor] = [.systemOrange, .systemBrown, .systemRed]
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 675))

        for (index, sample) in samples.enumerated() {
            let color = colors[index % colors.count].withAlphaComponent(0.45)
            let image = renderer.image { context in
                context.cgContext.setFillColor(color.cgColor)
                context.cgContext.fill(CGRect(x: 0, y: 0, width: 900, height: 675))
            }
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            try? FoodEntryRepository(context: context, snapshotService: .shared).createEntry(
                photoData: data,
                foodName: sample.name,
                consumedAt: Date().addingTimeInterval(-sample.hoursAgo * 3600),
                foodDescription: sample.note
            )
        }
    }
}
