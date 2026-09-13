# 07_CHANGELOG.md — ByeJetlag Engineering Changelog

> Append-only engineering log untuk perubahan yang dilakukan AI/developer. Jangan hapus entry lama. Changelog ini bukan release notes marketing.

## Rules

Setiap patch harus mencatat:
- tanggal,
- task,
- root cause,
- files changed,
- behavior changed,
- verification,
- known limitations,
- next recommended step.

Gunakan satu entry per logical patch. Jangan menulis "fixed" bila build/test belum diverifikasi.

---

## 2026-09-09 — AI Knowledge Base Consolidation

### Task
Menyusun paket knowledge base yang konsisten untuk AI-assisted development ByeJetlag.

### Root Cause
Existing project sudah memiliki product, architecture, algorithm, dan design documentation, tetapi belum memiliki kontrak kerja AI, model contract terpisah, implementation status snapshot, dan changelog engineering.

### Files Added in Knowledge-Base Package
- `00_AI_RULES.md`
- `01_PRODUCT.md`
- `02_ARCHITECTURE.md`
- `03_MODELS.md`
- `04_ALGORITHM.md`
- `05_DESIGN_SYSTEM.md`
- `06_CURRENT_STATE.md`
- `07_CHANGELOG.md`

### Source Code Changed
None.

### Verification
- Archive structure inspected.
- Existing knowledge-base files inspected.
- Key Swift symbols searched to cross-check CURRENT state.

### Known Limitations
- Snapshot hanya merepresentasikan archive yang diberikan pada 2026-09-09.
- Local Xcode project dapat memiliki file/setting tambahan yang tidak ikut archive.

### Next Recommended Step
Establish a buildable baseline from the real Xcode project, then perform the first small architecture patch: unify schedule domain model/data flow without yet inventing new algorithm behavior.

---

## 2026-09-10 — Inject AppState from App Root

### Task
Remove the `AppState.shared` singleton and inject one `AppState` instance from `ByeJetLagApp` with `.environmentObject()`.

### Root Cause
Views owned a global `AppState.shared` through `@StateObject`, creating direct singleton coupling and preventing root-controlled state injection.

### Files Changed
- `App/ByeJetLagApp.swift` — create and inject the root-owned `AppState`.
- `Models/Models.swift` — remove the singleton and expose an initializer for root/preview injection.
- `Views/Home/HomeView.swift` — consume injected state and provide isolated preview instances.
- `Views/AddFlight/AddFlightView.swift` — consume injected state.
- `Views/Profile/ProfileView.swift` — consume injected state in profile and edit-profile screens.
- `06_CURRENT_STATE.md` — record the implemented state-management change.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- The app creates one `AppState` at its SwiftUI root; descendant views use that same instance through `@EnvironmentObject`.
- `generateBlocks(for:)` was not modified.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: No test targets/files found.
- Static checks/manual checks: confirmed no `AppState.shared` references remain and every direct `AppState` consumer is supplied by the root environment or its preview.

### Known Limitations
- `AppState` remains in `Models.swift`; moving it to the target `Store/` boundary is a separate architecture task.
- Schedule generation remains the existing hardcoded template by task constraint.

### Next Recommended Step
Move `AppState` to `Store/AppState.swift` while preserving the new injection path, then introduce the service boundary separately.

---

## 2026-09-10 — Align BlockType Visual Mapping

### Task
Match every `BlockType` foreground/background color and SF Symbol with `05_DESIGN_SYSTEM.md` Sections 2–3.

### Root Cause
`BlockType` and a private `ScheduleView` extension contained ad-hoc visual mappings that differed from the design-system table. Multi-symbol block types also had no shared model representation.

### Files Changed
- `Models/Models.swift` — define the specified foreground/background colors and one-or-more SF Symbols per block type.
- `Views/Schedule/ScheduleView.swift` — remove duplicate visual mapping and render `BlockType` colors/icons, including icon groups.
- `Views/Components/Components.swift` — render block cards and detail headers from the shared colors/icon groups.
- `06_CURRENT_STATE.md` — record the implemented mapping.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- Each of the eight block types now uses exactly the table's foreground and background hex values.
- Multi-icon types render their specified SF Symbols together in an `HStack`.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: No test targets/files found.
- Static checks/manual checks: verified the eight mappings against the Section 2–3 table and confirmed `ScheduleView` no longer defines alternate block colors or icons.

### Known Limitations
- Non-schedule color tokens remain to be consolidated into `AppTheme` in a separate design-system task.

### Next Recommended Step
Move the remaining non-schedule color definitions into `AppTheme` without changing the approved block visual mapping.

---

## 2026-09-10 — Replace Static Schedule Template with CircadianEngine

### Task
Fix root environment injection compilation, create a pure circadian engine, add basic unit tests, and replace `AppState.generateBlocks(for:)`'s static template.

### Root Cause
The root environment modifier was applied to a conditional result rather than a concrete container. Schedule generation was a fixed four-day template that ignored profile sleep, UTC offset direction, preparation days, and conditional rules.

