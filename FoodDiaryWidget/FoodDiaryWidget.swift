import WidgetKit
import SwiftUI
import UIKit

struct FoodDiaryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct FoodDiaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> FoodDiaryWidgetEntry {
        FoodDiaryWidgetEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (FoodDiaryWidgetEntry) -> Void) {
        completion(FoodDiaryWidgetEntry(date: .now, snapshot: .read()))
    }

    /// Tanpa polling: snapshot ditulis ulang aplikasi setiap ada perubahan,
    /// iOS yang menjadwalkan ulang tampilan (PRD §7 — bukan real-time).
    func getTimeline(in context: Context, completion: @escaping (Timeline<FoodDiaryWidgetEntry>) -> Void) {
        let entry = FoodDiaryWidgetEntry(date: .now, snapshot: .read())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

extension WidgetSnapshot {
    /// Data contoh untuk galeri widget / placeholder — bukan konten pengguna.
    static let sample = WidgetSnapshot(
        dateText: "Sabtu, 31 Oktober 2026",
        dateISO: "2026-10-31",
        totalCount: 3,
        firstTimeText: "07:30",
        lastTimeText: "19:45",
        items: [
            .init(id: UUID(), name: "Nasi goreng", timeText: "07:30", thumbFilename: nil),
            .init(id: UUID(), name: "Kopi susu", timeText: "12:15", thumbFilename: nil),
            .init(id: UUID(), name: "Sate ayam", timeText: "19:45", thumbFilename: nil),
        ]
    )
}

struct FoodDiaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FoodDiaryWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumView(snapshot: entry.snapshot)
        default:
            LargeView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Keluarga widget

private struct SmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hari ini")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if snapshot.totalCount == 0 {
                Spacer()
                Text("Belum ada catatan")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Text("\(snapshot.totalCount)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("catatan")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let first = snapshot.firstTimeText, let last = snapshot.lastTimeText {
                    Text("\(first)–\(last)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if let latest = snapshot.items.last {
                    HStack(spacing: 6) {
                        WidgetThumb(filename: latest.thumbFilename)
                        Text(latest.name ?? "Tanpa nama")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hari ini")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.totalCount)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("catatan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let first = snapshot.firstTimeText, let last = snapshot.lastTimeText {
                    Text("\(first)–\(last)")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 78, alignment: .leading)

            if snapshot.items.isEmpty {
                Spacer()
                Text("Belum ada catatan")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(snapshot.items.suffix(3)) { ItemRow(item: $0) }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct LargeView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Hari ini")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let first = snapshot.firstTimeText, let last = snapshot.lastTimeText {
                    Text("\(first)–\(last)")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            if snapshot.items.isEmpty {
                Spacer()
                Text("Belum ada catatan hari ini")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Text("\(snapshot.totalCount) catatan")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .monospacedDigit()

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(snapshot.items) { ItemRow(item: $0) }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ItemRow: View {
    let item: WidgetSnapshot.Item

    var body: some View {
        HStack(spacing: 8) {
            WidgetThumb(filename: item.thumbFilename)
            Text(item.name ?? "Tanpa nama")
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(item.timeText)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

/// Thumbnail dari App Group; placeholder kalau file tidak ada (foto asli tidak pernah dibaca widget).
private struct WidgetThumb: View {
    let filename: String?

    var body: some View {
        Group {
            if let filename,
               let url = AppGroup.thumbnailsURL?.appendingPathComponent(filename),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Widget

struct FoodDiaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FoodDiaryWidget", provider: FoodDiaryProvider()) { entry in
            FoodDiaryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "fooddiary://today?date=\(entry.snapshot.dateISO)"))
        }
        .configurationDisplayName("Food Diary")
        .description("Ringkasan makanan hari ini. Ketuk untuk membuka aplikasi.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct FoodDiaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        FoodDiaryWidget()
    }
}
