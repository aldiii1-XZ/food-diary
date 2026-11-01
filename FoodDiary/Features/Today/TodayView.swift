import SwiftUI

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @State private var showCapture = false

    var body: some View {
        @Bindable var router = router
        NavigationStack {
            DayTimeline(date: router.selectedDate)
                .navigationTitle("Hari Ini")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button { shiftDay(-1) } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Hari sebelumnya")

                        Button { shiftDay(1) } label: {
                            Image(systemName: "chevron.right")
                        }
                        .accessibilityLabel("Hari berikutnya")
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if !Calendar.current.isDateInToday(router.selectedDate) {
                            Button("Hari Ini") { router.selectedDate = .now }
                        }
                        Button { showCapture = true } label: {
                            Label("Catat makanan", systemImage: "camera")
                        }
                    }
                }
                .sheet(isPresented: $showCapture) {
                    CaptureView(defaultDate: router.selectedDate)
                }
        }
    }

    private func shiftDay(_ value: Int) {
        router.selectedDate = Calendar.current
            .date(byAdding: .day, value: value, to: router.selectedDate) ?? router.selectedDate
    }
}
