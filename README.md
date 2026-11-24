# 💧 CaiHeurang — Air Jernih untuk Keluarga Sehat

**CaiHeurang** adalah aplikasi Flutter *water habit tracker* dengan gamifikasi tanaman virtual dan pemantau konsumsi minuman manis, dirancang ramah untuk seluruh anggota keluarga Indonesia dengan target hidrasi & batas gula berdasarkan panduan WHO / IOM.

---

## ✨ Fitur Utama

- **Tracking Air Minum +1 Gelas**: Catat konsumsi air 250 ml dengan animasi progres melingkar, *haptic feedback*, serta tombol hapus/undo di riwayat harian.
- **Tanaman Virtual Interaktif (7 Fase × 5 Mood)**: Ilustrasi tanaman kustom yang berevolusi dari *Biji* hingga *Pohon Rindang* berdasarkan XP, lengkap dengan animasi & ekspresi mood (*celebrating, happy, normal, thirsty, sleeping*).
- **Sistem XP, Golden Hour, Streak & Perisai**:
  - Bonus XP di *Golden Hour* (pagi 06–09, siang 12–13, sore 16–18), bonus target harian, *recovery bonus*, serta milestone streak (3, 7, 14, 30 hari).
  - **Streak Shield** otomatis melindungi streak saat absen dan bertambah setiap kelipatan 7 hari.
- **Pemantau Minuman Manis**: Catat es teh manis, kopi manis, jus, kemasan, hingga minuman kustom dengan estimasi gram gula & peringatan lembut sesuai batas harian WHO berdasarkan usia.
- **Share Achievement ala TikTok Streak**: Buat & bagikan kartu vertikal bergaya Story (mode *Streak*, *Target Harian*, dan *Evolusi Tanaman*) langsung ke WhatsApp, TikTok, atau Instagram Story.
- **Multi-Profil Keluarga**: Tambah, pindah, dan kelola beberapa anggota keluarga (Ayah, Ibu, Anak, dll.) dalam satu perangkat — masing-masing dengan target air, tanaman, riwayat, dan streak terpisah.
- **Pengingat Minum Lokal**: Notifikasi terjadwal (06:00–22:00) dengan deteksi zona waktu lokal otomatis (WIB/WITA/WIT) dan interval fleksibel (1–4 jam).

---

## 🧱 Arsitektur & Tech Stack

- **Framework**: Flutter (Material 3)
- **State Management**: `flutter_riverpod`
- **Local Storage**: `hive_flutter` (offline-first, tanpa backend)
- **Notifikasi**: `flutter_local_notifications` + `timezone`
- **Share Gambar**: `share_plus` + `path_provider` + `RepaintBoundary`
- **Format Tanggal**: `intl` (lokal Indonesia `id`)

```text
lib/
├── core/
│   ├── constants/     # Konstanta XP, level, target WHO, gula, emoji
│   ├── router/        # Navigasi onboarding & main
│   ├── theme/         # Palet warna & tema Nunito
│   └── utils/         # HiveInit, NotificationService, AchievementShareService
├── data/
│   ├── models/        # Hive models & adapters (.g.dart)
│   └── repositories/  # AppRepository (profil, water/sweet log, streak, summary)
├── features/
│   ├── home/          # MainScreen, HomeScreen, PlantWidget, ProgressRing, dialogs
│   ├── onboarding/    # Alur onboarding 5 langkah
│   ├── profile/       # Profil, edit profil, multi-profil keluarga, pengingat
│   └── stats/         # Skor mingguan, progres level, riwayat 7 hari
└── shared/
    └── providers/     # Riverpod providers & notifiers
```

---

## 🚀 Menjalankan Proyek

```bash
# 1. Install dependencies
flutter pub get

# 2. (Opsional) Generate ulang Hive adapters jika mengubah model
dart run build_runner build --delete-conflicting-outputs

# 3. Jalankan unit & widget tests
flutter test

# 4. Jalankan aplikasi
flutter run
```
