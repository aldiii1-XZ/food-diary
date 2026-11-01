# Food Diary — catatan build & uji

Status: kode lengkap untuk MVP PRD, TAPI **belum pernah di-build** — ditulis di
Windows yang tidak punya Xcode. Build pertama di Mac hampir pasti perlu
penyesuaian kecil (signing, entitlement). Jangan kaget kalau ada error compile.
— tanggal tulis: 2026-10-31

## Isi

- `FoodDiary/` — app (SwiftUI + SwiftData), iOS 17+.
- `FoodDiaryWidget/` — widget Home Screen (kecil/sedang/besar).
- `Shared/` — kode yang dipakai app & widget (App Group + format snapshot).
- `FoodDiaryTests/` — unit test repository, penyimpanan file, snapshot.
- `project.yml` — definisi project untuk [XcodeGen](https://github.com/yonaskolb/XcodeGen);
  file `.xcodeproj` tidak disimpan di repo (digenerate).

## Langkah di Mac

1. Prasyarat: macOS + Xcode 15 ke atas, lalu `brew install xcodegen`.
2. Dari folder ini:
   ```sh
   xcodegen generate
   open FoodDiary.xcodeproj
   ```
3. Signing: target **FoodDiary** → Signing & Capabilities → pilih Team kamu.
   Ulangi untuk target **FoodDiaryWidget**.
4. App Group: pastikan `group.id.aldiii.fooddiary` terdaftar di
   Apple Developer → Identifiers → App Groups, dan dicentang di capability
   **kedua** target. Tanpa ini widget tidak bisa membaca data.
5. Jalankan: scheme **FoodDiary**, pilih simulator iPhone.
   - Simulator tidak punya kamera — tombol "Ambil Foto" muncul hanya di
     perangkat asli; di simulator pakai "Pilih dari Galeri".
   - Tes widget: long-press Home Screen → tambah widget → Food Diary.
     Widget menampilkan snapshot terakhir; berubah setelah app menyimpan/menghapus.

## Test

Unit test: pilih scheme FoodDiary → Cmd+U (jalan di simulator).

Checklist manual (PRD §12):

- [ ] T-01 simpan foto tanpa nama → catatan muncul di timeline
- [ ] T-02 simpan dengan nama + catatan → ikut tampil
- [ ] T-03 tutup & buka ulang app → data tetap ada
- [ ] T-04 edit nama/catatan/waktu lewat Detail → tersimpan
- [ ] T-05 quick capture: foto → simpan → selesai tanpa isi apa pun
- [ ] T-06 hapus catatan → baris hilang, foto ikut terhapus
- [ ] T-07 simpan/hapus → widget ikut memperbarui ringkasan
- [ ] T-08 ketuk widget → app terbuka di tab Hari Ini pada tanggal itu
- [ ] T-09 tolak izin kamera → tetap bisa pilih dari galeri
- [ ] T-10 hapus file foto manual (Files/Simulator) → app tidak crash, keluar placeholder

## Kalau mau ganti identitas

Bundle ID & App Group dipakai di tiga tempat — ubah semuanya:
1. `project.yml` (PRODUCT_BUNDLE_IDENTIFIER ×2 + entitlements ×2)
2. `Shared/AppGroup.swift` — konstanta `identifier`
3. `FoodDiary/Info.plist`-nya digenerate, tidak perlu diedit manual.

## Batasan lingkungan Windows

- Build, signing, install ke iPhone, dan App Store semuanya butuh macOS + Xcode.
- Windows bisa dipakai untuk nulis kode (seperti sekarang) dan push git.
- Opsi kalau tidak ada Mac: Mac fisik sewaan (mis. MacinCloud), atau CI macOS
  (GitHub Actions `macos` runner — gratis untuk repo publik; hasil build bisa
  diunduh untuk di-install via TestFlight/side-load).
