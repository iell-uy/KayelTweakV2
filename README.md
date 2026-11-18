# Kayel Tweak (standalone, v3 MAX)

## Apa ini
APK berdiri sendiri (bukan plugin AxManager) buat tweak Itel Android 12 kamu.
Logic tweak-nya (`kayel.sh`) sama dengan versi plugin yang sudah diuji sebelumnya.
UI-nya diambil dari file v3 MAX yang kamu kasih, cuma jembatannya diganti dari
`ksu.exec` (AxManager) jadi jembatan ADB milik app ini sendiri (`AdbBridge.kt`,
pakai library open-source **Kadb**).

**Level akses app ini = shell ADB, BUKAN root.** Sama persis levelnya dengan
AxManager/Shizuku. Jangan percaya kalau ada yang bilang app non-root bisa dapat
akses lebih dari itu tanpa root beneran — itu mustahil di Android.

## Kenapa nggak langsung dikasih file .apk jadi
Claude (AI yang bikin ini) jalan di sandbox tanpa Android SDK, jadi nggak bisa
compile .apk langsung. Solusinya: **GitHub Actions** (gratis) yang compile-in
buat kamu di cloud. Caranya di bawah.

## Cara dapetin file .apk (sekali doang, ±5 menit)
1. Bikin akun GitHub kalau belum punya (gratis): github.com
2. Bikin repo baru, nama bebas, visibility **Public** (biar Actions-nya gratis tanpa batas)
3. Upload SEMUA isi folder project ini ke repo itu (drag & drop lewat web GitHub juga bisa,
   atau pakai GitHub Desktop)
4. Buka tab **Actions** di repo itu → akan otomatis jalan ("Build Kayel Tweak APK").
   Tunggu sampai centang hijau (±2-4 menit)
5. Klik run yang selesai itu → scroll ke bawah ke bagian **Artifacts** →
   download `KayelTweak-debug-apk.zip` → di dalamnya ada `app-debug.apk`
6. Pindahkan apk itu ke HP Itel kamu, install seperti biasa
   (aktifkan dulu "Izinkan dari sumber ini" kalau diminta)

## Cara pakai di HP (SEKALI SAJA, langsung di HP, tanpa PC)
1. Setelan → Tentang Ponsel → ketuk "Nomor bentukan" 7x (kalau belum muncul Opsi Pengembang)
2. Setelan → Opsi Pengembang → aktifkan **Wireless debugging**
3. Ketuk **Pair device with pairing code** → akan muncul kode 6 digit
4. Buka app Kayel Tweak → masukkan kode itu → tunggu "Berhasil!"
5. Setelah itu app langsung bisa dipakai. Kalau Wireless debugging dimatikan atau
   HP restart, pairing BISA jadi perlu diulang — ini batasan bawaan Android, bukan bug.

## Kalau ADB bridge-nya gagal connect / error
Ini bagian paling kompleks dan BELUM saya tes di HP fisik (sandbox saya tidak
punya perangkat Android). Kalau gagal pairing atau shell tidak jalan:
- Pastikan Wireless debugging benar-benar aktif saat pairing
- Coba lagi: kode 6 digit kedaluwarsa cepat, jangan kelamaan
- Kirim ke saya pesan error yang muncul, saya bantu debug
- **Jangan panik, HP tidak akan rusak** — kegagalan di sini paling buruk cuma
  "app tidak bisa connect", bukan brick/bootloop. Semua perintah di kayel.sh
  sudah diuji logic-nya (backup/restore, validasi input, proteksi aplikasi sistem)
- Selama ini belum beres, **plugin AxManager versi sebelumnya tetap aman dipakai**
  sebagai cadangan

## Struktur
- `app/src/main/java/.../AdbBridge.kt` — pairing & shell (Kadb, open-source Apache/MIT)
- `app/src/main/java/.../MainActivity.kt` — layar pairing + host WebView
- `app/src/main/java/.../WebAppInterface.kt` — jembatan JS <-> Kotlin
- `app/src/main/assets/index.html` — UI v3 MAX kamu, bridge-nya sudah diganti
- `app/src/main/assets/kayel/kayel.sh` — logic tweak (identik dengan versi plugin)
- `.github/workflows/build.yml` — compile otomatis di GitHub Actions
