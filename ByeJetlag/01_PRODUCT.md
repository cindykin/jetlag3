# 01_PRODUCT.md — ByeJetlag

> **Status:** Source of truth. Isi requirement utama berasal dari knowledge base yang sudah ada di archive project yang diaudit. Jangan mengubah kontrak di file ini sebagai efek samping task coding biasa.

> File ini WAJIB dibaca AI sebelum mengerjakan task apapun di project ini.
> Kalau ada instruksi di prompt yang bertentangan dengan file ini, jangan asumsi ataupun menebak, mohon bertanya.

## Identitas Produk
- **Nama:** ByeJetlag
- **One-liner:** App untuk traveler yang sering bepergian lintas zona waktu dan mengalami jet lag — membantu mereka menyesuaikan jam biologis sebelum, selama, dan setelah penerbangan.

## Scope

### Onboarding & Profil
- User **wajib** mengisi data profil (timezone asal, pola tidur historis, dsb.) — **sekali saja**, di awal pakai app.
- Jika user skip/belum isi saat onboarding, sistem akan menanyakannya ulang **di akhir alur pembuatan trip pertama** (create jadwal trip), bukan dipaksa blocking di layar onboarding.
- Data jam tidur/bangun diambil dari profil (seed awal) dan dipakai generate jadwal sekaligus di muka. **Tidak ada check-in harian berulang** — user tidak ditanya tiap pagi. Satu-satunya cara update data tidur setelah jadwal jadi adalah lewat **Reschedule manual** (maksimal 1x per Trip, lihat `ALGORITHM_SPEC.md` Section 6.1).

### Trip Model
- **Hanya ada 1 tipe Trip** — tidak ada konsep "round-trip" sebagai entitas terpisah.
- Kalau user mau pulang-pergi, dia membuat **2 Trip terpisah** lewat flow "Add Flight" dua kali (Trip pergi, Trip pulang). Keduanya **tidak digrouping** jadi satu — masing-masing punya kalkulasi jetlag, jadwal, dan lifecycle sendiri.

### Health Screening — TIDAK ADA DI SCOPE INI, tidak perlu dikerjakan
- Gentle Mode (insomnia/lansia) — tidak dikerjakan.
- Semua parameter terkait (MaxShift alternatif, caffeine cutoff alternatif, margin CBTmin tambahan) — tidak dikerjakan.
- Tombol manual "Saya terlalu lelah" — tidak dikerjakan.
- Hanya ada 1 jalur parameter (normal), tidak ada percabangan gentle/insomnia.

### Notifikasi
- **Wajib push notification real** (bukan cuma in-app banner), dikirim berdasarkan jadwal waktu yang dihitung algoritma (Seek Light, Avoid Light, Caffeine Cut-off, dsb.), dengan timing presisi (real-time, match exact ke waktu event).
- Implikasi teknis: butuh `UNUserNotificationCenter` + local notification scheduling (bukan real-time server push, karena semua kalkulasi & data lokal).

### Data & Penyimpanan
- **Local only** — tidak ada backend/sync akun. Gunakan SwiftData atau UserDefaults sesuai kebutuhan struktur data (trip = model relasional; preferensi ringan = UserDefaults).
- Tidak ada rencana auth/login.

## Non-Goals yg tidak perlu dikerjakan (eksplisit)
- **WatchOS / Apple Watch / HealthKit** — tidak disentuh sama sekali (lihat `04_ALGORITHM.md`).
- **Health Screening, Gentle Mode, Insomnia handling** — tidak dikerjakan.
- **Backend/cloud sync, multi-device** — tidak ada rencana.
- **Auth/login** — tidak ada.
- **General discipline untuk AI:** jangan mengubah struktur project/arsitektur yang sudah berjalan kalau tidak diminta atau tidak diperlukan oleh task yang sedang dikerjakan. Kalau ada kebutuhan restrukturisasi, AI harus usul dulu dan jelaskan alasannya sebelum eksekusi — bukan mengubah diam-diam sebagai "efek samping" dari fix lain.

## Referensi Silang
- Rumus & logika algoritma lengkap: `04_ALGORITHM.md`
- Arsitektur kode (folder structure, pattern): `02_ARCHITECTURE.md`
- Design tokens & referensi visual: `05_DESIGN_SYSTEM.md`
