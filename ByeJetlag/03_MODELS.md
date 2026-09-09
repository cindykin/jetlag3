# 03_MODELS.md — ByeJetlag Data Contract

> Tujuan file ini: mencegah AI membuat duplicate model atau menebak bentuk data. Bedakan **CURRENT** dan **TARGET**. `04_ALGORITHM.md` tetap menjadi sumber kebenaran formula.

## 1. Model Ownership

Domain model ByeJetlag harus berada di layer Models, bukan didefinisikan ulang di View.

Single source of truth untuk schedule:

```text
BlockType
TimelineBlock
```

Model berikut di `ScheduleView.swift` adalah **CURRENT duplicate yang harus dihapus saat refactor schedule**:

```text
ActivityType
ActivityItem
TimelineSection
MockSchedule
```

Jangan membuat model schedule ketiga.

---

## 2. CURRENT Models — Berdasarkan Codebase yang Di-upload

### `BlockType`

CURRENT sudah memiliki 8 case:

```swift
seekLight
avoidLight
sleep
nap
caffeine
noCaffeine
melatonin
flight
```

CURRENT juga menyimpan presentation/detail behavior seperti icon, color, `whatToDo`, `alternatives`, dan `whyItMatters`.

**TARGET:** tetap menjadi enum domain schedule tunggal. Visual token akhirnya mengikuti `05_DESIGN_SYSTEM.md` / `AppTheme`, bukan warna ad-hoc yang tersebar.

---

### `TimelineBlock`

CURRENT:

```swift
struct TimelineBlock: Identifiable, Codable {
    var id: UUID
    var type: BlockType
    var startTime: Date
    var endTime: Date
    var title: String
}
```

Ada computed `durationLabel`.

**Invariants:**
- `endTime >= startTime`.
- Sleep/non-overlap rule mengikuti `04_ALGORITHM.md`.
- UI harus merender model ini langsung setelah schedule refactor.
- Jangan membuat `ActivityItem` baru sebagai adapter permanen hanya untuk UI.

---

### `FlightLeg`

CURRENT:

```swift
struct FlightLeg: Identifiable, Codable {
    var id: UUID
    var origin: String
    var destination: String
    var departure: Date
    var arrival: Date
}
```

CURRENT belum menyimpan timezone eksplisit.

**TARGET requirement:** flight leg harus membawa informasi timezone origin dan destination secara eksplisit sehingga:
- waktu input airport dipahami sebagai local time airport,
- absolute instant dapat dihitung dengan benar,
- direction/UTC offset gap dihitung untuk tanggal flight,
- display berpindah timezone tepat pada arrival.

Semantik target dari `04_ALGORITHM.md`:

```swift
originTimeZone
destinationTimeZone
departureTime
arrivalLocalTime
direction
```

> Implementasi storage boleh memakai IANA identifier string sebagai bentuk persisted representation bila diperlukan, tetapi jangan menyimpan label GMT manual sebagai sumber kebenaran. Jangan mengandalkan timezone device.

---

### `UserProfile`

CURRENT fields:

```text
useMelatonin
useCaffeine
receiveNotifications
sleepTime
wakeTime
sex
name
totalSleep
sleepPattern
```

Known issue:
- `totalSleep` dan `sleepPattern` CURRENT masih string statis dan bisa tidak sinkron dengan `sleepTime`/`wakeTime`.

**TARGET:** derive display value dari data sleep/wake aktual bila memungkinkan; hindari dua sumber kebenaran untuk data yang sama.

---

### `Trip`

CURRENT fields:

```text
id
flights: [FlightLeg]
blocks: [TimelineBlock]
createdAt
originCity
destinationCity
```

CURRENT computed fields antara lain origin/destination code, departure date, dan active state.

**Product invariant:**
- Trip collection = `[Trip]`.
- Satu Trip dapat memiliki beberapa `FlightLeg` untuk transit/connecting.
- Flight pulang = Trip baru, bukan round-trip child/grouping.

**TARGET required state from algorithm:**
- reschedule state harus per Trip (`hasRescheduled`, default false) saat fitur tersebut diimplementasikan.

---

### `AppState`

