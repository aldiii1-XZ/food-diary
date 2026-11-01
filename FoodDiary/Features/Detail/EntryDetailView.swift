import SwiftUI
import SwiftData
import UIKit

/// Detail + edit nama/catatan/waktu, hapus (PRD §4.1). Perubahan baru tersimpan
/// saat tombol Simpan — bukan autosave sambil mengetik.
struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry

    @State private var name: String
    @State private var details: String
    @State private var consumedAt: Date
    @State private var confirmDelete = false
    @State private var errorMessage: String?

    init(entry: FoodEntry) {
        self.entry = entry
        _name = State(initialValue: entry.foodName ?? "")
        _details = State(initialValue: entry.foodDescription ?? "")
        _consumedAt = State(initialValue: entry.consumedAt)
    }

    private var fullImage: UIImage? {
        UIImage(contentsOfFile: ImageStore.shared.photoURL(for: entry.imagePath).path)
    }

    var body: some View {
        Form {
            Section {
                if let fullImage {
                    Image(uiImage: fullImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 320)
                } else {
                    Text("Foto tidak ditemukan di perangkat.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Detail") {
                TextField("Nama makanan", text: $name)
                TextField("Catatan", text: $details, axis: .vertical)
                DatePicker("Waktu konsumsi", selection: $consumedAt)
            }

            Section {
                Button("Hapus Catatan", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan") { save() }
            }
        }
        .confirmationDialog(
            "Hapus catatan dan fotonya?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Hapus", role: .destructive) { delete() }
        }
        .alert("Gagal", isPresented: errorPresented) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.foodName = trimmedName.isEmpty ? nil : trimmedName
        entry.foodDescription = trimmedDetails.isEmpty ? nil : trimmedDetails
        entry.consumedAt = consumedAt
        do {
            try FoodEntryRepository(context: context, snapshotService: .shared).updateEntry(entry)
            dismiss()
        } catch {
            errorMessage = "Perubahan tidak tersimpan: \(error.localizedDescription)"
        }
    }

    private func delete() {
        do {
            try FoodEntryRepository(context: context, snapshotService: .shared).deleteEntry(entry)
            dismiss()
        } catch {
            errorMessage = "Catatan tidak terhapus: \(error.localizedDescription)"
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
}