### Files Changed
- `App/ByeJetLagApp.swift` — wrap the onboarding/home conditional in `Group` before environment injection.
- `Services/CircadianEngine.swift` — add pure calculation and generation functions.
- `Tests/CircadianEngineTests.swift` — add CBTmin, shift, and direction/12-hour-rule tests.
- `Models/Models.swift` — replace the entire static generator with engine delegation using airport IANA timezones.
- `06_CURRENT_STATE.md` — update implementation status and remaining test-target limitation.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- Blocks are generated from profile sleep/wake times, actual airport timezone offsets on flight dates, direction-specific light windows, preparation-day shift, caffeine cutoff, and conditional caffeine/melatonin rules.
- Sleep has exclusive priority; other generated blocks are split or removed where they overlap Sleep.
- The root `AppState` environment is applied to a `Group`, resolving the SwiftUI modifier error.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: Added `CircadianEngineTests`, but could not run because no test target/project is available.
- Static checks/manual checks: `swiftc -typecheck` passed for Models, Airport, Onboarding Color support, and CircadianEngine; only a pre-existing Airport deprecation warning was emitted. A full source type-check is blocked by the local toolchain's unavailable `PreviewsMacros` plugin.

### Known Limitations
- `FlightLeg` still does not persist explicit origin/destination timezone identifiers; `AppState` resolves them from the airport database during generation.
- The test source is not registered in an Xcode target until a project file is supplied.

### Next Recommended Step
Add explicit persisted IANA timezone identifiers to `FlightLeg` and configure the engine tests in the real Xcode project.

---

## 2026-09-10 — Resolve App-Target Build Diagnostics

### Task
Resolve the reported root environment, XCTest module, and deprecated locale API build diagnostics.

### Root Cause
The build target treated the XCTest source as application code, and the root environment modifier remained attached to a conditional builder. The airport helper used an API deprecated on iOS 16.

### Files Changed
- `App/ByeJetLagApp.swift` — inject the root state directly into each concrete root view branch.
- `Tests/CircadianEngineTests.swift` — compile XCTest tests only when XCTest is available to the target.
- `Models/Airport.swift` — use `Locale.Region.isoRegions`.
- `Views/Home/HomeView.swift` — make the stateful preview setup a single expression, avoiding a `Void` expression in `ViewBuilder`.
- `06_CURRENT_STATE.md` — record the root-injection and test-target state.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- The app root gives both Home and Onboarding the same injected `AppState` without applying a modifier to the conditional builder.
- App builds that do not link XCTest exclude the test declaration; a proper XCTest target still compiles and runs it.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is available.
- Tests: Not run; no test target is available.
- Static checks/manual checks: full source type-check no longer reports the root environment, XCTest, self-import, airport deprecation, or Home preview `ViewBuilder` diagnostics. It remains blocked only by the local toolchain's unavailable `PreviewsMacros` plugin.

### Known Limitations
- `CircadianEngineTests` must still be assigned to an XCTest target in the real Xcode project.

### Next Recommended Step
Open the real Xcode project, add `Tests/CircadianEngineTests.swift` to its unit-test target, and run the suite.

---

## 2026-09-10 — Generate Destination Naps and Daily Caffeine Windows

### Task
Add destination daytime naps, replace arrival-only caffeine with daily wake-to-cutoff windows, and cover the generation pipeline with eastward and westward XCTest cases.

### Root Cause
The engine did not generate naps and created caffeine only near daytime arrival, which did not implement the required daily caffeine window. Wake time was also derived from the end of the upcoming sleep window rather than the wake period preceding that target sleep.

### Files Changed
- `Services/CircadianEngine.swift` — generate 30-minute 13:00 destination naps, generate conditional daily caffeine windows, correct the wake anchor, and treat full-session melatonin as sleep-equivalent.
- `Tests/CircadianEngineTests.swift` — add deterministic eastward and westward generation-pipeline cases with concrete inputs and expected local times in comments.
- `06_CURRENT_STATE.md` — record implemented nap/caffeine behavior and pending test-target execution.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- Each generated schedule includes a 13:00–13:30 destination-local nap, subject to Sleep exclusivity.
- With caffeine enabled, each day receives a caffeine block from wake time through `targetSleep − 8 hours`; the former arrival-only caffeine block is removed.
- A melatonin-enabled sleep session is represented by one full-duration `.melatonin` block and receives Sleep's overlap priority.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: XCTest sources parse successfully but cannot run until assigned to a test target.
- Static checks/manual checks: updated Models/Engine type-check passed; `git diff --check` passed. The new pipeline tests document and assert concrete eastward/westward caffeine and nap windows.

### Known Limitations
- Nap time is a deterministic 13:00 destination-local window because Section 3 supplies the maximum duration but no individualized nap-time formula.
- Reschedule behavior remains unchanged.

### Next Recommended Step
Assign `CircadianEngineTests.swift` to the real XCTest target and run both pipeline scenarios in Xcode.

---

## 2026-09-11 — Persist Airport Timezones on Flight Legs

### Task
Make flight-time entry timezone-aware, persist airport IANA timezone identifiers on each `FlightLeg`, and stop schedule generation from re-looking-up airport timezones.

### Root Cause
`FlightLeg` stored only absolute dates, while `DatePicker` used the device timezone and `AppState` later re-derived timezone context from the mutable airport database. This contradicted the UI's local-airport-time claim.

