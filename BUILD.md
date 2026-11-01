# Food Diary — catatan build & uji

Status: MVP PRD selesai dan **sudah build + uji otomatis di CI** (GitHub Actions
runner macOS): build hijau, unit test 12/12 lulus, app jalan di simulator
(bukti screenshot). **Persistensi data terverifikasi**: app ditutup lalu dibuka
ulang tanpa seed → catatan tetap tampil. Kode ditulis di
Windows tanpa Xcode; kalau build manual di Mac perlu penyesuaian
signing/entitlement, catat di sini.
— tanggal tulis: 2026-10-31 · update CI: 2026-11-01

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

Sudah tercakup otomatis di CI: build, unit test (termasuk persistensi
lintas-restart — `testEntriesSurviveContainerReopen`), dan tampilan timeline
(lewat screenshot + buka ulang tanpa seed). Sisanya masih perlu cek manual.

Checklist manual (PRD §12):

- [ ] T-01 simpan foto tanpa nama → catatan muncul di timeline
- [ ] T-02 simpan dengan nama + catatan → ikut tampil
- [x] T-03 tutup & buka ulang app → data tetap ada — terverifikasi otomatis di
  CI (unit test + screenshot `02-after-restart.png`)
- [ ] T-04 edit nama/catatan/waktu lewat Detail → tersimpan
- [ ] T-05 quick capture: foto → simpan → selesai tanpa isi apa pun
- [ ] T-06 hapus catatan → baris hilang, foto ikut terhapus
- [ ] T-07 simpan/hapus → widget ikut memperbarui ringkasan
- [ ] T-08 ketuk widget → app terbuka di tab Hari Ini pada tanggal itu
- [ ] T-09 tolak izin kamera → tetap bisa pilih dari galeri
- [ ] T-10 hapus file foto manual (Files/Simulator) → app tidak crash, keluar placeholder

## Penyimpanan data

- Catatan (nama, waktu, catatan teks) → database **SwiftData**: file SQLite di
  disk milik app; dibaca ulang tiap app dibuka — restart/force-quit tidak
  menghapus isi.
- Foto asli → file JPEG di Application Support milik app; widget cuma membaca
  thumbnail.
- Data hilang hanya kalau: (a) catatan/foto dihapus dari dalam app, atau
  (b) app di-uninstall (aturan iOS — container app ikut terhapus).
- Data ikut backup iPhone (iCloud/Finder) secara default.
- `-uiDemoSeed` hanya mengisi kalau diminta **dan** database masih kosong —
  tidak pernah menimpa data yang sudah ada.

## CI (GitHub Actions)

Repo publik: <https://github.com/aldiii1-XZ/food-diary> — runner macOS gratis.
Workflow `.github/workflows/ios.yml` jalan tiap push ke `main` (bisa juga
manual lewat tab Actions → Run workflow):

1. `xcodegen generate`
2. `xcodebuild test` — unit test di simulator "iPhone 16" (12 tes)
3. launch pertama: isi data contoh (`-uiDemoSeed`) → `01-today.png`
4. app ditutup, **dibuka ulang tanpa seed** → `02-after-restart.png` (kalau
   penyimpanan rusak, screenshot ini bakal kosong)
5. mode gelap → `03-today-dark.png`
6. build Release unsigned → `FoodDiary-unsigned.ipa`
7. unggah screenshot + `.ipa` sebagai artefak `food-diary-output`

- Pantau dari terminal: `gh run list`, `gh run watch`.
- Unduh artefak (jalankan dari folder tujuan):
  `gh run download <id-run> -n food-diary-output -R aldiii1-XZ/food-diary`
  → `01-today.png`, `02-after-restart.png`, `03-today-dark.png`,
  `FoodDiary-unsigned.ipa`.
- `.ipa` unsigned = belum ditandatangani; install lewat AltStore/Sideloadly
  dengan Apple ID sendiri.
- Data contoh seed dibuat hanya saat argumen `-uiDemoSeed` ada (CI); pemakaian
  normal tidak pernah membuatnya.

## Kalau mau ganti identitas

Bundle ID & App Group dipakai di tiga tempat — ubah semuanya:
1. `project.yml` (PRODUCT_BUNDLE_IDENTIFIER ×2 + entitlements ×2)
2. `Shared/AppGroup.swift` — konstanta `identifier`
3. `FoodDiary/Info.plist`-nya digenerate, tidak perlu diedit manual.

## Batasan lingkungan Windows

- Build, signing, install ke iPhone, dan App Store semuanya butuh macOS + Xcode.
- Windows bisa dipakai untuk nulis kode (seperti sekarang) dan push git.
- CI macOS (GitHub Actions) sudah dipakai untuk build + test + screenshot
  (bagian "CI" di atas). Yang tetap butuh Mac/Apple ID: signing, install ke
  iPhone (unduh `.ipa` unsigned → side-load), App Store.
