# 02_ARCHITECTURE.md — ByeJetlag

> **Status:** Source of truth. Isi requirement utama berasal dari knowledge base yang sudah ada di archive project yang diaudit. Jangan mengubah kontrak di file ini sebagai efek samping task coding biasa.

> Baca `01_PRODUCT.md` dan `04_ALGORITHM.md` dulu. File ini soal STRUKTUR KODE, bukan requirement produk.
> Sumber: hasil audit kode asli, semua poin di bawah merujuk kondisi nyata project, bukan asumsi.

---

## 1. Kondisi Saat Ini (Ringkasan dari Audit)

Jangan implementasi fitur baru di atas fondasi ini tanpa membenahi poin-poin berikut dulu:

### 🔴 Kritis — blocker fungsional
1. **`ScheduleView` menampilkan `MockSchedule.sections` (data statis hardcode)**, BUKAN `trip.blocks` yang di-generate. Jadwal yang dihitung tidak pernah muncul di layar.
2. **`generateBlocks()` di `AppState` (Models.swift) adalah template 4-hari statis** — tidak ada CBTmin, tidak ada UTC offset/direction, tidak ada shift harian. Tidak menerapkan `04_ALGORITHM.md` sama sekali.
3. **Tidak ada persistence.** Semua data (`trips`, `profile`) cuma di memory (`@Published`). Force-quit = hilang semua.
4. **Date picker flight tidak timezone-aware** — `DatePicker` pakai timezone device, padahal UI mengklaim "local time at local airport". Ini fatal karena seluruh algoritma sirkadian bergantung waktu lokal bandara yang akurat.

### 🟠 Bug fungsional nyata
6. Dua model paralel untuk konsep yang sama: `BlockType`/`TimelineBlock` (Models.swift, dipakai generate) vs `ActivityType`/`ActivityItem`/`TimelineSection` (didefinisikan ulang total di ScheduleView.swift, dipakai render). Dua dunia ini tidak nyambung.
7. `Color("#E8682A")` dkk di `ActivityType` (ScheduleView.swift) — salah initializer (mencari Color Set bernama itu di Asset Catalog, bukan parse hex). Harusnya `Color(hex:)` yang sudah ada di project.
8. `Image("onboard1")`/`Image("onboard2")` dipanggil tapi asset-nya tidak ada di `Assets.xcassets`.
9. Tombol Onboarding-as-Guide (dibuka sebagai `.sheet` dari Home) tidak bisa di-dismiss — cuma set `hasSeenOnboarding = true` tanpa `dismiss()`.
10. `RescheduleSheet.onConfirm` dipanggil dengan closure kosong `{ }` — tombol Reschedule tidak mengubah apapun.
11. `EditProfileView` menampilkan teks debug/scaffold ke user asli ("@State vars", "Winding up...") — harus dibersihkan.
12. Profile "Total Sleep"/"Sleep Pattern" adalah string statis, tidak sinkron dengan `sleepTime`/`wakeTime` aktual.
13. Toggle Notifications tidak menjadwalkan notifikasi apapun — tidak ada `UNUserNotificationCenter` di manapun di project.
14. Tidak ada fitur delete/edit trip.

### 🟡 Konsistensi & kualitas kode
15. **4 sistem warna berbeda** yang tidak saling terhubung: `AppTheme.swift` (`#C45500`), README (`#FFB547` — tidak cocok kode manapun), `OnboardingView.swift extension Color` (3 warna sendiri), `ActivityType.accentColor` (5 warna sendiri). → Diselesaikan lewat `05_DESIGN_SYSTEM.md`.
16. Dua "component library" gaya berbeda: `Components.swift` vs komponen custom inline di `OnboardingView.swift`.
17. `AppState.shared` singleton dipakai langsung dari banyak View — coupling tinggi, susah di-preview/test terisolasi.
18. `utc_offset` di `global_airports.json` statis per bandara (tidak dihitung dari IANA timezone + tanggal) — berisiko salah ±1 jam kalau ada negara ber-DST.
19. Onboarding hardcode `.white` — berpotensi pecah di Dark Mode.
20. Tidak ada design token tipografi — font ad-hoc (`.headline`, `.title2`, dst) di tiap View, tidak konsisten. → Diselesaikan lewat `05_DESIGN_SYSTEM.md`.

---

## 2. Keputusan Arsitektur (SUDAH DIPUTUSKAN — jangan didebat ulang oleh AI)

### A. Single Source of Truth: Model Jadwal
- **`BlockType` + `TimelineBlock` (Models.swift) MENANG.** Alasan: sudah punya `whatToDo`/`alternatives`/`whyItMatters`/`icon`/`color`, dan ini yang dipakai jalur generate.
- **`ActivityType`/`ActivityItem`/`TimelineSection` di `ScheduleView.swift` DIHAPUS TOTAL**, termasuk fungsi konversi manual `ActivityDetailSheet.bt`.
- `BlockType` diperluas jadi 8 tipe sesuai `04_ALGORITHM.md` Section 3: `seekLight`, `avoidLight`, `sleep`, `nap`, `caffeine`, `noCaffeine`, `melatonin`, `flight`.
- `ScheduleView` WAJIB di-refactor supaya render langsung dari `trip.blocks` (via `CircadianEngine`, lihat poin C), bukan `MockSchedule.sections`.

