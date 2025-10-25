# Pretty QR Code Examples & Customization

Panduan lengkap untuk kustomisasi QR code di aplikasi Muraloka menggunakan `pretty_qr_code: ^3.5.0`

## 📱 Current Implementation (QRIS Payment)

QR code yang saat ini digunakan di marketplace:

```dart
PrettyQrView.data(
  data: qrisString,
  errorCorrectLevel: QrErrorCorrectLevel.H,
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Theme.of(context).primaryColor,
      roundFactor: 0.6,
    ),
  ),
)
```

**Features:**
- ✅ Smooth rounded corners untuk modern look
- ✅ Warna sesuai primary color aplikasi
- ✅ High error correction (30% recovery)
- ✅ Gradient background container
- ✅ Box shadow untuk depth

---

## 🎨 Style Variations

### 1. Classic Black QR (Default)
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: const PrettyQrDecoration(
    shape: PrettyQrDefaultSymbol(
      color: Colors.black,
    ),
  ),
)
```
**Use Case:** Maximum compatibility, professional look

---

### 2. Rounded Modern QR (Current)
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Theme.of(context).primaryColor,
      roundFactor: 0.6,
    ),
  ),
)
```
**Use Case:** Modern apps, branded QR codes

---

### 3. Fully Circular QR
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: const PrettyQrDecoration(
    shape: PrettyQrRoundedSymbol(
      color: Colors.black,
    ),
  ),
)
```
**Use Case:** Artistic design, unique branding

---

### 4. Gradient QR Code
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      brush: PrettyQrBrush.gradient(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3674B5),
            Color(0xFF1E3A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      roundFactor: 0.5,
    ),
  ),
)
```
**Use Case:** Premium look, brand identity

---

### 5. Custom Color QR
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: const PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Color(0xFF3674B5), // Brand color
      roundFactor: 0.7,
    ),
  ),
)
```
**Use Case:** Brand consistency

---

### 6. Dark Mode Adaptive QR
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      roundFactor: 0.5,
    ),
  ),
)
```
**Use Case:** Apps with dark mode support

---

## 🖼️ With Logo/Image (Optional)

### Adding Center Logo
```dart
PrettyQrView.data(
  data: qrisString,
  decoration: const PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Colors.black,
      roundFactor: 0.5,
    ),
    image: PrettyQrDecorationImage(
      image: AssetImage('assets/logo.png'),
      position: PrettyQrDecorationImagePosition.embedded,
    ),
  ),
)
```

**Important:** 
- Logo tidak boleh terlalu besar (max 20% dari QR)
- Use high error correction level (H)
- Test scannability dengan logo

---

## 📦 Container Styling (Current Implementation)

### Gradient Container with Shadow
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Theme.of(context).primaryColor.withOpacity(0.02),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Theme.of(context).primaryColor.withOpacity(0.2),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: PrettyQrView.data(...),
)
```

---

## 🎯 Best Practices

### ✅ DO's
- Use `QrErrorCorrectLevel.H` untuk QRIS payment
- Match QR color dengan brand identity
- Add sufficient padding around QR (min 16px)
- Use white/light background untuk better scan
- Test dengan multiple QR scanner apps
- Ensure minimum size 150x150px

### ❌ DON'Ts
- Jangan gunakan warna terlalu terang (difficult to scan)
- Hindari complex gradient untuk production
- Jangan tambahkan terlalu banyak decoration
- Jangan crop QR code edges
- Hindari low contrast (QR vs background)

---

## 🧪 Testing Checklist

- [ ] Scan dengan Google Lens
- [ ] Scan dengan camera native (iOS/Android)
- [ ] Test di GoPay app
- [ ] Test di OVO app
- [ ] Test di Dana app
- [ ] Test di mobile banking apps
- [ ] Test dalam kondisi cahaya rendah
- [ ] Test dengan screenshot QR
- [ ] Test print QR code
- [ ] Test dari berbagai jarak

---

## 🎨 Color Palette Suggestions

### Professional (Finance/Banking)
```dart
color: Color(0xFF1E3A5F) // Navy Blue
color: Color(0xFF2C5F2D) // Forest Green
color: Color(0xFF4A4A4A) // Dark Gray
```

### Modern (Tech/Startup)
```dart
color: Color(0xFF3674B5) // Current Muraloka Blue
color: Color(0xFF6366F1) // Indigo
color: Color(0xFF8B5CF6) // Purple
```

### Vibrant (Creative/Art)
```dart
color: Color(0xFFE11D48) // Rose
color: Color(0xFFEA580C) // Orange
color: Color(0xFF7C3AED) // Violet
```

---

## 📊 Performance Tips

1. **Pre-generate QR Data**
   ```dart
   final qrCode = QrCode.fromData(
     data: qrisString,
     errorCorrectLevel: QrErrorCorrectLevel.H,
   );
   
   // Cache untuk reuse
   ```

2. **Use const Decorations**
   ```dart
   const decoration = PrettyQrDecoration(
     shape: PrettyQrSmoothSymbol(
       color: Colors.black,
       roundFactor: 0.5,
     ),
   );
   ```

3. **Lazy Loading untuk Multiple QRs**
   - Load QR on demand
   - Cache generated images
   - Use `ListView.builder` untuk list QR codes

---

## 🔧 Advanced Customization

### Custom QR Matrix
```dart
PrettyQrView(
  qrImage: QrImage(QrCode.fromData(
    data: qrisString,
    errorCorrectLevel: QrErrorCorrectLevel.H,
  )),
  decoration: PrettyQrDecoration(...),
)
```

### Export QR as Image
```dart
final qrCode = QrCode.fromData(
  data: qrisString,
  errorCorrectLevel: QrErrorCorrectLevel.H,
);

final qrImage = QrImage(qrCode);
final imageData = await qrImage.toImageAsUint8List(
  size: 512,
  format: ImageByteFormat.png,
  decoration: PrettyQrDecoration(...),
);

// Save or share imageData
```

---

## 📱 Responsive Sizing

### Mobile
```dart
size: MediaQuery.of(context).size.width * 0.6
```

### Tablet
```dart
size: 300.0
```

### Desktop
```dart
size: 400.0
```

### Adaptive
```dart
double getQrSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 600) return 350.0; // Tablet/Desktop
  return width * 0.65; // Mobile
}
```

---

## 🌟 Pro Tips

1. **Always test scannability** setelah styling changes
2. **Use high contrast** (dark QR, light background)
3. **Keep it simple** untuk critical payments
4. **Brand consistency** > Complex design
5. **Accessibility first** - ensure QR readable

---

## 📞 Support

Jika QR code tidak bisa di-scan:
1. Cek error correction level (min M, recommended H)
2. Pastikan kontras cukup tinggi
3. Verifikasi QRIS string format benar
4. Test dengan QR scanner tool online
5. Check minimum size (min 150x150px)

---

**Last Updated:** October 25, 2025  
**Package Version:** pretty_qr_code ^3.5.0  
**Tested On:** Android & iOS