CURRENT berada di `Models.swift` dan menggunakan singleton:

```swift
static let shared = AppState()
```

CURRENT state:

```text
trips: [Trip]
profile: UserProfile
hasCompletedProfile: Bool
```

CURRENT `generateBlocks(for:)` adalah hardcoded template dan **bukan** algorithm engine yang valid.

**TARGET:**
- pindah ke `Store/AppState.swift`,
- bukan singleton,
- inject dari app root melalui environment,
- hanya mengorkestrasi state/services,
- schedule computation dipindah ke `CircadianEngine`.

---

## 3. TARGET Model yang Belum Ada

### `DailyCheckIn`

Required oleh `04_ALGORITHM.md`:

```swift
struct DailyCheckIn {
    let date: Date
    let actualSleepTime: Date
    let actualWakeTime: Date
}
```

Behavior:
- onboarding/profile sleep pattern adalah seed awal,
- setelah check-in tersedia, actual check-in menjadi baseline terbaru,
- CBTmin = actual wake time - 2.5 jam,
- bila hari ini belum check-in, fallback ke check-in terakhir + reminder.

**CURRENT:** belum ditemukan pada codebase yang di-upload.

Jangan menebak ownership/storage final tanpa menyelaraskan dengan Trip lifecycle dan persistence implementation. Jika menambah field untuk ownership, lakukan sebagai perubahan arsitektur eksplisit dan update file ini.

---

### `Direction`

Required secara semantik:

```swift
enum Direction {
    case eastward
    case westward
}
```

Direction harus dihitung dari timezone/offset gap sesuai `04_ALGORITHM.md`, termasuk aturan >12 jam. Jangan meminta user memilih arah secara manual.

---

## 4. Relationship Map

```text
AppState
├── profile: UserProfile
└── trips: [Trip]
      ├── flights: [FlightLeg]
      ├── blocks: [TimelineBlock]
      ├── hasRescheduled (TARGET)
      └── check-in relationship/state (TARGET; implement explicitly)

TimelineBlock
└── type: BlockType
```

---

## 5. Data Invariants

### Trip
- Minimal satu valid flight leg sebelum schedule dihasilkan.
- `flights` disusun sesuai urutan perjalanan.
- `blocks` berasal dari engine, bukan mock.

### FlightLeg
- Origin dan destination tidak boleh sama untuk satu leg.
- Arrival absolute instant harus setelah departure absolute instant.
- Airport timezone harus dapat di-resolve dari IANA identifier/data airport.

### TimelineBlock
- Start/end harus deterministik dari algorithm input.
- Conditional block tidak dibuat bila toggle terkait off.
- Sleep exclusivity/non-overlap wajib dipatuhi.

### UserProfile
- Sleep/wake profile adalah seed, bukan nilai aktual harian selamanya.
- Derived display string tidak boleh menjadi sumber data kedua.

---

## 6. Model Change Rules untuk AI

Sebelum menambah field/model baru, AI harus menjawab:

1. Requirement mana yang membutuhkan data ini?
2. Apakah data bisa diturunkan dari model existing?
3. Siapa owner lifecycle data tersebut?
4. Apakah harus persisted?
5. Apakah field ini akan menduplikasi source of truth?
6. Apakah migration/decoding backward compatibility dibutuhkan?

Jika jawabannya tidak jelas, jangan menambah model secara diam-diam.

---

## 7. Explicitly Forbidden Models/Concepts

Jangan buat:
- `TripType`
- `RoundTrip`
- `RoundTripGroup`
- schedule model paralel (`ActivityItem`, versi baru sejenisnya)
- Watch/Health model
- backend/auth user model
- GentleMode/HealthScreening state untuk v1

---

## 8. Model Acceptance Criteria untuk Refactor Schedule

Refactor schedule dianggap benar jika:

- `ActivityType`, `ActivityItem`, `TimelineSection`, `MockSchedule` tidak lagi menjadi jalur data production.
- `ScheduleView` menerima/render `[TimelineBlock]` dari Trip.
- `BlockType` tetap satu-satunya schedule type enum.
- block hasil engine bisa ditest tanpa render SwiftUI.
- timezone context tidak berasal dari device secara implisit.