### Files Changed
- `Models/Models.swift` — add origin/destination IANA timezone IDs and read them directly when invoking the engine.
- `Views/AddFlight/AddFlightView.swift` — capture timezone IDs from airport selections, render/persist date picker values in airport timezones, and format itinerary times in their respective airport timezones.
- `06_CURRENT_STATE.md` — mark verified FlightLeg and DatePicker timezone work.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- Airport selection writes its IANA timezone identifier into the corresponding leg.
- Departure and arrival pickers use the origin and destination timezone respectively. Their bindings extract local date components in that timezone and recreate the absolute `Date` through `Calendar.date(from:)`.
- `AppState.generateBlocks(for:)` now reads timezone IDs from the trip's own legs, not `AirportStore`.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: Existing XCTest target is unavailable.
- Static checks/manual checks: Models/Engine type-check and AddFlight/test-source parse checks passed; `git diff --check` passed. Manual trace: Paris `Europe/Paris` local `2026-01-15 14:00` resolves to stored `2026-01-15T13:00:00Z`; it displays as `2026-01-15 20:00 GMT+7` on a Jakarta device but remains `14:00` when formatted in Paris.

### Known Limitations
- Existing in-memory legs created before this change have empty timezone IDs and cannot generate schedule blocks until recreated/edited; persistence and migration are not yet implemented.
- Timeline timezone divider behavior remains a separate UI task.

### Next Recommended Step
Add a migration strategy when persistence is introduced, then implement the arrival/midnight timezone divider using the IDs stored on each flight leg.

---

## 2026-09-11 — Implement One-Time Manual Reschedule

### Task
Implement the manual, per-Trip reschedule flow with a single allowed use, actual sleep start/stop input, and regenerated blocks.

### Root Cause
The schedule exposed reschedule outside the required block-detail flow, its confirmation closure did nothing, and no state prevented repeated use.

### Files Changed
- `Models/Models.swift` — add `Trip.hasRescheduled` and the guarded `AppState.rescheduleTrip` mutation.
- `Views/Schedule/ScheduleView.swift` — trigger reschedule only from block detail, refresh the updated Trip, and hide the action after use.
- `Views/Components/Components.swift` — correct the modal's one-time copy and sleep-stop input label.
- `Tests/CircadianEngineTests.swift` — cover CBTmin, regenerated blocks, and second-use rejection.
- `06_CURRENT_STATE.md` — record the implemented one-time flow.
- `07_CHANGELOG.md` — record this patch.

### Behavior Changed
- A Trip starts with `hasRescheduled == false` and can be rescheduled only once from a block-detail screen.
- Confirmation derives CBTmin with `CircadianEngine.cbtMin(actualSleepEnd)`, uses the actual sleep inputs as the new profile baseline, regenerates the Trip's blocks, and then marks the Trip as rescheduled.
- Once marked, the Reschedule button is absent from every block-detail sheet for that Trip; it is not merely disabled.

### Verification
- Build: NOT VERIFIED — no `.xcodeproj` or workspace is present in the available source tree.
- Tests: Added the reschedule XCTest, but no XCTest target is available to execute it.
- Static checks/manual checks: Models/Engine type-check and Schedule/Components/test-source parse checks passed; `git diff --check` passed. The reschedule mutation guards the Trip ID and `hasRescheduled` before making any state change.

### Known Limitations
- The app remains memory-only, so the one-time flag will not survive force quit until persistence is implemented.
- Timezone divider behavior was not changed.

### Next Recommended Step
Register the XCTest source in the real test target, then add persistence for the Trip reschedule flag and regenerated blocks.

---

## 2026-09-11 — Timezone Divider pada Schedule Timeline

### Task
Menambahkan timezone divider di `ScheduleView` sesuai `04_ALGORITHM.md` Section 9 dan `05_DESIGN_SYSTEM.md` Section 5.

### Root cause
Timeline sebelumnya hanya merender section harian tanpa penanda eksplisit ketika pengguna melewati timezone baru atau batas tengah malam lokal.

### Files changed:
  - `Views/Schedule/ScheduleView.swift`
  - `06_CURRENT_STATE.md`

### Behavior changed:
  - Menampilkan divider dengan badge `{Nama Kota} Time` + ikon jam hanya pada titik flight arrival yang berpindah timezone.
  - Menampilkan divider tanggal/jam saja pada tengah malam lokal tanpa perpindahan timezone.
  - Tidak menambahkan divider pada kondisi lain.
  - Top navigation bar tetap tidak berubah.
### Verification:** Source review dilakukan terhadap implementasi divider dan referensi requirement Section 9/Section 5. Build belum dijalankan pada environment ini.
- **Known limitations:** Validasi visual final masih perlu dilakukan melalui simulator/device.
- **Next recommended step:** Jalankan preview/simulator untuk memastikan spacing dan alignment divider sesuai design system.

---

## 2026-09-11 — Fix: Timeline Day-Grouping Memakai Device Timezone, Bukan Airport Timezone

### Task
Audit implementasi timezone divider (`04_ALGORITHM.md` Section 9, `05_DESIGN_SYSTEM.md` Section 5) yang sudah ada dari entry sebelumnya di changelog ini, sebelum dianggap selesai.

### Root Cause
`buildSections()` mengelompokkan `TimelineBlock` per hari menggunakan `Calendar.current` (timezone device), dan `makeDividerInfo()` memakai `.current` untuk cek midnight-tanpa-perpindahan-timezone. Ini bertentangan dengan single-source-of-truth timezone yang sudah dibangun di `FlightLeg.originTimeZoneID`/`destinationTimeZoneID` (patch 2026-09-11 sebelumnya): kalau timezone device pengguna tidak sama dengan timezone airport origin/destination yang sedang berlaku, batas hari, posisi grid per-jam, dan label tanggal/jam section header semuanya ikut bergeser secara salah — bukan cuma teks divider.

