class QRISPaymentService {
  /// Generate QRIS code untuk pembayaran marketplace
  /// 
  /// [merchantName] - Nama merchant (seller)
  /// [merchantCity] - Kota merchant
  /// [amount] - Harga dalam Rupiah
  /// [referenceId] - ID marketplace atau nama canvas sebagai reference
  static String generateQRIS({
    required String merchantName,
    required String merchantCity,
    required double amount,
    required String referenceId,
  }) {
    try {
      // Create QRIS string menggunakan helper method
      // Format: merchant_name|merchant_city|amount|reference
      final qrisData = QRISHelper.generateQRCode(
        merchantName: merchantName.length > 25 ? merchantName.substring(0, 25) : merchantName,
        merchantCity: merchantCity.length > 15 ? merchantCity.substring(0, 15) : merchantCity,
        amount: amount,
        merchantCategoryCode: '7999', // Miscellaneous Business Services
        merchantID: referenceId.substring(0, referenceId.length > 15 ? 15 : referenceId.length),
      );
      
      print('✅ QRIS generated successfully');
      print('   Merchant: $merchantName');
      print('   Amount: Rp ${amount.toStringAsFixed(0)}');
      print('   Reference: $referenceId');
      
      return qrisData;
    } catch (e) {
      print('❌ Error generating QRIS: $e');
      
      // Fallback: generate simple QRIS string jika error
      return _generateSimpleQRIS(
        merchantName: merchantName,
        amount: amount,
        referenceId: referenceId,
      );
    }
  }

  /// Fallback method untuk generate simple QRIS
  static String _generateSimpleQRIS({
    required String merchantName,
    required double amount,
    required String referenceId,
  }) {
    // Simple format QRIS string
    // Ini adalah format sederhana, dalam production sebaiknya gunakan API yang proper
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'QRIS|$merchantName|${amount.toStringAsFixed(0)}|$referenceId|$timestamp';
  }

  /// Parse QRIS string untuk validasi
  static Map<String, dynamic>? parseQRIS(String qrisString) {
    try {
      if (qrisString.startsWith('QRIS|')) {
        // Parse simple format
        final parts = qrisString.split('|');
        if (parts.length >= 5) {
          return {
            'type': 'simple',
            'merchantName': parts[1],
            'amount': double.tryParse(parts[2]) ?? 0,
            'referenceId': parts[3],
            'timestamp': parts[4],
          };
        }
      }
      
      // Try parse with QRIS package
      return {
        'type': 'qris',
        'data': qrisString,
      };
    } catch (e) {
      print('❌ Error parsing QRIS: $e');
      return null;
    }
  }

  /// Validasi QRIS string
  static bool validateQRIS(String qrisString) {
    try {
      if (qrisString.isEmpty) return false;
      
      // Check simple format
      if (qrisString.startsWith('QRIS|')) {
        final parts = qrisString.split('|');
        return parts.length >= 5;
      }
      
      // Check QRIS format (minimal length)
      return qrisString.length > 50;
    } catch (e) {
      return false;
    }
  }

  /// Generate QRIS untuk project marketplace
  /// 
  /// [projectName] - Nama project/canvas
  /// [projectId] - ID project di marketplace
  /// [sellerName] - Nama penjual
  /// [price] - Harga project
  static String generateProjectPaymentQRIS({
    required String projectName,
    required String projectId,
    required String sellerName,
    required double price,
    String sellerCity = 'Jakarta', // Default city
  }) {
    // Buat reference ID dari project ID dan timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final referenceId = '${projectId.substring(0, projectId.length > 10 ? 10 : projectId.length)}-$timestamp';
    
    return generateQRIS(
      merchantName: '$sellerName - $projectName',
      merchantCity: sellerCity,
      amount: price,
      referenceId: referenceId,
    );
  }

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    final formatter = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatter';
  }
}

/// Helper class untuk generate QRIS
class QRISHelper {
  static String generateQRCode({
    required String merchantName,
    required String merchantCity,
    required double amount,
    required String merchantCategoryCode,
    required String merchantID,
  }) {
    // Gunakan QRIS package untuk generate
    // Format dasar QRIS menggunakan EMV standard
    
    // Buat QRIS content dengan format yang benar
    final qrisContent = _buildQRISContent(
      merchantName: merchantName,
      merchantCity: merchantCity,
      amount: amount,
      merchantCategoryCode: merchantCategoryCode,
      merchantID: merchantID,
    );
    
    return qrisContent;
  }
  
  static String _buildQRISContent({
    required String merchantName,
    required String merchantCity,
    required double amount,
    required String merchantCategoryCode,
    required String merchantID,
  }) {
    // Build EMV QRIS format
    final buffer = StringBuffer();
    
    // Payload Format Indicator (ID: 00)
    buffer.write(_formatTag('00', '01'));
    
    // Point of Initiation Method (ID: 01) - Dynamic
    buffer.write(_formatTag('01', '12'));
    
    // Merchant Account Information (ID: 26-51)
    // Menggunakan ID 26 untuk domestic merchant
    final merchantInfo = StringBuffer();
    merchantInfo.write(_formatTag('00', '936009')); // Acquirer ID
    merchantInfo.write(_formatTag('01', merchantID));
    buffer.write(_formatTag('26', merchantInfo.toString()));
    
    // Merchant Category Code (ID: 52)
    buffer.write(_formatTag('52', merchantCategoryCode));
    
    // Transaction Currency (ID: 53) - 360 for IDR
    buffer.write(_formatTag('53', '360'));
    
    // Transaction Amount (ID: 54)
    buffer.write(_formatTag('54', amount.toStringAsFixed(0)));
    
    // Country Code (ID: 58)
    buffer.write(_formatTag('58', 'ID'));
    
    // Merchant Name (ID: 59)
    buffer.write(_formatTag('59', merchantName));
    
    // Merchant City (ID: 60)
    buffer.write(_formatTag('60', merchantCity));
    
    // CRC (ID: 63) - Will be calculated at the end
    final payload = buffer.toString();
    final crc = _calculateCRC(payload + '6304');
    buffer.write('63');
    buffer.write('04');
    buffer.write(crc);
    
    return buffer.toString();
  }
  
  static String _formatTag(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }
  
  static String _calculateCRC(String data) {
    // Simple CRC-16/CCITT-FALSE calculation
    int crc = 0xFFFF;
    final bytes = data.codeUnits;
    
    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}

