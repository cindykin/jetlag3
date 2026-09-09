# 05_DESIGN_SYSTEM.md — ByeJetlag

> **Status:** Source of truth. Isi requirement utama berasal dari knowledge base yang sudah ada di archive project yang diaudit. Jangan mengubah kontrak di file ini sebagai efek samping task coding biasa.

> Baca `01_PRODUCT.md`, `04_ALGORITHM.md`, dan `02_ARCHITECTURE.md` dulu.
> File ini soal token visual & rendering timeline. Logic kapan sebuah block muncul/tidak overlap ada di `04_ALGORITHM.md` Section 3 — jangan duplikat logic di sini, cukup referensi.

---

## 1. Warna Primer
```
Primary: #C45500
```
Ini warna aksen utama app (tombol CTA, active state, dsb — bukan warna block).

## 2. Warna per Block Type

Tiap block punya 2 warna: warna aksen/ikon (foreground) dan warna background block-nya.

| Block Type | Foreground | Background |
|---|---|---|
| Seek Light | `#FFBE00` | `#FFF9EC` |
| Go to Sleep | `#1D57AF` | `#EDF3FC` |
| Take melantonin & Go to Sleep | `#1D57AF` | `#EDF3FC` |
| Take a nap (If can) | `#1D7DAF` | `#EEF7FC` |
| Caffeine | `#855216` | `#FCF5ED` |
| Avoid Light | `#808080` | `#F2F2F2` |
| Avoid Caffeine | `#808080` | `#F2F2F2` |
| Flight | `#111111` | `#F2F2F2` |

Jam berada di kolom kiri, sedangkan activity blocks berada di sisi kanan.
Setiap block punya warna latar lembut, garis indikator vertikal berwarna di sisi kiri, icon, judul, dan rentang waktu.



## 3. Ikon per Block Type
Semua icon menggunakan SF Symbols style fill. Jika ada 2 icon maka group mereka pake HStack
- Seek light = sun.max.fill
- sleep = bed.double.fill
- Melatonin = bed.double.fill + pill.fill
- nap = bed.double.fill + sun.max.fill
- caffeine = cup.and.saucer.fill
- avoid light = sun.max.fill + x.circle
- avoid caffeine = cup.and.saucer.fill + x.circle
- flight = airplane.up.right


 ## 4. Layout Timeline (Multi-Lane Timeline System)

Ini BUKAN timeline satu kolom biasa — ini timeline **multi-lane** mirip Gantt chart. Rendering WAJIB pakai pendekatan ini (bukan `List`/`ScrollView` dengan section biasa):

- Gunakan **`ZStack`** sebagai container utama timeline, dengan kolom jam di paling kiri (fixed).
- **Map waktu → posisi Y**: setiap block di-posisikan secara vertikal berdasarkan waktu mulainya (fungsi konversi `time → yOffset`, linear terhadap rentang jam yang ditampilkan).
- **Height block = durasi.** Block yang durasinya lebih lama (misal Sleep 8 jam) harus terlihat lebih tinggi/panjang secara visual dibanding block singkat.
- **Lane assignment (posisi X):** untuk tiap titik waktu, kumpulkan semua block yang aktif bersamaan (hasil dari `ALGORITHM_SPEC.md` Section 3.C — boleh overlap kecuali Sleep). Bagi lebar area block (di luar kolom jam) merata jadi N kolom sejajar, N = jumlah block yang overlap di rentang waktu itu.
  - Contoh nyata: Caffeine (08:00-17:00) + Avoid Light (08:00-14:00) bersamaan → keduanya dapat lebar ½ area, side-by-side.
  - Contoh lain: Flight + Caffeine bersamaan → 2 lane sejajar.
- **Sleep = pengecualian.** Kapanpun Sleep aktif, dia **mengambil lebar penuh** area block (tidak berbagi lane dengan siapapun), konsisten dengan Sleep eksklusif di `ALGORITHM_SPEC.md` Section 3.C poin 1.
- Badge waktu (`HH:mm-HH:mm`) pada card hanya muncul di kemunculan pertama block itu, tidak diulang tiap jam.

## 5. Timezone Divider (Visual)
- Divider berupa header horizontal pemisah, isinya: nama hari+tanggal (kiri), lalu jam pada titik itu (kanan).
- **Saat perpindahan ke timezone baru** (flight arrival) → tambahkan badge di tengah: ikon jam + teks **"{Nama Kota Tujuan} Time"** (contoh: "Doha Time", "Paris Time").
- **Saat tengah malam lokal TANPA perpindahan timezone** → cukup tanggal & jam saja, **tanpa badge kota**.

## 6. Tipografi
Gunakan system font (SF Pro) dengan skala bawaan iOS: `.largeTitle`, `.title`, `.headline`, `.body`, `.caption`.

## 7. Corner Radius
- Block card di timeline: **8px**.
- Trip card / flight flag card: **16px**.