### Files Changed
- `Views/Schedule/ScheduleView.swift` — tambah helper `activeTimeZone(at:flights:)` (origin tz sebelum departure pertama, destination tz sejak arrival leg terkait), pakai helper ini di `buildSections()` untuk day-grouping + format `DateFormatter`, dan teruskan ke `makeDividerInfo()` untuk cek midnight.
- `06_CURRENT_STATE.md` — update baris Timezone section.

### Behavior Changed
- Pengelompokan hari, posisi vertikal block pada grid jam, label tanggal/jam section header, dan cek midnight untuk divider sekarang semuanya konsisten memakai timezone airport yang aktif di titik waktu tersebut — bukan timezone device.
- Badge `{Kota} Time` pada flight-arrival divider tidak berubah logikanya (masih bandingkan identifier origin vs destination tz).

### Verification
- Build: NOT VERIFIED (tidak ada toolchain Xcode/Swift di environment ini — perlu di-build manual di Xcode).
- Tests: Tidak ada test baru ditambahkan untuk perubahan ini; `CircadianEngineTests` tidak tersentuh.
- Static/manual checks: Source review — semua call-site `buildSections`/`makeDividerInfo` sudah konsisten dengan signature baru; preview `#Preview("Jakarta → Paris")` tetap kompatibel (FlightLeg tanpa timezone ID eksplisit fallback ke `.current` secara graceful, tidak crash).

### Known Limitations
- Belum divalidasi di simulator/device — terutama kasus device di timezone berbeda dari kedua airport, dan kasus multi-leg (>2 flight) untuk urutan `activeTimeZone`.
- Belum ada unit test untuk `activeTimeZone`/`buildSections`/`makeDividerInfo` karena ketiganya `private` di file View — pertimbangkan extract ke Services/ kalau mau di-cover XCTest.

### Next Recommended Step
Build & jalankan di simulator dengan device timezone yang sengaja beda dari kedua airport trip (misal device WIB, trip Jakarta→Paris), verifikasi grid/label tetap benar. Kalau lolos, lanjut ke Persistence (trips/profile masih memory-only).

---

## 2026-09-11 — Rewrite: Boundary-Based Timeline Segmentation + Block Splitting

### Task
Rewrite `buildSections()`/`makeDividerInfo()` di `ScheduleView.swift` — bukan ditambal — karena pendekatan pengelompokan per-hari berdasarkan `block.startTime` punya 2 bug struktural:
1. Block yang melintasi tengah malam (mis. Sleep 22:00–06:00) tidak pernah displit, jadi divider tengah malam untuk rentang itu tidak pernah muncul.
2. `makeDividerInfo()` mengecek "block pertama section mulai PERSIS di `flight.arrival`" — nyaris tidak pernah cocok karena block jarang mulai tepat di waktu arrival, jadi badge kota nyaris tidak pernah muncul secara reliable.

### Root Cause
Desain lama menurunkan segmen timeline dari data block (`block.startTime`), padahal seharusnya sebaliknya: segmen ditentukan dari boundary trip itu sendiri (midnight & flight arrival timezone-baru), lalu block yang overlap boundary di-split mengikuti segmen — bukan block yang menentukan ada/tidaknya segmen.

### Files Changed
- `Services/ScheduleTimelineBuilder.swift` **(baru)** — `computeBoundaries`, `activeTimeZone`, `buildSections`, `dividerInfo`, plus model `TimelineBoundary`/`BoundaryKind`/`DaySection`/`PositionedBlock`/`TimezoneDividerInfo`. Dipindah dari `ScheduleView.swift` (tadinya `private`) supaya bisa di-unit-test tanpa trik `@testable` terhadap `private`.
- `Views/Schedule/ScheduleView.swift` — hapus definisi duplikat, sekarang cuma konsumsi tipe/fungsi dari file Services baru.
- `Tests/ScheduleTimelineBuilderTests.swift` **(baru)** — 4 test case (lihat Verification).
- `06_CURRENT_STATE.md` — update Timezone section + tambah temuan bug baru di Schedule/Algorithm (lihat di bawah).

### Behavior Changed
- Boundary (midnight lokal / flight arrival ke timezone baru) dihitung sekali di muka dari `flights` + rentang trip — independen dari block manapun.
- Block yang overlap lebih dari satu segmen (mis. Sleep melintasi tengah malam) sekarang displit jadi beberapa `PositionedBlock`, masing-masing dengan `id` unik tapi tetap `sourceBlockID` ke block asli (tap-to-detail tetap buka block utuh, bukan potongan).
- Tiap segmen SELALU punya header tanggal+jam (`SectionHeader`, tidak berubah). Badge `{Kota} Time` cuma muncul kalau segmen itu dibuka oleh boundary jenis arrival-timezone-baru — tidak untuk midnight biasa, tidak untuk segmen pertama trip (bukan boundary yang "dilintasi" user, itu cuma titik mulai).
- Same-timezone connecting flight (mis. domestic leg) TIDAK memicu badge kota — cuma perpindahan timezone asli yang memicu.

