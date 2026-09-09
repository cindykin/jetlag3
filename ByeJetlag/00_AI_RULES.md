# 00_AI_RULES.md — ByeJetlag AI Engineering Contract

> File ini adalah instruksi kerja untuk AI coding assistant yang mengerjakan ByeJetlag. Baca file ini **sebelum membaca source code atau mengedit apa pun**.

## 1. Tujuan

AI berperan sebagai software engineer yang membantu menstabilkan dan menyelesaikan ByeJetlag, **bukan** sebagai product designer yang bebas menambah requirement baru.

Prioritas utama:
1. correctness,
2. kesesuaian dengan source of truth,
3. perubahan sekecil mungkin,
4. buildability,
5. testability,
6. baru kemudian polish/refactor tambahan.

---

## 2. Mandatory Read Order

Sebelum task coding, baca minimal:

1. `00_AI_RULES.md`
2. `01_PRODUCT.md`
3. `06_CURRENT_STATE.md`
4. `02_ARCHITECTURE.md`
5. `03_MODELS.md`
6. `04_ALGORITHM.md` — wajib untuk task schedule/timezone/CBTmin/light/caffeine/sleep/reschedule/notification
7. `05_DESIGN_SYSTEM.md` — wajib untuk task UI/timeline/onboarding/design
8. source code yang benar-benar terkait task
9. `07_CHANGELOG.md`

Jangan mengandalkan memory chat sebagai pengganti file-file di atas.

---

## 3. Source-of-Truth Hierarchy

Untuk konflik informasi, gunakan urutan ini:

1. `01_PRODUCT.md` untuk scope dan behavior produk.
2. `04_ALGORITHM.md` untuk semua rumus dan aturan schedule/circadian.
3. `02_ARCHITECTURE.md` untuk struktur, ownership, dan dependency.
4. `03_MODELS.md` untuk kontrak data serta status model CURRENT/TARGET.
5. `05_DESIGN_SYSTEM.md` untuk visual/UI.
6. `06_CURRENT_STATE.md` untuk kondisi implementasi terbaru.
7. `07_CHANGELOG.md` untuk riwayat perubahan.
8. Existing source code adalah bukti **CURRENT implementation**, bukan otomatis requirement yang benar.

Jika source code bertentangan dengan source-of-truth, **jangan menyesuaikan dokumen agar mengikuti bug**. Perbaiki implementasinya sesuai task.

Jika prompt baru meminta perubahan product/algorithm yang bertentangan dengan source-of-truth, tandai konflik tersebut secara eksplisit sebelum mengubah kontrak.

---

## 4. CURRENT vs TARGET — Jangan Dicampur

Dokumen menggunakan dua istilah:

- **CURRENT** = yang benar-benar ada di codebase sekarang.
- **TARGET** = arsitektur/behavior yang sudah diputuskan tetapi belum tentu sudah diimplementasi.

AI dilarang mengklaim fitur TARGET sebagai "sudah selesai" tanpa menemukan implementasinya di codebase.

Contoh:
- CURRENT: `ScheduleView` masih memakai `MockSchedule.sections`.
- TARGET: `ScheduleView` render `trip.blocks` yang dihasilkan `CircadianEngine`.

---

## 5. Pre-Edit Protocol

Sebelum menulis kode:

1. Baca file relevan.
2. Cari root cause, bukan hanya symptom.
3. Sebutkan:
   - masalah yang ditemukan,
   - root cause,
   - file yang perlu diubah,
   - file yang **tidak** perlu disentuh,
   - risiko/regresi yang mungkin terjadi.
4. Pilih patch terkecil yang menyelesaikan task.
5. Pastikan patch konsisten dengan TARGET architecture.

Untuk bug kecil, jangan melakukan refactor lintas-project yang tidak diperlukan.

---

## 6. Hard Guardrails

### Dilarang

- Menambahkan WatchOS, Apple Watch, WatchKit, HealthKit, watch target, watch companion, atau logic khusus watch.
- Menambahkan backend, login/auth, cloud sync, atau multi-device sync.
- Menambahkan Gentle Mode, insomnia handling, health screening, atau fitur "Saya terlalu lelah".
- Membuat `TripType`, round-trip grouping, atau menggabungkan flight pulang ke Trip keberangkatan.
- Membuat model jadwal paralel baru selain `BlockType` + `TimelineBlock`.
- Menggunakan `MockSchedule` sebagai data production.
- Meng-hardcode schedule sebagai pengganti rumus di `04_ALGORITHM.md`.
- Menaruh business logic circadian baru di SwiftUI View.
- Menggunakan timezone device sebagai sumber kebenaran untuk waktu flight bandara.
- Menggunakan `utc_offset` statis dari JSON sebagai satu-satunya sumber offset pada tanggal tertentu jika IANA timezone tersedia.
- Menambahkan package/dependency eksternal tanpa kebutuhan yang jelas dan tanpa persetujuan.
- Mengganti design system, nama block, formula, atau product behavior karena "best practice" umum.
- Membuat duplicate helper/component/model bila yang existing bisa dipakai atau diperbaiki.
- Mengubah banyak file hanya untuk "cleanup" saat task sebenarnya sempit.
- Menghapus source code yang belum dipastikan dead code.

### Wajib

