import Foundation
import SwiftData

/// Satu catatan makanan (PRD §5.2).
/// `foodDescription` adalah field "description" di PRD — di-rename agar tidak
/// bentrok dengan `description` bawaan Swift.
@Model
final class FoodEntry {
    @Attribute(.unique) var id: UUID
    /// Opsional: quick capture boleh tanpa nama (T-05).
    var foodName: String?
    /// Nama file foto di folder Photos (bukan path absolut — folder bisa berubah).
    var imagePath: String
    var consumedAt: Date
    var createdAt: Date
    var foodDescription: String?

    init(
        id: UUID = UUID(),
        foodName: String? = nil,
        imagePath: String,
        consumedAt: Date = .now,
        createdAt: Date = .now,
        foodDescription: String? = nil
    ) {
        self.id = id
        self.foodName = foodName
        self.imagePath = imagePath
        self.consumedAt = consumedAt
        self.createdAt = createdAt
        self.foodDescription = foodDescription
    }
}