### Verification
- Build: NOT VERIFIED (tidak ada toolchain Xcode/Swift di environment ini).
- Tests written (belum dijalankan, perlu register ke test target di Xcode):
  - `testSleepBlockCrossingMidnightIsSplitAcrossTwoSegments` — Sleep 22:00–06:00 UTC tanpa flight sama sekali → harus jadi 2 segmen, 2 potongan (durasi total 8 jam), `sourceBlockID` sama, `id` beda, segmen kedua divider tanpa badge kota, segmen pertama tanpa divider.
  - `testFlightArrivalIntoNewTimezoneProducesCityBadgeEvenWithoutABlockStartingThere` — block sengaja mulai 3 jam SETELAH arrival (bukan persis di titik arrival) → tetap harus ketemu segmen dengan badge "CDG".
  - `testConnectingFlightWithinSameTimezoneProducesNoCityBadge` — leg CGK→DPS (sama-sama Asia/Jakarta) → tidak boleh ada badge kota sama sekali.
  - `testEverySegmentHasADateAndTimeLabelRegardlessOfDividerType` — setiap segmen (apapun jenis boundary-nya) harus tetap punya `dateLabel`/`localTimeLabel` terisi.
- Static/manual checks: Source review menyeluruh terhadap `buildSections`/`computeBoundaries`/`dividerInfo`; semua call-site di `ScheduleView.swift` sudah dicek konsisten (tidak ada sisa referensi ke fungsi/struct lama yang `private`).

### Known Limitations
- Belum divalidasi di simulator/device sungguhan atau lewat `xcodebuild test`.
- File baru `ScheduleTimelineBuilder.swift`/`ScheduleTimelineBuilderTests.swift` perlu ditambahkan manual ke target yang benar di Xcode (app target untuk yang pertama, test target untuk yang kedua) — belum ada `.xcodeproj` di archive yang di-audit sesi ini.
- Investigasi terpisah menemukan **bug lain, di luar scope task ini**, yang kemungkinan jadi penyebab konkret "hari cuma keliatan Sleep": `CircadianEngine.generateBlocks` tidak menerapkan `adaptationRate` pada hari-hari recovery pasca-arrival (`completedShiftDays` beku di nilai preparation, tidak progresif sesuai `04_ALGORITHM.md` Section 6/7). Ditelusuri manual (bukan dijalankan) — lihat detail & mekanisme lengkap di `06_CURRENT_STATE.md` bagian Schedule/Algorithm. **Ini bug di `CircadianEngine.swift`, bukan di `ScheduleView.swift`** — split/boundary fix di atas tidak akan menyelesaikannya.

### Next Recommended Step
1. Tambahkan `ScheduleTimelineBuilder.swift` & `ScheduleTimelineBuilderTests.swift` ke target Xcode yang benar, jalankan build + test.
2. Buat task terpisah untuk fix `completedShiftDays`/`dailyShift` di `CircadianEngine.swift` supaya progresif pakai `adaptationRate` pada hari recovery — ini prioritas lebih tinggi dari polish UI karena langsung mempengaruhi kebenaran jadwal yang ditampilkan ke user.

---

## 2026-09-12 — Investigasi Ditutup: "00:00 Ganda" adalah Expected Behavior, Bukan Bug — Ditambahkan Disambiguation

### Task
Lanjutan investigasi debug print sesi sebelumnya: hapus semua `print()` temporary, laporkan temuan.

### Temuan
`buildSections()`/`computeBoundaries()` **sudah benar secara kronologis** — tidak ada bug hitungan. Yang sempat kelihatan aneh dari log: saat pesawat melintasi tengah malam **di timezone asal** (sebelum arrival), lalu tak lama kemudian mendarat dan melintasi tengah malam lagi **di timezone tujuan** (setelah arrival), dua `SectionHeader` berurutan bisa menampilkan teks jam yang identik persis, mis. sama-sama "Sun, 13 Sep 00:00" — padahal dua instant absolut itu beda beberapa jam. Ini BUKAN bug: masing-masing `DaySection` memang benar-benar diformat memakai `boundary.timeZone` yang berbeda (satu di timezone asal, satu di timezone tujuan) — datanya benar, cuma teksnya kebetulan sama-sama menunjukkan "00:00" sehingga membingungkan saat dibaca berurutan tanpa konteks timezone.

**Kenapa ditulis "resolved as expected behavior", bukan "bug fixed":** tidak ada logika yang salah untuk diperbaiki di `computeBoundaries`/`buildSections` — root cause-nya murni UX/tampilan (section header tidak pernah menyebutkan timezone rujukannya), bukan kesalahan perhitungan boundary/split dari task-task sebelumnya.

### Files Changed
- `Services/ScheduleTimelineBuilder.swift` — hapus semua debug print (`debugUTCFormatter`, `debugUTC`, dan pemanggilannya) dari sesi investigasi sebelumnya. Tambah field `timeZoneLabel: String` ke `DaySection`, dan helper `shortTimeZoneLabel(for timeZone:) -> String` (ambil komponen terakhir dari IANA identifier, mis. "Asia/Jakarta" → "Jakarta").
- `Views/Schedule/ScheduleView.swift` — `SectionHeader` sekarang menampilkan `"\(section.localTimeLabel) · \(section.timeZoneLabel)"` (mis. "00:00 · Jakarta") alih-alih cuma jam tanpa konteks timezone. Ini berlaku untuk SEMUA section header, bukan cuma yang punya `TimezoneDividerView` (yang tetap khusus untuk kasus arrival-timezone-baru).
- `06_CURRENT_STATE.md` — catat temuan ini dengan label "resolved as expected behavior, disambiguation ditambahkan", terpisah dari entry bug-fix lain, supaya riwayat akurat (tidak ada bug hitungan yang diperbaiki di sini).

### Behavior Changed
- Section header (bukan cuma divider arrival) sekarang selalu menyebutkan timezone rujukan singkat di sebelah jam. Tidak ada perubahan pada logika `computeBoundaries`/`buildSections`/split sama sekali — murni penambahan field display.

