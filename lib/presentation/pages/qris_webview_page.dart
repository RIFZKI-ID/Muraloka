import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple WebView page to display QRIS payment image
class QRISWebViewPage extends StatefulWidget {
  final String listingTitle;
  final double price;

  const QRISWebViewPage({
    Key? key,
    required this.listingTitle,
    required this.price,
  }) : super(key: key);

  @override
  State<QRISWebViewPage> createState() => _QRISWebViewPageState();
}

class _QRISWebViewPageState extends State<QRISWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Format price to Rupiah
    final formattedPrice = 'Rp ${widget.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
    
    // Create HTML content with the QRIS image
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }
            .container {
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                max-width: 500px;
                width: 100%;
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
            }
            .header h1 {
                font-size: 24px;
                margin-bottom: 10px;
                font-weight: 700;
            }
            .header p {
                opacity: 0.9;
                font-size: 14px;
            }
            .content {
                padding: 30px 20px;
            }
            .info-card {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 20px;
                margin-bottom: 20px;
            }
            .info-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 12px;
                padding-bottom: 12px;
                border-bottom: 1px solid #e9ecef;
            }
            .info-row:last-child {
                margin-bottom: 0;
                padding-bottom: 0;
                border-bottom: none;
            }
            .info-label {
                color: #6c757d;
                font-size: 14px;
            }
            .info-value {
                color: #212529;
                font-weight: 600;
                font-size: 14px;
                text-align: right;
                max-width: 60%;
                word-wrap: break-word;
            }
            .price {
                font-size: 32px !important;
                color: #667eea !important;
                font-weight: 700 !important;
            }
            .qr-container {
                text-align: center;
                padding: 20px;
                background: white;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            }
            .qr-container img {
                max-width: 100%;
                height: auto;
                border-radius: 8px;
            }
            .qr-label {
                margin-top: 15px;
                font-size: 14px;
                color: #6c757d;
            }
            .instructions {
                margin-top: 20px;
                padding: 20px;
                background: #e7f3ff;
                border-left: 4px solid #667eea;
                border-radius: 8px;
            }
            .instructions h3 {
                color: #667eea;
                font-size: 16px;
                margin-bottom: 15px;
                font-weight: 700;
            }
            .instructions ol {
                padding-left: 20px;
                color: #495057;
            }
            .instructions li {
                margin-bottom: 10px;
                line-height: 1.6;
                font-size: 14px;
            }
            .footer {
                padding: 20px;
                text-align: center;
                background: #f8f9fa;
                border-top: 1px solid #e9ecef;
            }
            .footer p {
                color: #6c757d;
                font-size: 12px;
                margin: 5px 0;
            }
            .badge {
                display: inline-block;
                padding: 4px 12px;
                background: #28a745;
                color: white;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 600;
                margin-top: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>💳 QRIS Payment</h1>
                <p>Scan QR Code untuk melakukan pembayaran</p>
            </div>
            
            <div class="content">
                <!-- Payment Info -->
                <div class="info-card">
                    <div class="info-row">
                        <span class="info-label">🛍️ Item</span>
                        <span class="info-value">${widget.listingTitle}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">💰 Total Pembayaran</span>
                        <span class="info-value price">$formattedPrice</span>
                    </div>
                </div>

                <!-- QR Code Image -->
                <div class="qr-container">
                    <img src="https://raw.githubusercontent.com/RIFZKI-ID/Muraloka/refs/heads/updated/assets/images/qris_example.jpg" alt="QRIS Payment">
                    <p class="qr-label">
                        <strong>RIFZKI ID</strong><br>
                        NMID: ID1024318412755<br>
                        <span class="badge">QRIS Standar GPN</span>
                    </p>
                </div>

                <!-- Instructions -->
                <div class="instructions">
                    <h3>📱 Cara Pembayaran:</h3>
                    <ol>
                        <li>Buka aplikasi mobile banking atau e-wallet Anda</li>
                        <li>Pilih menu <strong>Scan QR</strong> atau <strong>QRIS</strong></li>
                        <li>Arahkan kamera ke QR Code di atas</li>
                        <li>Pastikan nominal sesuai: <strong>$formattedPrice</strong></li>
                        <li>Masukkan PIN dan konfirmasi pembayaran</li>
                        <li>Simpan bukti pembayaran Anda</li>
                    </ol>
                </div>
            </div>

            <div class="footer">
                <p><strong>Muraloka Marketplace</strong></p>
                <p>Pembayaran aman dengan QRIS - Standar Nasional</p>
                <p style="margin-top: 10px; font-size: 11px;">
                    Setelah pembayaran berhasil, project akan otomatis tersedia di "My Projects"
                </p>
            </div>
        </div>
    </body>
    </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QRIS Payment'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ℹ️ Info Pembayaran'),
                  content: const Text(
                    'Ini adalah contoh pembayaran QRIS.\n\n'
                    'Pada implementasi sebenarnya:\n'
                    '• QR code akan di-generate secara dinamis\n'
                    '• Terintegrasi dengan payment gateway\n'
                    '• Verifikasi pembayaran otomatis\n'
                    '• Transfer project ownership otomatis\n\n'
                    'Saat ini hanya untuk demonstrasi UI/UX.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Info',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Batal'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('✅ Konfirmasi Pembayaran'),
                        content: const Text(
                          'Apakah Anda sudah melakukan pembayaran dan ingin menyelesaikan transaksi?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Belum'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context, true); // Return to marketplace with success
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Sudah Bayar'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Pembayaran Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
