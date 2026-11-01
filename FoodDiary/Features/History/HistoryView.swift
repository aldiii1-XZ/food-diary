import SwiftUI

/// Riwayat: pilih tanggal lalu lihat timeline hari itu (PRD §4.3).
struct HistoryView: View {
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayControls
                Divider()
                DayTimeline(date: date)
            }
            .navigationTitle("Riwayat")
        }
    }

    private var dayControls: some View {
        HStack {
            Button { shiftDay(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Hari sebelumnya")

            Spacer()

            DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                .labelsHidden()

            Spacer()

            Button { shiftDay(1) } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Hari berikutnya")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func shiftDay(_ value: Int) {
        date = Calendar.current.date(byAdding: .day, value: value, to: date) ?? date
    }
}
