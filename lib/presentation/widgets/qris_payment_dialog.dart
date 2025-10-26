import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../utils/qris_payment_service.dart';
import '../../constant/constant.dart';

class QRISPaymentDialog extends StatelessWidget {
  final String projectName;
  final String projectId;
  final String sellerName;
  final double price;
  final String? sellerCity;

  const QRISPaymentDialog({
    Key? key,
    required this.projectName,
    required this.projectId,
    required this.sellerName,
    required this.price,
    this.sellerCity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate QRIS code
    final qrisString = QRISPaymentService.generateProjectPaymentQRIS(
      projectName: projectName,
      projectId: projectId,
      sellerName: sellerName,
      price: price,
      sellerCity: sellerCity ?? 'Jakarta',
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.qr_code_2,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran QRIS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scan QR code untuk membayar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getTextTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceVariant(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, size: 16, color: AppColors.getTextTertiary(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: AppColors.getTextTertiary(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sellerName,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.getTextTertiary(context),
                        ),
                      ),
                      Text(
                        QRISPaymentService.formatRupiah(price),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code with Pretty Design
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.getSurface(context),
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
              child: Column(
                children: [
                  // Pretty QR Code with custom styling
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(context),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PrettyQrView.data(
                      data: qrisString,
                      errorCorrectLevel: QrErrorCorrectLevel.H,
                      decoration: PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(
                          color: Theme.of(context).primaryColor,
                          roundFactor: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR Code Label with icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: AppColors.lightSurface,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scan untuk Membayar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.lightSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copy Button
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrisString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QRIS code berhasil disalin!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Salin QRIS Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightInfo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.lightInfo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan QR code menggunakan aplikasi mobile banking atau e-wallet yang mendukung QRIS',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lightTextPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Return true untuk konfirmasi pembayaran
                    },
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show QRIS payment dialog
  static Future<bool?> show(
    BuildContext context, {
    required String projectName,
    required String projectId,
    required String sellerName,
    required double price,
    String? sellerCity,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRISPaymentDialog(
        projectName: projectName,
        projectId: projectId,
        sellerName: sellerName,
        price: price,
        sellerCity: sellerCity,
      ),
    );
  }
}
