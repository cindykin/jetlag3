# 04_ALGORITHM.md — ByeJetlag

> **Status:** Source of truth. Isi requirement utama berasal dari knowledge base yang sudah ada di archive project yang diaudit. Jangan mengubah kontrak di file ini sebagai efek samping task coding biasa.

> Baca `01_PRODUCT.md` dulu untuk konteks produk sebelum baca ini.
> File ini SATU-SATUNYA sumber kebenaran rumus. Jangan implementasi dari ingatan/training data umum soal jet lag.

## Batasan Scope (tegas, jangan diimplementasi)
- Apple Watch / HealthKit / WatchOS apapun.
- Gentle Mode, Insomnia handling, Health Screening.
- Tombol "Saya terlalu lelah".
- Konsekuensi: hanya ada 1 jalur parameter (normal), tidak ada percabangan gentle/insomnia di mana pun dalam kode.

---

## 1. Baseline & Core Definitions

### A0. Standar Waktu Global (UTC)
- Semua perhitungan mesin dalam basis UTC.
- Simpan timezone sebagai IANA identifier (`Asia/Jakarta`), bukan label GMT manual.
- Untuk rumus adaptasi lintas zona, gunakan selisih UTC Offset sebagai sumber kebenaran.
- **Aturan timezone display:** sebelum arrival, tampilkan & hitung berdasarkan origin timezone. Setelah arrival, switch ke destination timezone. Transisi ini harus presisi di titik `arrivalLocalTime` — tidak boleh drift/mismatch saat lintas zona.

### A. Sumber Data Pola Tidur (TIDAK ADA Check-in Harian)
**Tidak ada pertanyaan/prompt harian ke user soal jam tidur/bangun.** Sumber data pola tidur cuma 2:

1. **Seed dari profil** — hasil onboarding "Personalize Profile" (Average Sleep Pattern / jam biasa bangun & tidur). Ini dipakai untuk generate jadwal pertama kali saat Trip dibuat.
2. **Update via Reschedule manual (opsional, maksimal 1x per Trip)** — kalau user merasa jadwalnya meleset, dia buka detail block → tekan tombol "Reschedule" → modal **"Input your time of sleep"** muncul, minta `Sleep start time` & `Sleep stop time` **aktual**. Nilai ini dipakai untuk hitung ulang CBTmin & regenerate sisa jadwal Trip itu (lihat Section 6.1).

Di luar 2 momen ini (generate awal & reschedule), data tidak pernah diminta ulang ke user selama Trip berjalan.

### B. Perhitungan CBTmin
```
CBTmin = Wake Time - 2.5 Jam
```
- `Wake Time` = dari profil (saat generate awal), ATAU dari input reschedule (kalau user sudah pernah reschedule).
- CBTmin dihitung **maksimal 2 kali per Trip**: sekali saat generate awal, sekali lagi kalau user reschedule. Bukan nilai yang di-update otomatis setiap hari.

---

## 2. Trip Model

**HANYA ADA 1 TIPE TRIP.** Tidak ada `TripType` (oneWay/roundTrip) — ini sengaja dihapus.

```swift
struct Trip {
    let id: UUID
    let flights: [FlightLog]     // 1 flight, atau beberapa kalau ada transit/connecting
    let createdAt: Date
}

struct FlightLog {
    let id: UUID
    let originTimeZone: TimeZone
    let destinationTimeZone: TimeZone
    let departureTime: Date
    let arrivalLocalTime: Date
    let direction: Direction    // .eastward / .westward, dihitung dari offset gap
}
```

- **Trip disimpan sebagai list/array** (`[Trip]`), bukan singleton — arsitektur data harus siap menampung banyak trip tanpa refactor.
- **Kalau user mau "pulang pergi" (round-trip secara konsep):** dia bikin 2 Trip terpisah (Trip A: pergi, Trip B: pulang) lewat flow "Add Flight" 2 kali. **Tidak digrouping** jadi satu entitas — masing-masing Trip berdiri sendiri dengan CBTmin, gap, direction, dan jadwalnya masing-masing.
- **Non-conflict requirement:** kalau ada 2+ Trip aktif bersamaan, jadwal notifikasi antar Trip tidak boleh saling override — setiap Trip punya scheduling identifier sendiri.
- `flights: [FlightLog]` tetap array untuk mendukung connecting/transit flight dalam 1 perjalanan (beda konsep dari "flight pulang").

---

## 3. Block Type & Generation Rules

### A. 8 Tipe Block
```swift
enum BlockType {
    case seekLight
    case avoidLight
    case sleep
    case nap
    case caffeine
    case noCaffeine
    case melatonin  
    case flight
}
```