### Verification
- Build: NOT VERIFIED (tidak ada toolchain Xcode/Swift di environment ini).
- Tests: `ScheduleTimelineBuilderTests.swift` tidak perlu diubah — assertion yang ada tidak menyentuh `timeZoneLabel`, tapi kalau mau nambah assertion baru untuk field ini, bisa cek `sections[i].timeZoneLabel == "Jakarta"` dkk pada skenario yang sudah ada.
- Static/manual checks: dicek tidak ada tempat lain yang construct `DaySection(...)` secara langsung selain di `buildSections`, jadi penambahan field baru tidak memecah call-site manapun.

### Known Limitations
- `shortTimeZoneLabel` naif (ambil komponen terakhir path IANA identifier) — untuk identifier tanpa "/" (mis. "UTC") hasilnya "UTC" apa adanya, cukup wajar. Untuk kasus jarang seperti offset-style identifier ("Etc/GMT+7") hasilnya kurang enak dibaca ("GMT+7") — belum jadi masalah nyata karena app pakai IANA city-based identifier dari data airport, bukan offset-style.
- Belum divalidasi visual di simulator — cek spacing "·" dan potensi text-truncation kalau nama kota panjang (mis. "Indiana/Indianapolis" → "Indianapolis").

### Next Recommended Step
Build & lihat langsung di simulator untuk trip yang tadinya membingungkan (dua midnight berdekatan), pastikan sekarang jelas bedanya. Lanjut ke task `CircadianEngine.generateBlocks` (`completedShiftDays` tidak progresif) yang masih tercatat sebagai next priority dari entry sebelumnya.

---

## 2026-09-12 — Fix: Hour-Grid Label Salah + Konsolidasi Section Header/Divider

### Task
Dua fix terpisah di area yang sama:
1. `TimelineGrid.hourTicks` menampilkan label jam salah untuk section yang mulai di jam non-bulat.
2. Konsolidasi `SectionHeader` + `TimezoneDividerView` jadi satu bar (belum kejadian dari task konsolidasi sebelumnya).

### Bug 1 — Root Cause
`section.startHour`/`endHour` dan `PositionedBlock.startHour` adalah **jam relatif** terhadap `segmentStart` (hasil `pieceStart.timeIntervalSince(segmentStart)/3600`), BUKAN jam-dalam-sehari. Tapi `TimelineGrid` memformat angka relatif itu langsung: `String(format: "%02d:00", hour % 24)` — seolah `hour` adalah jam asli. Untuk section yang mulai persis di jam bulat (mis. midnight), kebetulan `hour=0` cocok dengan tick pertama yang juga jam 00:00 asli, jadi bug ini nggak kelihatan. Tapi untuk section yang dibuka oleh flight arrival di jam non-bulat (mis. 03:01), tick pertama (`hour=0`, relatif) tetap diformat jadi "00:00" — padahal jam aslinya sekitar 03:00.

### Fix 1
- `Services/ScheduleTimelineBuilder.swift` — `DaySection` dapat 2 field baru: `segmentStartDate: Date` (instant asli segmen dimulai — sudah dihitung sebagai `segmentStart`/`boundary.instant`, tinggal disimpan) dan `timeZone: TimeZone` (= `boundary.timeZone`, sudah ada juga).
- `Views/Schedule/ScheduleView.swift` — `TimelineGrid.hourLabels` (baru): untuk tiap hour tick, hitung `actualDate = segmentStartDate + (hourRelative - startHour) jam`, lalu format `actualDate` itu (bukan `hour` mentah) pakai `DateFormatter` dengan `timeZone` segmen. Posisi visual (`offset`, grid lines) TIDAK diubah — itu memang benar sebagai aritmatika relatif, cuma teks label yang salah.

### Bug 2 — Konsolidasi Header (Fix Tertunda)
Task sebelumnya (2026-09-11, timezone divider awal) sudah minta ini tapi belum kejadian: untuk section dengan `divider != nil`, `ScheduleView.body` merender `TimezoneDividerView` (bar sendiri: tanggal + badge kota + jam) LANGSUNG DIIKUTI `SectionHeader` (bar sendiri lagi: tanggal + jam) — dua bar bertumpuk yang isinya tumpang tindih (tanggal & jam muncul 2x).

### Fix 2
- `Views/Schedule/ScheduleView.swift` — `TimezoneDividerView` dihapus. `SectionHeader` sekarang satu-satunya bar, baca `section.divider` langsung: badge kota (`{cityName} Time` + ikon jam) cuma muncul kalau `divider?.cityName != nil`; border bawah cuma muncul kalau `divider != nil` (baik midnight maupun arrival — bukan section pertama trip, karena `dividerInfo(for:)` sudah mengembalikan `nil` untuk `.tripStart`). `ScheduleView.body` disederhanakan: tidak ada lagi render kondisional 2-view, cukup `ForEach(sections) { SectionView(section:) }`.

### Files Changed
- `Services/ScheduleTimelineBuilder.swift` — tambah `segmentStartDate`/`timeZone` ke `DaySection`.
- `Views/Schedule/ScheduleView.swift` — `TimelineGrid.hourLabels`, hapus `TimezoneDividerView`, konsolidasi `SectionHeader`, sederhanakan `ScheduleView.body`.
- `06_CURRENT_STATE.md` — catat kedua fix + 1 item belum-terverifikasi (lihat Verification).

