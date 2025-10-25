# QRIS Payment Integration Guide

## Overview
Implementasi pembayaran QRIS untuk marketplace Muraloka menggunakan standard EMV QRIS Indonesia dengan **Pretty QR Code** untuk tampilan yang lebih menarik dan profesional.

## Packages Yang Digunakan
- `qris: ^0.7.1` - Library untuk generate QRIS payment code
- `pretty_qr_code: ^3.5.0` - Widget untuk menampilkan QR code dengan design yang menarik

## Struktur File

### 1. QRIS Payment Service (`lib/utils/qris_payment_service.dart`)
Service untuk generate QRIS code sesuai standard EMV Indonesia.

**Key Methods:**
```dart
// Generate QRIS code umum
QRISPaymentService.generateQRIS({
  required String merchantName,
  required String merchantCity,
  required double amount,
  required String referenceId,
})

// Generate QRIS khusus untuk project marketplace
QRISPaymentService.generateProjectPaymentQRIS({
  required String projectName,
  required String projectId,
  required String sellerName,
  required double price,
  String sellerCity = 'Jakarta',
})

// Format rupiah
QRISPaymentService.formatRupiah(double amount)
```

**QRIS Format (EMV Standard):**
- Payload Format Indicator (00): "01"
- Point of Initiation (01): "12" (dynamic)
- Merchant Account (26): Berisi acquirer ID dan merchant ID
- Merchant Category Code (52): "7999" (Miscellaneous Business)
- Transaction Currency (53): "360" (Indonesian Rupiah)
- Transaction Amount (54): Harga dalam format string
- Country Code (58): "ID"
- Merchant Name (59): Nama penjual + nama project
- Merchant City (60): Kota merchant
- CRC (63): Checksum CRC-16/CCITT-FALSE

**Reference ID Format:**
```
{projectId-10char}-{timestamp-6digit}
```
Contoh: `abc1234567-123456`

### 2. QRIS Payment Dialog (`lib/presentation/widgets/qris_payment_dialog.dart`)
Dialog Material Design untuk menampilkan QR code pembayaran dengan **Pretty QR Code**.

**Features:**
- Menampilkan informasi project (nama, penjual, harga)
- **QR code cantik dengan rounded corners** menggunakan `PrettyQrView`
- QR code dengan warna sesuai theme aplikasi (primary color)
- **Gradient background** untuk visual yang lebih menarik
- **Box shadow** untuk depth effect
- Tombol copy QRIS code ke clipboard
- Instruksi pembayaran
- Return `true` jika user konfirmasi pembayaran selesai

**Pretty QR Code Styling:**
```dart
PrettyQrView.data(
  data: qrisString,
  errorCorrectLevel: QrErrorCorrectLevel.H,
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Theme.of(context).primaryColor, // Warna sesuai theme
      roundFactor: 0.6, // Rounded corners (0.0 - 1.0)
    ),
  ),
)
```

**Design Features:**
- Gradient container dengan primary color
- White QR code container dengan shadow
- Rounded corners untuk modern look
- Gradient button dengan "Scan untuk Membayar"
- Icon qr_code_scanner yang intuitif

**Usage:**
```dart
final result = await QRISPaymentDialog.show(
  context,
  projectName: 'Artwork Title',
  projectId: 'project123',
  sellerName: 'John Doe',
  price: 100000,
  sellerCity: 'Jakarta',
);

if (result == true) {
  // User confirmed payment
}
```

### 3. Marketplace Integration (`lib/all_code/page/marketplace_page.dart`)
Integrasi payment flow di marketplace.

**Payment Flow:**
1. User klik tombol "Purchase" pada listing
2. System fetch data penjual dari Firestore berdasarkan `ownerId`
3. Tampilkan loading indicator
4. Tampilkan QRISPaymentDialog dengan data lengkap
5. User scan QR code dengan mobile banking
6. User klik "Selesai" setelah pembayaran berhasil
7. System refresh data marketplace

