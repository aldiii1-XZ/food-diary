import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

/// Layar catat makanan (PRD §4.2): foto -> metadata opsional -> simpan.
/// Nama boleh kosong (quick capture, T-05).
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let defaultDate: Date

    @State private var photoData: Data?
    @State private var previewImage: UIImage?
    @State private var foodName = ""
    @State private var foodDescription = ""
    @State private var consumedAt = Date()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var saveErrorMessage: String?
    @State private var permissionMessage: String?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Foto") { photoSection }
                Section("Detail (opsional)") {
                    TextField("Nama makanan", text: $foodName)
                    TextField("Catatan", text: $foodDescription, axis: .vertical)
                    DatePicker("Waktu konsumsi", selection: $consumedAt)
                }
            }
            .navigationTitle("Catat Makanan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { save() }
                        .disabled(photoData == nil)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        photoData = data
                        previewImage = image
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoData = data
                        previewImage = image
                    } else {
                        saveErrorMessage = "Foto dari galeri tidak bisa dibaca. Coba pilih foto lain."
                    }
                }
            }
            .alert("Gagal menyimpan", isPresented: saveErrorPresented) {
                Button("OK") {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .alert("Izin kamera", isPresented: permissionPresented) {
                Button("Buka Pengaturan") { openSystemSettings() }
                Button("Tutup", role: .cancel) {}
            } message: {
                Text(permissionMessage ?? "")
            }
            .onAppear {
                consumedAt = Calendar.current.isDateInToday(defaultDate) ? .now : defaultDate
            }
        }
    }

    // MARK: - Foto

    @ViewBuilder
    private var photoSection: some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Pratinjau foto terpilih")
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.4))
                .frame(height: 110)
                .overlay {
                    Text("Belum ada foto")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
        }

        HStack(spacing: 12) {
            if cameraAvailable {
                Button {
                    startCamera()
                } label: {
                    Label("Ambil Foto", systemImage: "camera")
                }
                .buttonStyle(.borderedProminent)
            }

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Label("Pilih dari Galeri", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
        }
    }

    private func startCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        permissionMessage = self.permissionDeniedText
                    }
                }
            }
        default:
            permissionMessage = permissionDeniedText
        }
    }

    private var permissionDeniedText: String {
        "Izin kamera ditolak. Kamu masih bisa memilih foto dari galeri, atau aktifkan izin kamera lewat Pengaturan."
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    // MARK: - Simpan

    private func save() {
        guard let photoData else { return }
        let name = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try FoodEntryRepository(context: context, snapshotService: .shared).createEntry(
                photoData: photoData,
                foodName: name.isEmpty ? nil : name,
                consumedAt: consumedAt,
                foodDescription: details.isEmpty ? nil : details
            )
            dismiss()
        } catch {
            saveErrorMessage = "Catatan tidak tersimpan: \(error.localizedDescription). Coba lagi; kalau ruang penyimpanan hampir penuh, kosongkan dulu sedikit."
        }
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var permissionPresented: Binding<Bool> {
        Binding(
            get: { permissionMessage != nil },
            set: { if !$0 { permissionMessage = nil } }
        )
    }
}
