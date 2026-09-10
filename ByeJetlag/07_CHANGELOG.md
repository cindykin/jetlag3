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