- Gunakan `BlockType` + `TimelineBlock` sebagai schedule model tunggal.
- Gunakan IANA timezone identifier untuk timezone logic.
- Simpan banyak Trip sebagai collection (`[Trip]`).
- Pisahkan UI dari business logic.
- Perlakukan `04_ALGORITHM.md` sebagai satu-satunya sumber formula.
- Pertahankan ByeJetlag v1 sebagai **iOS-only**.

---

## 7. Architecture Direction

Target dependency direction:

```text
SwiftUI View
    ↓
AppState / AddFlightViewModel
    ↓
Services
    ↓
Models
```

Yang tidak boleh terjadi:

```text
View → hardcoded algorithm
View → duplicate domain model
Service → SwiftUI View
Model → navigation/UI logic
```

Service target:
- `CircadianEngine` = pure schedule/circadian computation.
- `PersistenceService` = local persistence.
- `NotificationService` = local notification scheduling.

---

## 8. Schedule-Specific Rules

Saat task menyentuh schedule:

1. Baca `04_ALGORITHM.md` penuh.
2. Jangan memakai mock schedule sebagai fallback production.
3. Jangan membuat rumus dari pengetahuan umum jet lag.
4. Jangan sederhanakan eastward/westward light window.
5. Sleep memiliki prioritas tertinggi dalam non-overlap.
6. Melatonin hanya dibuat bila toggle aktif **dan** ada sleep window terkait.
7. Caffeine hanya dibuat bila toggle aktif.
8. `No Caffeine` mengikuti cut-off target sleep - 8 jam.
9. Reschedule maksimal satu kali dan hanya manual.
10. Perhitungan waktu internal berbasis absolute `Date`/UTC; presentation memakai timezone yang benar.

---

## 9. UI-Specific Rules

Saat task menyentuh UI:

- Ikuti `05_DESIGN_SYSTEM.md`.
- Jangan mengubah algoritma hanya agar UI lebih mudah dirender.
- Timeline harus merepresentasikan waktu/durasi sebenarnya.
- Jangan mengganti layout schedule dengan list statis jika target design meminta positioned timeline.
- `AppTheme.swift` adalah target single source of truth untuk warna/font.
- Gunakan reusable component daripada duplicate component inline bila sudah ada kontraknya.
- Pertahankan accessibility dasar SwiftUI: dynamic type, label yang jelas, tap target wajar.

---

## 10. Navigation & Onboarding Rules

- Onboarding utama hanya muncul sekali berdasarkan persisted flag.
- Membuka onboarding sebagai Guide dari Home **tidak boleh** merusak persisted onboarding state atau membuat sheet tidak bisa ditutup.
- Navigation state tidak boleh dipalsukan dengan boolean yang saling bertabrakan jika `NavigationStack`/sheet sudah bisa menangani flow dengan jelas.
- Perubahan navigation tidak boleh mengubah product flow tanpa kebutuhan task.

---

## 11. Persistence & Notification Rules

Persistence:
- Data user/trip tidak boleh hilang setelah force quit setelah persistence diimplementasikan.
- Storage tetap local-only.
- Jangan migrasi ke cloud/backend.

Notification:
- Gunakan local notification (`UNUserNotificationCenter`).
- Identifier harus unik per Trip/leg/event agar tidak saling override.
- Notification yang sudah tidak valid harus bisa dibatalkan/reschedule secara deterministik.

---

## 12. Verification Protocol

Setelah edit:

1. Compile/build project bila `.xcodeproj`/workspace tersedia.
2. Jika build tidak bisa dilakukan karena project file tidak tersedia, katakan **build not verified**; jangan mengklaim sukses build.
3. Jalankan test yang relevan bila ada.
4. Untuk algorithm logic, tambahkan unit-testable pure functions sebelum UI test bila memungkinkan.
5. Search codebase untuk duplicate/dead references yang seharusnya sudah hilang setelah refactor.
6. Review regressions pada navigation, timezone, persistence, dan schedule rendering sesuai scope.

Jangan menyatakan "fixed" hanya karena kode terlihat masuk akal.

---

## 13. Documentation Update Protocol

Setelah setiap patch yang benar-benar diterapkan:

### Update `06_CURRENT_STATE.md`
Pindahkan item dari TODO/BROKEN ke IMPLEMENTED hanya jika benar-benar ada di codebase dan sudah diverifikasi sebisa mungkin.

### Append `07_CHANGELOG.md`
Catat:
- tanggal,
- task,
- files changed,
- root cause,
- change summary,
- verification,
- known limitations,
- next recommended step.

Jangan rewrite history changelog.

---

## 14. Required AI Response Format untuk Coding Task

Gunakan struktur ringkas:

```text
UNDERSTANDING
- task yang akan dikerjakan
- source-of-truth yang relevan

ROOT CAUSE
- penyebab utama

FILES TO CHANGE
- file A — alasan
- file B — alasan

FILES NOT TO TOUCH
- ...

IMPLEMENTATION
- perubahan yang dilakukan

VERIFICATION
- build/test/static checks

DOC UPDATES
- CURRENT_STATE
- CHANGELOG

KNOWN LIMITATIONS / NEXT STEP
- ...
```

Untuk task yang sangat kecil, format boleh diringkas tetapi prinsipnya tetap sama.

---

## 15. Definition of Done

Sebuah task dianggap selesai hanya jika:

- memenuhi requirement,
- tidak melanggar guardrail,
- tidak menambah duplicate domain model,
- tidak memakai mock sebagai production logic,
- relevant state/data flow tersambung end-to-end,
- diverifikasi sebisa mungkin,
- dokumentasi state/changelog diperbarui.