### B. Definisi & Aturan per Tipe
- **Sleep** = core sleep, blok tidur panjang. Sleep **TIDAK selalu terjadi malam** — posisinya mengikuti hasil kalkulasi CBTmin/shift, bisa siang kalau memang itu hasil algoritmanya.
- **Nap** = tidur pendek, **durasi ≤ 90 menit**. Beda entitas dari Sleep, jangan disatukan jadi satu tipe dengan durasi berbeda.
- **Caffeine** & **Melatonin** = **conditional block** — HANYA muncul di jadwal kalau user meng-aktifkan toggle-nya di profil (`useCaffeine`, `useMelatonin`). Kalau toggle off, sistem tidak generate block ini sama sekali (bukan digenerate lalu disembunyikan).
- **Melatonin** — TIDAK BOLEH digenerate kalau tidak ada window Sleep terkait di hari itu. Melatonin selalu terikat ke satu Sleep window tertentu (ditempatkan sebelum window itu).
- **Seek Light** — muncul setelah waktu bangun (`after wake`), sesuai window CBTmin di Section 6.
- **Avoid Light** — muncul sebelum waktu tidur (`before sleep`), sesuai window CBTmin di Section 6.
- **No Caffeine** — instruksi berlaku sebelum window Sleep (lihat Section 7, Caffeine Cut-off).
- **Flight** — merepresentasikan durasi penerbangan itu sendiri, dari `departureTime` sampai `arrivalLocalTime` (dalam timezone yang sesuai, lihat Section 1.A0).

### C. Aturan Overlap (WAJIB, urutan prioritas)
1. **Sleep eksklusif mutlak.** Selama window Sleep aktif, TIDAK ADA block lain (tipe apapun) yang boleh render bersamaan pada rentang waktu itu — Sleep berdiri sendiri, ambil lebar penuh timeline pada rentang waktunya.
2. **Avoid Light tidak boleh overlap dengan Sleep.** Kalau hasil kalkulasi CBTmin bikin window Avoid Light beririsan dengan window Sleep, Sleep yang menang dan Avoid Light dipotong/disesuaikan supaya tidak tumpang tindih dengan Sleep.
3. **Selain Sleep, SEMUA block type BOLEH overlap satu sama lain di waktu yang sama.** Ini bukan kondisi yang harus dihindari — ini behavior yang diharapkan. Contoh valid: Flight + Caffeine bersamaan, Caffeine + Avoid Light bersamaan, Avoid Caffeine + Seek Light bersamaan.
4. Block yang overlap (poin 3) dirender sebagai **lane/kolom terpisah berdampingan** di timeline, bukan ditumpuk penuh atau dipaksa berurutan. Lihat `05_DESIGN_SYSTEM.md` Section 4 untuk spesifikasi layout-nya.

### D. Generasi Berdasarkan Pola & Shift
- Sleep block digenerate dari **pola tidur user** (seed dari profil, atau dari reschedule kalau sudah pernah — lihat Section 1) **+ pergeseran gradual** (`Shift_daily` — lihat Section 4.B). Bukan jam tetap hardcode. Seluruh jadwal Trip digenerate **sekaligus di muka** (bukan bertahap harian), karena tidak ada data check-in baru yang masuk setiap hari.

---

## 4. Fase Loading (Sebelum Terbang)

### A0. Anchor Time Zone
- Anchor utama: `TZ_origin_home` + `UTC_offset_origin_home` (lokasi aktual user).
- Override dinamis: IF user berpindah zona waktu sebelum berangkat → update ke `TZ_origin_current`.

### A. Batas Aman
- **Maksimum Shift:** 1 jam (60 menit) per hari. Hanya 1 nilai — tidak ada percabangan lain.

### B. Rumus Target Geser Harian
```
Shift_daily = min(Gap_total / N_days, 1.0)
```
- `Gap Total = CBTmin (dari profil/reschedule, Section 1.B) - CBTmin Target Lokal (tujuan)`.
- `N_days` = hari persiapan tersisa dari tanggal generate sampai tanggal flight, maksimal 3 hari.
- `Total Loading Shift = Shift_daily * N_days`.
- Karena tidak ada check-in harian, seluruh rencana geser harian ini **dihitung sekali di muka** untuk seluruh durasi loading phase, bukan disesuaikan tiap hari berjalan.

---

## 5. Fase In-Flight

- Gunakan `Arrival Local Time` sebagai acuan instruksi tidur/bangun. Tidak ada check-in manual selama fase ini.

- **IF Arrival Time = 06:00–16:00 (Pagi/Siang):**
  - "Tidur Sekarang, Bangun 4 jam sebelum mendarat."
  - Alarm ±4 jam sebelum mendarat → "Minum Kafein & Tetap Terjaga".
- **IF Arrival Time = 18:00–05:00 (Malam):**
  - "Tetap terjaga di awal penerbangan, usahakan tidur di akhir penerbangan."

---


## 6. Fase Recovery & Status "Fully Adapted"

Seluruh jadwal recovery digenerate sekaligus di muka saat Trip dibuat (dari CBTmin di Section 1.B) — tidak ada check-in harian yang mengoreksi jadwal secara otomatis.

