# Muraloka

Muraloka adalah aplikasi capstone Flutter untuk digital painting kolaboratif dengan monetisasi.  
Aplikasi ini mendukung multi-layer real-time painting, kolaborasi, dan marketplace terintegrasi menggunakan Firestore.

## Fitur Utama

- **Core Painting**: CustomPainter, brush & eraser, pan/zoom, layer management, dark mode.
- **Kolaborasi Real-time**: Sync gambar, kontrol ownership (export, jual, hapus hanya oleh owner), galeri proyek.
- **Monetisasi**: Jual karya ke marketplace, integrasi pembayaran Midtrans Snap, metrik penjualan.
- **Store/Marketplace**: Halaman store publik, aksi jual oleh owner, total sold per listing.
- **Export & Drafts**: Export PNG (owner only), galeri drafts.
- **Kontrol Ownership**: Hanya owner bisa export, jual, dan hapus project/layer.

## Teknologi

- **Frontend**: Flutter
- **Backend/DB**: Google Firestore
- **Monetisasi**: Midtrans Snap


## Instalasi & Menjalankan

1. Clone repositori:
    ```bash
    git clone https://github.com/yourusername/muraloka.git
    ```
2. Masuk ke direktori proyek:
    ```bash
    cd muraloka
    ```
3. Install dependencies:
    ```bash
    flutter pub get
    ```
4. Jalankan aplikasi:
    ```bash
    flutter run
    ```

## Skema Database Firestore

- **Drafts**: `/artifacts/{appId}/users/{userId}/projects/{projectId}` (Owner only)
- **Shared Projects**: `/artifacts/{appId}/public/data/projects_shared/{projectId}` (Owner & kolaborator)
- **Marketplace**: `/artifacts/{appId}/public/data/store_listings/{listingId}` (Publik, owner listing)
- **Reviews**: `/artifacts/{appId}/public/data/store_listings/{listingId}/reviews/{reviewId}`

## Kontribusi

Silakan kontribusi atau buka issue untuk perbaikan!

## Lisensi

Proyek ini berlisensi MIT.
