import SwiftUI

struct EntryRow: View {
    let entry: FoodEntry

    private var title: String {
        guard let name = entry.foodName, !name.isEmpty else { return "Tanpa nama" }
        return name
    }

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailImage(filename: entry.imagePath, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .lineLimit(1)
                if let details = entry.foodDescription, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(Formatters.time.string(from: entry.consumedAt))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), jam \(Formatters.time.string(from: entry.consumedAt))")
    }
}