**Modified Function:**
```dart
Future<void> _purchaseListing(StoreListing listing) async {
  // 1. Show loading
  // 2. Fetch seller data from Firestore users collection
  // 3. Show QRIS dialog
  // 4. Handle payment confirmation
  // 5. Refresh data
}
```

## Data Model

### StoreListing Model
```dart
class StoreListing {
  final String id;
  final String title;
  final String projectId;
  final String ownerId;  // User ID penjual
  final double price;
  // ... other fields
}
```

### User Model
```dart
class User {
  final String uid;
  final String displayName;  // Digunakan sebagai seller name
  final String email;
  // ... other fields
}
```

## Cara Kerja

### 1. Generate QRIS Code
Ketika user klik purchase:
```
marketplace_page.dart
  └─> Fetch seller from Firestore users/{ownerId}
  └─> QRISPaymentDialog.show()
      └─> QRISPaymentService.generateProjectPaymentQRIS()
          └─> QRISHelper._buildQRISContent()
              └─> Generate EMV format QRIS string
              └─> Calculate CRC-16 checksum
          └─> Return QRIS string
      └─> Display QR code using QrImageView
```

### 2. Payment Process
```
User scan QR code
  └─> Mobile banking app membaca QRIS
  └─> Tampilkan detail:
      - Merchant: "John Doe - Artwork Title"
      - Amount: Rp 100.000
      - Reference: abc1234567-123456
  └─> User konfirmasi pembayaran
  └─> User klik "Selesai" di dialog
  └─> Return true ke marketplace
```

### 3. Post-Payment (TODO - Backend Integration)
Saat ini masih placeholder, perlu implementasi:
- ✅ Generate QRIS code
- ✅ Display QR code
- ✅ User confirmation
- ❌ Verify payment status dari payment gateway
- ❌ Transfer ownership project ke buyer
- ❌ Update user's purchasedItems
- ❌ Kirim notifikasi ke seller dan buyer
- ❌ Update listing totalSold counter
- ❌ Update listing status jika one-time purchase

## Testing QRIS

### Manual Testing
1. Jalankan aplikasi: `flutter run`
2. Navigate ke Marketplace
3. Klik "Purchase" pada listing
4. Verifikasi dialog muncul dengan informasi benar
5. Screenshot QR code atau scan dengan mobile banking
6. Test dengan aplikasi: GoPay, OVO, Dana, BCA Mobile, Mandiri Online, dll

### QR Code Validation
QRIS code yang valid harus:
- Bisa di-scan oleh semua e-wallet Indonesia
- Menampilkan merchant name yang benar
- Menampilkan amount yang sesuai
- Bisa track transaction dengan reference ID

## Error Handling

### Current Implementation
```dart
try {
  // Show loading
  // Fetch seller
  if (!sellerDoc.exists) {
    _showError('Gagal mengambil informasi penjual');
    return;
  }
  
  // Show QRIS dialog
  final result = await QRISPaymentDialog.show(...);
  
  if (result == true) {
    _showSuccess('Pembayaran berhasil!');
    await _refreshData();
  }
} catch (e) {
  // Close loading if still open
  if (mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
  _showError('Gagal membuka pembayaran: $e');
}
```

### Possible Errors
- Seller data not found (handled)
- Network timeout (handled with try-catch)
- QR generation failure (fallback to simple format)
- Invalid amount (validated in service)

## Next Steps (Backend Integration)

### 1. Payment Verification
Implement webhook atau polling untuk verify payment status:
```dart
Future<bool> verifyPayment(String referenceId) async {
  // Call payment gateway API
  // Check transaction status
  // Return true if paid
}
```

### 2. Ownership Transfer
Transfer project ownership setelah payment verified:
```dart
Future<void> transferOwnership({
  required String projectId,
  required String buyerId,
  required String sellerId,
}) async {
  final batch = FirebaseFirestore.instance.batch();
  
  // Update project owner
  // Update seller's myProjects (remove)
  // Update buyer's purchasedItems (add)
  // Update buyer's myProjects (add)
  
  await batch.commit();
}
```