### Verification
- Build: NOT VERIFIED (tidak ada toolchain Xcode/Swift di environment ini).
- **Screenshot simulator trip Jakarta-Doha: TIDAK DILAKUKAN.** Task ini secara eksplisit minta verifikasi visual via simulator sebelum lapor selesai — environment sesi ini (Linux sandbox, tanpa Xcode/macOS/simulator) tidak bisa menjalankan itu sama sekali, konsisten dengan keterbatasan yang sudah dicatat di beberapa entry sebelumnya soal `xcodebuild`. **Ini bukan "sudah diverifikasi lalu lupa lampirkan" — verifikasi visualnya memang belum terjadi sama sekali.** Ditandai eksplisit `[ ]` (belum selesai) di `06_CURRENT_STATE.md`, bukan `[x]`.
- Static/manual checks: source review — semua call-site `DaySection(...)` (cuma 1, di `buildSections`), `TimezoneDividerView` (dihapus, tidak ada sisa referensi), dan `ForEach` di `ScheduleView.body` sudah dicek konsisten. `ScheduleTimelineBuilderTests.swift` tidak perlu diubah (tidak construct `DaySection` langsung, cuma panggil `buildSections()`).

### Known Limitations
- Belum divalidasi visual — WAJIB dicek manual di simulator sebelum item ini dianggap benar-benar selesai: (a) hour-grid label sekarang menunjukkan jam yang benar untuk section yang mulai di jam non-bulat, (b) section dengan divider cuma render 1 bar (bukan 2 bertumpuk), spacing badge & alignment wajar.

### Next Recommended Step
Build di Xcode, jalankan di simulator, buka trip Jakarta-Doha (atau trip apapun yang punya flight arrival di jam non-bulat), screenshot, dan konfirmasi 2 hal di atas. Kalau ada yang masih salah secara visual, laporkan balik dengan screenshot supaya bisa ditelusuri titik pastinya.

---

## 2026-09-13 — Bagian 1: Tutup Investigasi Seek Light (Dokumentasi Saja)

### Task
Konfirmasi terhadap `04_ALGORITHM.md` Section 3.B/3.C (sudah direvisi): apakah wajar Seek Light ter-subtract seluruhnya oleh Sleep untuk arah westward, karena CBTmin masih di tengah window tidur. Instruksi eksplisit: JANGAN ubah kode `CircadianEngine.swift`/`enforcingSleepExclusivity`.

### Temuan
**Investigated, confirmed correct behavior per spec — no code change.** Section 3.C poin 1 (`04_ALGORITHM.md`) eksplisit: "Sleep eksklusif mutlak... TIDAK ADA block lain (tipe apapun) yang boleh render bersamaan pada rentang waktu itu". Poin 2: kalau Avoid Light beririsan dengan Sleep, "Sleep yang menang dan Avoid Light dipotong/disesuaikan". Kalau hasil kalkulasi CBTmin (`Wake Time - 2.5 jam`) menaruh window Seek Light/Avoid Light SELURUHNYA di dalam window Sleep, hasil "block itu hilang total dari render" adalah konsekuensi langsung dan disengaja dari aturan overlap ini — bukan efek samping algoritma yang keliru.

**Penting — ini TIDAK menutup bug freeze `completedShiftDays` yang dicatat 2026-09-11.** Itu bug terpisah yang masih terbuka: karena shift beku (tidak progresif per `adaptationRate`), kondisi "CBTmin jatuh di tengah Sleep" ini jadi terjadi BERULANG identik setiap hari recovery — harusnya cuma sesekali terjadi tergantung progres shift harian yang sebenarnya. Investigasi ini cuma menjawab pertanyaan sempit "apakah mekanisme subtraction-nya sendiri benar", bukan "apakah kondisi yang memicu subtraction ini terjadi dengan frekuensi yang benar".

### Files Changed
- `06_CURRENT_STATE.md` — tambah entry "investigated, confirmed correct behavior per spec — no code change", dengan catatan eksplisit bedanya dari bug freeze yang masih terbuka.
- **Tidak ada perubahan kode** — sesuai instruksi task ini murni dokumentasi.

### Verification
- N/A (dokumentasi, tidak ada kode yang berubah untuk diverifikasi).

---

## 2026-09-13 — Bagian 2: Fitur Trim Timeline ke "Sekarang"

### Task
Section hari ini: jangan render jam yang sudah lewat, mulai dari jam sekarang (dibulatkan ke jam sebelumnya) bukan dari 00:00. Section yang sudah lewat seluruhnya (kemarin dst): skip total, jangan ditampilkan. Section masa depan: render penuh seperti biasa.

