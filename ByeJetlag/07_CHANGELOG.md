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
