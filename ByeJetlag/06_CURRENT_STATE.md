# 06_CURRENT_STATE.md — ByeJetlag Implementation Status

> **Snapshot:** 2026-09-10, berdasarkan source tree di `ByeJetlag`. File ini harus diperbarui setiap patch. Jangan menganggap TARGET sudah implemented jika belum dipindahkan ke bagian Implemented.

## 1. Project Snapshot

Source tree yang ditemukan:

```text
ByeJetlag/
├── App/
│   ├── AppTheme.swift
│   └── ByeJetLagApp.swift
├── Models/
│   ├── Airport.swift
│   └── Models.swift
├── Views/
│   ├── AddFlight/
│   ├── Components/
│   ├── Home/
│   ├── Onboarding/
│   ├── Profile/
│   └── Schedule/
├── Resources/global_airports.json
├── Assets.xcassets/
├── PRODUCT_OVERVIEW.md
├── ARCHITECTURE.md
├── ALGORITHM_SPEC.md
└── DESIGN_SYSTEM.md
```

---

## 2. Implemented / Exists in CURRENT Code

- [x] SwiftUI app entry (`ByeJetLagApp`).
- [x] Root onboarding gate menggunakan `@AppStorage("hasSeenOnboarding")`.
- [x] Home screen.
- [x] Add Flight flow.
- [x] Airport picker + `global_airports.json`.
- [x] Profile UI.
- [x] Schedule UI exists.
- [x] `BlockType` dengan 8 block cases exists.
- [x] `TimelineBlock` exists.
- [x] `Trip` memakai `flights: [FlightLeg]` dan app state memakai `trips: [Trip]`.
- [x] `UserProfile` memiliki toggle caffeine/melatonin/notification.
- [x] Existing knowledge base untuk product/architecture/algorithm/design.
- [x] `ScheduleView` render dari `trip.blocks` (`[TimelineBlock]`), bukan duplicate model.
- [x] Duplicate domain model (`ActivityType`, `ActivityItem`, `TimelineSection`, `MockSchedule`) dihapus dari `ScheduleView.swift`.
- [x] `AppState` dibuat sekali di root `ByeJetLagApp` dan di-inject melalui `.environmentObject()`.
- [x] `BlockType` memiliki foreground, background, dan SF Symbols sesuai `05_DESIGN_SYSTEM.md` Section 2–3; timeline dan block detail mengonsumsi mapping tersebut. *(2026-09-10)*

> Checklist di atas hanya berarti code/structure ditemukan, **bukan berarti behavior sudah benar**.

---

## 3. Critical Broken / Not Yet Correct

### Schedule / Algorithm
- [x] `ScheduleView` sekarang render `trip.blocks`, bukan `MockSchedule.sections`. *(2026-09-10)*
- [x] `ScheduleView.swift` tidak lagi mendefinisikan `ActivityType`, `ActivityItem`, `TimelineSection` — dihapus total. *(2026-09-10)*
- [ ] `AppState.generateBlocks(for:)` masih hardcoded schedule template.
- [ ] `CircadianEngine` belum ada.
- [ ] CBTmin calculation belum terimplementasi sebagai engine.
- [ ] Eastward/westward direction + adaptation rule belum terimplementasi sesuai spec.
- [ ] Loading shift (`Shift_daily`) belum terimplementasi sesuai spec.
- [ ] Non-overlap schedule rules belum terimplementasi secara authoritative.
- [ ] Daily check-in model/flow belum ditemukan pada codebase.
- [ ] Manual reschedule 1x belum bekerja; CURRENT `RescheduleSheet` dipanggil dengan closure kosong.

### Timezone
- [ ] `FlightLeg` belum menyimpan timezone origin/destination eksplisit.
- [ ] `AddFlightView` DatePicker masih tidak timezone-aware.
- [ ] Offset/direction belum dihitung dari IANA timezone pada tanggal flight.
- [ ] Timeline timezone switch pada arrival belum terhubung ke data real.

### Persistence
- [ ] `trips` dan `profile` masih memory-only pada `AppState`.
- [ ] Force quit akan kehilangan state tersebut.
- [ ] `PersistenceService` belum ada.

### Notifications
- [ ] `NotificationService` belum ada.
- [ ] `UNUserNotificationCenter` belum terintegrasi.
- [ ] Notification toggle belum menjadwalkan event real.

---

## 4. Known UI / UX Bugs

- [x] `ScheduleView` mengikuti data flow real (`trip.blocks`). *(2026-09-10)*
- [x] Schedule timeline berbasis `TimelineBlock` duration/time, bukan mock section model. *(2026-09-10)*
- [x] Warna dan ikon untuk delapan `BlockType` sesuai tabel design system. *(2026-09-10)*
- [ ] Token warna non-schedule masih belum seluruhnya dikonsolidasikan ke `AppTheme`.
- [ ] `Image("onboard1")` dan `Image("onboard2")` dipanggil tetapi asset tersebut tidak ditemukan pada `Assets.xcassets` archive.
- [ ] Onboarding yang dibuka sebagai Guide dari Home tidak memiliki dismissal behavior yang benar; aksi utama hanya mengubah `hasSeenOnboarding`.
- [ ] Onboarding masih memiliki color extension/component inline yang bertabrakan dengan target design system.
- [ ] Profile `totalSleep` / `sleepPattern` masih string statis dan dapat tidak sinkron dengan sleep/wake input.
- [ ] `EditProfileView` memiliki scaffold/debug text menurut audit existing.
- [ ] Delete/edit Trip belum ada.

