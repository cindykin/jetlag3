# 08_ONBOARDING_AND_FLOWS.md — ByeJetlag

> **Status:** Source of truth untuk flow onboarding & itinerary. Baca `00_AI_RULES.md`, `01_PRODUCT.md`, `05_DESIGN_SYSTEM.md` dulu.
> File ini melengkapi (bukan menggantikan) `01_PRODUCT.md` — kalau ada konflik soal scope/data, `01_PRODUCT.md` menang; file ini soal urutan layar & trigger-nya.

---

## 1. DUA JENIS ONBOARDING — JANGAN DICAMPUR

Project ini punya 2 flow yang sekilas mirip tapi tujuannya beda total. AI **wajib** membedakan keduanya secara eksplisit di kode (nama View, nama flag, nama function — jangan reuse satu flag untuk dua konsep ini).

### A. Onboarding "Help/Guide" — Informational Only
- **Tujuan:** kasih tau konsep app (seek light, avoid light, sleep, nap, caffeine, melatonin) ke user baru. **Tidak ada input data apapun.**
- **Trigger tampil:**
  - Otomatis sekali di first launch (sebelum ada trip/profile apapun).
  - Bisa dibuka ULANG kapan saja secara manual oleh user lewat tombol Guide di Home (`i` icon di navbar Travel Plans) — ini BUKAN reset onboarding state, cuma nampilin ulang info yang sama sebagai referensi.
- **Efek selesai:** set flag "sudah pernah lihat help" jadi `true` (first-run), TAPI membuka ulang dari tombol Guide **tidak boleh mengubah/reset flag apapun** dan **harus bisa di-dismiss dengan benar** (ini bug yang sudah dicatat di `06_CURRENT_STATE.md` Section 6 — "Guide dismissal behavior").
- **Tidak ada logic kondisional** — semua user baru selalu lihat ini sekali, titik.

### B. Onboarding "Personalize Profile" — Data Collection
- **Tujuan:** mengisi data profil sirkadian user (5 pertanyaan screening) yang dipakai algoritma.
- **5 Pertanyaan (urutan sesuai desain):**
  1. Would you like to use melatonin to timeshift faster and sleep better? *(→ set `useMelatonin` toggle)*
  2. When do you normally fall asleep? *(time picker, dibatasi range before 9pm – after 2am maksimal)*
  3. What's your sex? *(female/male/other)*
  4. When do you normally wake up? *(time picker, dibatasi range before 7am – after 9pm)*
  5. Get advice delivered as notifications? *(yes/no → set notification permission/preference)*
- **Trigger tampil — KONDISIONAL, ini bagian paling penting:**
  - **TIDAK tampil** kalau user sudah mengisi profil ini secara mandiri lebih dulu (misal lewat Edit Profile) SEBELUM bikin trip pertama.
  - **Tampil** kalau user belum isi profil sama sekali, dipicu di titik pembuatan trip pertama (bagian akhir alur Add Flight — sinkron dengan keputusan di `01_PRODUCT.md`: "kalau skip onboarding, ditanya lagi di akhir alur create trip pertama").
  - Setelah terisi (dari jalur manapun — Edit Profile ATAU screening ini), **tidak tampil lagi selamanya**, kecuali user edit manual lewat Edit Profile.
- **Constraint UI terkait (dari `06_CURRENT_STATE.md`):** 4 field ini (Gender, Use caffeine, Use melatonin, Average Sleep Pattern) di Edit Profile **terkunci/read-only kalau ada trip aktif** — supaya baseline sirkadian tidak berubah di tengah trip yang sedang berjalan.

---

## 2. Flow Add Flight → Itinerary → Generate Plan

1. **Fill your flight detail:** pilih airport departure & arrival (search), lalu Schedule (Departure & Arrival date/time — **local time di airport masing-masing**, lihat `02_ARCHITECTURE.md` soal timezone-aware DatePicker).
2. **Itinerary List:** menampilkan leg yang sudah diisi (`Jakarta → Doha`). Ada tombol **"+ Add other flight"** untuk menambah leg lain (transit/connecting, ATAU flight balik — UI-nya sama, tapi maknanya beda tergantung konteks user).
3. **Konfirmasi:** "Are you entering all flight correctly? Including all stopover, transit, and your return flights?" → **Yes, create plan** / **No, let me complete**.
4. **PENTING — konsekuensi "Add other flight":** kalau leg yang ditambahkan itu sebenarnya flight PULANG (bukan transit), hasil generate-nya tetap **jadi 2 section jadwal terpisah** (2 Trip independen secara kalkulasi), **BUKAN digabung jadi satu rencana perjalanan**. Ini konsisten dengan keputusan "tidak ada round-trip grouping" di `01_PRODUCT.md`.
5. Setelah confirm → **Personalize Profile screening** muncul HANYA jika profil belum terisi (lihat Section 1.B) → loading screen "Creating perfect plan for you" → jadwal jadi.

---

## 3. Reschedule Flow (Runtime, Manual Only — BUKAN Check-in Harian)

**Tidak ada prompt harian ke user.** User tidak pernah ditanya jam tidur/bangun setiap pagi. Mekanisme yang ada hanya ini:

- Trigger: user buka detail sebuah block (tap block di Schedule) → kalau `hasRescheduled == false`, ada tombol **"Reschedule"**.
- Tekan Reschedule → modal **"Input your time of sleep"** muncul: minta `Sleep start time` & `Sleep stop time` aktual.
- Tombol di modal: **Cancel** / **Reschedule**.
- Ini SAMA PERSIS dengan jatah reschedule manual 1x di `04_ALGORITHM.md` Section 6.1 — bukan mekanisme terpisah. Setelah dipakai 1x, tombol Reschedule hilang dari semua layar detail block di Trip itu.

---

## 4. Resolusi Konflik (sudah final)
1. **Reschedule maksimal 1x** — copy text "2 times" di desain adalah kesalahan/belum ter-update, bukan keputusan baru. `04_ALGORITHM.md` Section 6.1 (`hasRescheduled: Bool`) tetap berlaku. Copy text di UI perlu diperbaiki jadi konsisten dengan 1x.
2. **Reschedule HANYA bisa dipicu dari layar detail block** (tap block → sheet detail → tombol "Reschedule" muncul di sini, kalau `hasRescheduled == false`). Tidak ada tombol reschedule terpisah di Dashboard/Home, dan **tidak ada check-in harian otomatis** — lihat Section 3 di atas (sudah direvisi).
