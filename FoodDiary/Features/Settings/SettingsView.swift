import SwiftUI
import SwiftData
import UIKit
import AVFoundation

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    @State private var entryCount = 0
    @State private var storageBytes = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Informasi penyimpanan") {
                    LabeledContent("Jumlah catatan", value: "\(entryCount)")
                    LabeledContent("Ukuran foto", value: ByteCountFormatter.string(
                        fromByteCount: Int64(storageBytes), countStyle: .file
                    ))
                    Text("Semua foto dan catatan disimpan lokal di perangkat ini, tidak diunggah ke internet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Izin") {
                    LabeledContent("Kamera", value: cameraStatusText)
                    Text("Pemilihan foto dari galeri tidak memerlukan izin tambahan.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Buka Pengaturan iOS") { openSystemSettings() }
                }

                Section("Bantuan") {
                    Text("Ambil atau pilih foto makanan — catatan langsung tersimpan dengan waktu saat itu. Nama dan catatan boleh dikosongkan dan diisi belakangan dari halaman Detail. Widget Food Diary di Home Screen menampilkan ringkasan hari ini.")
                        .font(.footnote)
                }

                Section("Tentang") {
                    LabeledContent("Versi", value: appVersion)
                }
            }
            .navigationTitle("Pengaturan")
            .onAppear(perform: loadStats)
        }
    }

    private var cameraStatusText: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return "Diizinkan"
        case .denied: return "Ditolak"
        case .restricted: return "Dibatasi"
        case .notDetermined: return "Belum diminta"
        @unknown default: return "Tidak diketahui"
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadStats() {
        entryCount = (try? context.fetchCount(FetchDescriptor<FoodEntry>())) ?? 0
        storageBytes = ImageStore.shared.totalPhotoBytes()
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
