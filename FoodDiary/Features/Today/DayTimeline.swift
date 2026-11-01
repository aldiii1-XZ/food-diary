import SwiftUI
import SwiftData

/// Timeline satu hari: judul tanggal, ringkasan, daftar catatan.
/// Dipakai tab Hari Ini dan Riwayat supaya tampilannya persis sama.
struct DayTimeline: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [FoodEntry]
    @State private var pendingDeletion: FoodEntry?

    let date: Date

    init(date: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.consumedAt >= start && $0.consumedAt < end },
            sort: [SortDescriptor(\FoodEntry.consumedAt, order: .forward)]
        )
        self.date = date
    }

    /// "3 catatan · 07:30–19:45" (PRD §4.4 rangkuman harian).
    private var summaryText: String? {
        guard let first = entries.first, let last = entries.last else { return nil }
        let start = Formatters.time.string(from: first.consumedAt)
        let end = Formatters.time.string(from: last.consumedAt)
        return "\(entries.count) catatan · \(start)–\(end)"
    }

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        EntryRow(entry: entry)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Hapus", role: .destructive) { pendingDeletion = entry }
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Formatters.dayTitle.string(from: date))
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                    if let summaryText {
                        Text(summaryText)
                            .font(.caption)
                            .monospacedDigit()
                            .textCase(nil)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Belum ada catatan",
                    systemImage: "fork.knife",
                    description: Text("Tekan tombol kamera untuk memotret makanan pertama di hari ini.")
                )
            }
        }
        .navigationDestination(for: FoodEntry.self) { entry in
            EntryDetailView(entry: entry)
        }
        .confirmationDialog(
            "Hapus catatan dan fotonya?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Hapus", role: .destructive) {
                if let entry = pendingDeletion {
                    try? FoodEntryRepository(context: context, snapshotService: .shared)
                        .deleteEntry(entry)
                }
                pendingDeletion = nil
            }
        }
    }
}