### B. Trip Model
- Sesuai `04_ALGORITHM.md` Section 2: **hanya 1 tipe Trip**, tidak ada `TripType`/round-trip grouping.
- `Trip.flights: [FlightLeg]` tetap array untuk transit/connecting — bukan untuk flight pulang.

### C. Business Logic Dipindah ke Services Layer
- Buat `Services/CircadianEngine.swift` — pure functions sesuai kontrak di `04_ALGORITHM.md` (CBTmin, shift daily, direction, light rules, block generation & non-overlap rules, dst).
- `AppState.generateBlocks(for:)` yang sekarang (template statis) **dihapus/diganti total**, bukan ditambal — panggil `CircadianEngine` sebagai gantinya.
- `Services/NotificationService.swift` — wrapper `UNUserNotificationCenter`, dipanggil setiap kali blocks di-generate/reschedule untuk menjadwalkan local notification dengan timing presisi (lihat `04_ALGORITHM.md` Section 10).
- `Services/PersistenceService.swift` — simpan/load `trips` & `profile` via `Codable` + `UserDefaults`.

### D. Timezone Handling
- `FlightLeg` harus simpan `departure`/`arrival` sebagai `Date` **+ `TimeZone` eksplisit per airport**, bukan asumsi timezone device.
- `DatePicker` di `AddFlightView` harus dikonfigurasi eksplisit pakai `TimeZone` bandara yang dipilih user.
- Direction (eastward/westward) dan UTC Offset Gap dihitung dari `TimeZone` asli tiap leg, bukan dari device.
- Timeline display switch dari origin TZ ke destination TZ tepat di titik arrival (lihat `04_ALGORITHM.md` Section 1.A0).

### E. Design System — Satu Sumber Kebenaran
- **`App/AppTheme.swift` jadi satu-satunya sumber warna & tipografi**, isinya ikut token yang didefinisikan di `05_DESIGN_SYSTEM.md`. Semua warna lain (extension `Color` di `OnboardingView.swift`, `ActivityType.accentColor`) dihapus, direferensikan ulang ke `AppTheme`.
- `Color(hex:)` dipindah ke file utility terpisah (`Utilities/ColorExtensions.swift`).
- `Components.swift` jadi satu-satunya component library. Komponen custom di `OnboardingView.swift` (`ActionBlock`/`DualBlock`/`TripleBlock`) dipindah ke sini atau di-refactor pakai komponen yang sudah ada.

### F. State Management
- `AppState` **tidak lagi singleton** (`.shared` dihapus) — di-inject lewat `.environmentObject()` dari root `ByeJetLagApp`. Logic pindah ke Services (poin C), `AppState` cuma nyimpen `@Published` state + panggil Services.
- **Satu-satunya ViewModel terpisah:** `AddFlightViewModel`, khusus untuk `AddFlightView` karena paling kompleks (multi-step flow + validasi + personalize questions).
- Home, Schedule, Profile baca langsung dari `AppState` via `@EnvironmentObject`, tanpa ViewModel terpisah — logic mereka relatif simpel (nampilin list, nampilin detail, toggle setting).

### G. Dead Code & File Cleanup
- **`SplashView.swift` — dipakai**, disambungkan eksplisit sebagai layar pembuka singkat sebelum app menentukan tujuan ke Onboarding/Home. `ByeJetLagApp.swift` perlu ditambah state sementara (misal `isShowingSplash`) yang menampilkan `SplashView` beberapa detik di awal sebelum keputusan itu diambil.
- `EditProfileView` — hapus semua teks debug/scaffold ("@State vars", "Winding up...").

---

## 3. Struktur Folder Target

```
ByeJetlag/
├── App/
│   ├── ByeJetLagApp.swift
│   └── AppTheme.swift          # satu-satunya sumber warna & font
├── Models/
│   ├── Models.swift            # BlockType, TimelineBlock, FlightLeg, Trip, UserProfile, DailyCheckIn
│   └── Airport.swift
├── Services/
│   ├── CircadianEngine.swift   # pure functions dari 04_ALGORITHM.md
│   ├── NotificationService.swift
│   └── PersistenceService.swift
├── Store/
│   └── AppState.swift          # dipindah keluar dari Models.swift, tidak singleton
├── ViewModels/
│   └── AddFlightViewModel.swift
├── Utilities/
│   └── ColorExtensions.swift   # Color(hex:) pindah ke sini
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── AddFlight/
│   ├── Schedule/
│   └── Profile/
├── Components/
│   └── Components.swift        # satu-satunya component library
└── Resources/
    └── global_airports.json
```