### 3. Transaction History
Simpan record transaksi:
```dart
await FirebaseFirestore.instance
  .collection('transactions')
  .add({
    'buyerId': userId,
    'sellerId': listing.ownerId,
    'projectId': listing.projectId,
    'listingId': listing.id,
    'amount': listing.price,
    'referenceId': referenceId,
    'status': 'pending', // pending, completed, failed
    'createdAt': FieldValue.serverTimestamp(),
  });
```

### 4. Notifications
Kirim notifikasi ke buyer dan seller:
```dart
// Send to seller
await sendNotification(
  userId: listing.ownerId,
  title: 'Karya Terjual!',
  body: '${listing.title} telah dibeli oleh ${buyerName}',
);

// Send to buyer
await sendNotification(
  userId: buyerId,
  title: 'Pembelian Berhasil',
  body: 'Anda sekarang memiliki ${listing.title}',
);
```

## Security Considerations

### Current Implementation
- ✅ Reference ID includes timestamp untuk uniqueness
- ✅ Amount formatted correctly (no decimal tampering)
- ✅ CRC checksum untuk validate QRIS integrity
- ❌ No payment verification (CRITICAL - must implement)
- ❌ No fraud detection
- ❌ No rate limiting

### Recommendations
1. Implement server-side payment verification
2. Add transaction logging untuk audit trail
3. Implement timeout untuk pending payments
4. Add fraud detection (multiple failed attempts)
5. Secure API keys di environment variables
6. Implement refund mechanism

## Format Rupiah

Helper function untuk display amount:
```dart
QRISPaymentService.formatRupiah(100000)
// Output: "Rp 100.000"

QRISPaymentService.formatRupiah(1500000)
// Output: "Rp 1.500.000"
```

## Troubleshooting

### QR Code Tidak Bisa Di-scan
- Periksa QRIS string format (harus sesuai EMV standard)
- Verify CRC checksum calculation
- Test dengan multiple e-wallet apps
- Check QR code size (minimal 150x150px)

### Amount Salah
- Periksa data type (harus double)
- Verify formatTag untuk tag 54
- Check currency code (harus "360")

### Reference ID Duplicate
- Timestamp collision (sudah handled dengan milliseconds)
- ProjectId terlalu pendek (min 10 char recommended)

### Dialog Tidak Muncul
- Check context masih mounted
- Verify import path dialog
- Check for blocking dialogs

## Resources

- EMV QRIS Standard: https://www.bi.go.id/qris
- Package qris: https://pub.dev/packages/qris
- Package pretty_qr_code: https://pub.dev/packages/pretty_qr_code
- Firebase Firestore: https://firebase.google.com/docs/firestore

## Pretty QR Code Customization

### Available Shapes
```dart
// Smooth rounded QR (Recommended)
PrettyQrSmoothSymbol(
  color: Colors.black,
  roundFactor: 0.6, // 0.0 = square, 1.0 = circle
)

// Circle QR
PrettyQrRoundedSymbol(color: Colors.black)

// Default square QR
PrettyQrDefaultSymbol(color: Colors.black)
```

### Color Customization
```dart
// Single color
color: Theme.of(context).primaryColor

// Custom color
color: Color(0xFF3674B5)

// Dark mode support
color: Theme.of(context).brightness == Brightness.dark 
  ? Colors.white 
  : Colors.black
```

### Error Correction Levels
- `QrErrorCorrectLevel.L` - Low (7% recovery)
- `QrErrorCorrectLevel.M` - Medium (15% recovery)
- `QrErrorCorrectLevel.Q` - Quartile (25% recovery)
- **`QrErrorCorrectLevel.H` - High (30% recovery)** ← Recommended untuk QRIS

## Contact & Support

Untuk pertanyaan atau bug report:
- Check TODO comments di code
- Review error logs di console
- Test dengan real mobile banking apps