### Implementation
- `Services/ScheduleTimelineBuilder.swift` — `DaySection` dapat field baru `segmentEndDate: Date` (instant boundary berikutnya, atau `tripEnd` untuk segmen terakhir — datanya sudah ada di `buildSections` sebagai `segmentEnd`, tinggal disimpan). Dibutuhkan supaya trim logic tahu persis kapan sebuah segmen benar-benar berakhir, tanpa perlu menebak dari `endHour` (yang cuma perkiraan dari isi block, bisa meleset dari boundary asli).
- `Views/Schedule/ScheduleView.swift`:
  - `visibleSections` (baru): filter `sections` yang `segmentEndDate > Date()` — segmen yang seluruh rentangnya sudah lewat di-drop total dari array, bukan cuma disembunyikan sebagian.
  - `displayStartHour(for:)` (baru): untuk SATU segmen yang mengandung `Date()` saat ini, hitung jam sekarang dibulatkan ke bawah ke jam bulat (`Calendar` dengan `timeZone` segmen itu sendiri, BUKAN device) lalu konversi ke koordinat jam-relatif yang sama dengan `section.startHour`. Segmen lain (semua di masa depan) tetap pakai `section.startHour` asli, tidak berubah.
  - `TimelineGrid` — origin koordinat visual (`hourTicks`, `totalHeight`, semua `offset`) diganti dari `section.startHour` ke `displayStartHour` yang diteruskan dari parent. `hourLabels` (real-date formatting) TETAP dijangkarkan ke `section.startHour` — trimming cuma mengubah RENTANG jam yang ditampilkan, bukan pemetaan jam-ke-tanggal-asli.
  - `TimelineGrid.visibleBlocks` (baru): block yang sudah selesai penuh sebelum `displayStartHour` di-drop; block yang sedang berjalan (mulai sebelum, masih berlangsung) di-clip supaya mulai render tepat di `displayStartHour` — supaya tidak ada konten yang nongol di atas batas atas grid yang sudah di-trim.
  - `SectionHeader` TIDAK ikut ter-trim — tetap menampilkan identitas asli section (tanggal/jam sebenarnya), cuma area grid di bawahnya yang mulai dari "sekarang".

### Files Changed
- `Services/ScheduleTimelineBuilder.swift` — tambah `segmentEndDate`.
- `Views/Schedule/ScheduleView.swift` — `visibleSections`, `displayStartHour(for:)`, `TimelineGrid` rewrite (koordinat origin + `visibleBlocks`), `SectionView` meneruskan `displayStartHour`.
- `06_CURRENT_STATE.md` — catat fitur baru + item belum-terverifikasi.

### Behavior Changed
- Section yang 100% sudah lewat tidak lagi muncul di scroll view sama sekali.
- Section "hari ini" (yang sedang berjalan) grid-nya mulai dari jam sekarang dibulatkan ke bawah, bukan dari awal window section aslinya.
- Section masa depan tidak terpengaruh sama sekali (`displayStartHour == section.startHour`).
- Fitur ini murni display/UX — TIDAK ada di `04_ALGORITHM.md` sebagai requirement algoritma, tidak menyentuh `CircadianEngine.swift`, `trip.blocks`, atau data model manapun. Sepenuhnya computed di layer View dari `Date()` saat render.

### Verification
- Build: NOT VERIFIED (tidak ada toolchain Xcode/Swift di environment ini).
- **Screenshot/simulator: TIDAK DILAKUKAN** — sama seperti keterbatasan yang sudah dicatat di entry sebelumnya, environment sesi ini tidak punya Xcode/macOS/simulator.
- Static/manual checks: source review — fixture `#Preview("Jakarta → Paris")` di file yang sama ternyata sudah dibuat relatif terhadap `Date()` (bukan tanggal fiktif statis), jadi trim ini otomatis "teraktivasi" secara natural di preview Xcode — day -1 (kemarin) diperkirakan akan hilang dari tampilan tergantung jam preview di-render. Ini BUKAN regresi, ini fitur yang bekerja sesuai desain — dicatat di sini supaya nggak dikira preview-nya rusak kalau keliatan lebih pendek dari sebelumnya.
- Dicek tidak ada tempat lain yang construct `SectionView`/`TimelineGrid` langsung selain di `ScheduleView.body`/`SectionView.body` yang sudah diupdate; semua `#Preview` lewat `ScheduleView(trip:)` jadi tidak kena breaking change signature.

### Known Limitations
- Belum divalidasi visual — terutama: (a) block yang sedang "in progress" pas trim, harus kepotong rapi bukan nongol sebagian di luar batas atas; (b) tidak ada timer/auto-refresh — begitu waktu berjalan lewat boundary berikutnya (mis. lewat tengah malam), tampilan tidak otomatis re-render sampai View di-recompute (reopen screen, reschedule, dsb.) — ini pattern SwiftUI yang wajar untuk v1 (tidak ada requirement live-ticking di manapun di `04_ALGORITHM.md`), tapi dicatat sebagai batasan yang disengaja, bukan terlewat.
- Trip yang 100% sudah lewat (semua section ter-filter) akan jatuh ke `emptyState` yang teksnya "Your adaptation plan will appear here once generated" — copy itu sebenarnya untuk trip yang BELUM digenerate, bukan trip yang SUDAH selesai. Tidak dibuat state baru "trip completed" di task ini karena di luar scope yang diminta — dicatat sebagai gap kecil untuk task terpisah kalau diperlukan.

### Next Recommended Step
Build & jalankan di simulator dengan device time diset ke tengah-tengah sebuah trip aktif (mis. jam 14:00 di hari kedua), verifikasi: section kemarin hilang, section hari ini mulai dari jam 14:00 bukan 00:00, section besok render penuh dari 00:00.

---

# Entry Template

Copy template ini untuk patch berikutnya:

```md
## YYYY-MM-DD — <Short Task Name>

### Task
<apa yang diminta>

### Root Cause
<penyebab masalah>

### Files Changed
- `path/file.swift` — <alasan>

### Behavior Changed
- <perubahan behavior>

### Verification
- Build: PASS / FAIL / NOT VERIFIED
- Tests: <hasil>
- Static checks/manual checks: <hasil>

### Known Limitations
- <jika ada>

### Next Recommended Step
<langkah kecil berikutnya>
```
'