---

## 5. Architecture Debt

- [x] `AppState.shared` dihapus; Home, Add Flight, dan Profile membaca instance yang sama melalui `@EnvironmentObject`. *(2026-09-10)*
- [ ] `AppState` masih berada dalam `Models.swift`.
- [ ] Services layer target belum dibuat.
- [ ] `AddFlightViewModel` target belum dibuat.
- [ ] Component source of truth belum sepenuhnya dikonsolidasikan.
- [ ] `Color(hex:)` masih belum berada di utility target tunggal.

---

## 6. Onboarding Status — Detail

CURRENT root app sudah mempunyai persisted gate:

```swift
@AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
```

Artinya fondasi "onboarding hanya tampil sekali" **sudah ada** di entry point.

Namun masih ada problem berbeda:
- Onboarding juga dipakai sebagai Guide melalui sheet dari Home.
- `Let's Go`/`Skip` pada screen onboarding hanya mengubah flag.
- Saat dipakai sebagai sheet guide, perubahan flag tidak otomatis menjadi mekanisme dismiss yang benar.

Jadi task onboarding berikutnya seharusnya **memisahkan first-run completion dari guide dismissal**, bukan mengganti seluruh flow tanpa alasan.

---

## 7. WatchOS Status

- [x] Scope product menyatakan WatchOS/Apple Watch/HealthKit **out of scope**.
- [x] Source tree archive yang diaudit tidak menunjukkan target/folder WatchOS.
- [ ] Setiap patch v1 harus terus memastikan tidak ada dependency/target/feature WatchOS yang ditambahkan.

---

## 8. Recommended Execution Order dari Snapshot Ini

Urutan ini dibuat untuk mengurangi rework:

### Phase 0 — Baseline Safety
- [ ] Pastikan local project yang sebenarnya memiliki `.xcodeproj`/workspace dan dapat build.
- [ ] Buat git baseline commit sebelum refactor besar.
- [ ] Pastikan deployment target dan supported iOS version diketahui dari Xcode project asli.

### Phase 1 — Data Contract + Architecture Minimum
- [ ] Hilangkan duplicate schedule domain model.
- [ ] Pisahkan `AppState` dari Models dan siapkan service boundary.
- [ ] Pastikan perubahan tidak menyentuh WatchOS.

### Phase 2 — Timezone Correctness
- [ ] Tambahkan explicit airport timezone semantics pada `FlightLeg`/AddFlight flow.
- [ ] Perbaiki DatePicker/local-time conversion.
- [ ] Verifikasi departure/arrival absolute instants.

### Phase 3 — Circadian Engine
- [ ] Implement pure CBTmin/direction/gap/shift/light/caffeine helpers.
- [ ] Implement block generation.
- [ ] Implement non-overlap rules.
- [ ] Tambahkan unit tests untuk pure algorithm functions.

### Phase 4 — Schedule Integration + UI
- [ ] `ScheduleView` render `trip.blocks` real.
- [ ] Terapkan positioned timeline sesuai design system.
- [ ] Implement arrival/midnight timezone divider.
- [ ] Hapus `MockSchedule` dari production path.

### Phase 5 — Onboarding + Navigation
- [ ] Pertahankan first-run onboarding sekali.
- [ ] Fix Guide dismissal behavior.
- [ ] Rapikan navigation state dan route AddFlight → Trip/Schedule.

### Phase 6 — Persistence + Notifications
- [ ] Implement local persistence.
- [ ] Implement notification permission + deterministic schedule/cancel/reschedule.
- [ ] Pastikan multi-trip notification identifiers tidak collide.

### Phase 7 — Regression / Polish
- [ ] Profile cleanup.
- [ ] Missing assets/design consistency.
- [ ] delete/edit trip bila masih termasuk v1 delivery scope.
- [ ] end-to-end test minimal 2 arah timezone + transit case.

---

## 9. Next Task Recommended

**Task berikutnya yang paling aman:** baseline + schedule data-model unification.

Target patch pertama:
1. Pastikan project build di Xcode lokal.
2. Refactor `ScheduleView` agar berhenti bergantung pada duplicate domain model/mock untuk jalur production.
3. Jangan implement semua formula sekaligus pada patch yang sama bila belum ada timezone model yang benar.
4. Update file ini + `07_CHANGELOG.md` setelah patch.

---

## 10. Last Knowledge-Base Update

**2026-09-09** — Paket AI knowledge base dibuat dari archive yang di-upload. Tidak ada `.swift` file yang diubah oleh proses dokumentasi ini.