```
Estimasi Hari Sembuh = ceil(Remaining Gap / Adaptation Rate)
```
- **Artinya:** hitung berapa hari minimum dibutuhkan untuk menutup sisa selisih jam biologis (`Remaining Gap`), berdasarkan kecepatan adaptasi tubuh (0.95 atau 1.53 jam/hari — lihat Section 7). Dihitung sekali di muka.
- IF `Jumlah Hari di Tujuan >= Estimasi Hari Sembuh` → tampilkan UI **"Fully Adapted"**. Cara bacanya: begitu jumlah hari user sudah berada di destinasi (dihitung dari tanggal arrival) sama dengan atau lebih dari prediksi hari sembuh, sistem anggap adaptasi selesai.

`Remaining Gap` hanya berubah kalau user melakukan Reschedule manual (Section 6.1) — bukan diupdate otomatis harian.

### 6.1 Recalculation (Maksimal 1x, Manual Only)
- `hasRescheduled` (Bool, default `false`) — pakai boolean, bukan counter, karena limitnya cuma 1x.
- **Trigger (SATU-SATUNYA):** user membuka detail sebuah block, lalu menekan tombol **"Reschedule"** → modal "Input your time of sleep" muncul (Sleep start/stop time aktual). Tidak ada trigger otomatis, tidak ada check-in harian.
- **Logika:**
  - IF `hasRescheduled == false`: tombol "Reschedule" tersedia di layar detail block. Kalau ditekan dan user isi modal → hitung ulang CBTmin (Section 1.B) dari input aktual tsb, regenerate sisa blocks Trip dari `Remaining Gap` baru, set `hasRescheduled = true`.
  - IF `hasRescheduled == true`: **sembunyikan tombol Reschedule sepenuhnya** dari semua layar detail block di Trip itu. Jadwal hasil reschedule itulah yang berlaku sampai akhir Trip.
- **Reset:** `hasRescheduled` reset ke `false` untuk Trip yang baru (per-Trip, bukan global).
- **Audit Log (opsional, kalau sempat):** simpan `triggerTimestamp`, `oldBlocks`, `newBlocks` untuk kejadian reschedule.

---

## 7. Arah Penerbangan & Light Rules

- **Aturan 12 Jam:** IF `|UTC Offset Gap| > 12 jam` → `Adjusted Gap = 24 - |UTC Offset Gap|`, balik arah (eastward ↔ westward).

### A. Eastward (Phase Advance)
- Kecepatan Adaptasi: 0.95 jam/hari.
- `Estimasi Hari Sembuh = ceil(Remaining Gap / 0.95)`.
- `CBTmin` s.d. `(CBTmin + 4 jam)` → **SEEK LIGHT**
- `(CBTmin - 3 jam)` s.d. `CBTmin` → **AVOID LIGHT**

### B. Westward (Phase Delay)
- Kecepatan Adaptasi: 1.53 jam/hari.
- `Estimasi Hari Sembuh = ceil(Remaining Gap / 1.53)`.
- `(CBTmin - 4 jam)` s.d. `CBTmin` → **SEEK LIGHT**
- `CBTmin` s.d. `(CBTmin + 3 jam)` → **AVOID LIGHT**

⚠️ Window 4h/3h TIDAK simetris antar arah — jangan disederhanakan jadi sama.
⚠️ Kedua window ini tetap harus dicek ulang terhadap Aturan Non-Overlap (Section 3.C) — Avoid Light tidak boleh overlap Sleep.

---

## 8. Caffeine Cut-off
```
Caffeine Cutoff = Target Tidur Lokal - 8 Jam
```
Hanya 1 nilai. Block "No Caffeine" berlaku mulai titik ini sampai window Sleep berikutnya dimulai.

---

## 9. Timezone Divider (Timeline)

Sisipkan divider horizontal di timeline HANYA pada 2 kondisi ini:
1. **Flight arrival di timezone baru** → tampilkan badge **"{Nama Kota Tujuan} Time"** (contoh: "Doha Time", "Paris Time") + ikon jam, di samping tanggal & jam.
2. **Tengah malam (00:00) di timezone lokal yang sedang berlaku (tanpa perpindahan timezone)** → tampilkan tanggal & jam saja, **TANPA badge nama kota**.

Jangan sisipkan divider di kondisi lain manapun. Detail visual lengkap: lihat `05_DESIGN_SYSTEM.md` Section 5.

---

## 10. Notifikasi (Wajib Real Push)
- Gunakan `UNUserNotificationCenter` + local notification (bukan server push — semua data lokal).
- Setiap instruksi terjadwal (Seek Light, Avoid Light, Caffeine Cutoff, Sleep Anchor, Wake alarm in-flight) → dijadwalkan sebagai local notification pada waktu yang dihitung.
- **Timing notifikasi harus presisi (real-time), match exact dengan waktu event** — bukan perkiraan atau dibulatkan.
- Notifikasi per leg/trip harus punya identifier unik agar tidak saling override saat ada lebih dari 1 leg/trip aktif.
