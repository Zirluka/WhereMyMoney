import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/receipt_qr_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final parsed = ReceiptQrParser.parse(rawValue);
        if (parsed != null) {
          _isProcessing = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(parsed);
          return;
        }
      }
    }
  }

  void _simulateScanForTesting() {
    // Демонстрационный фискальный чек для тестирования на ПК и эмуляторах
    const mockFiscalQr =
        't=20261012T154500&s=1580.40&fn=9960440300123456&i=24510&fp=1928374650&n=1';
    final parsed = ReceiptQrParser.parse(mockFiscalQr);
    if (parsed != null) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Сканер чеков',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppColors.warning : Colors.white,
            ),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера сканера
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          size: 56, color: AppColors.expense),
                      const SizedBox(height: 16),
                      Text(
                        'Камера недоступна или нет разрешения: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Тестовый чек (Эмулятор/ПК)'),
                        onPressed: _simulateScanForTesting,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Рамка видоискателя
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.income, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.income.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Подсказка внизу экрана
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_rounded,
                          color: AppColors.income, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Наведите камеру на QR-код чека. Сумма и дата распознаются мгновенно.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                    ),
                    icon: const Icon(Icons.bug_report_rounded, size: 18),
                    label: const Text('Эмулировать сканирование чека'),
                    onPressed: _simulateScanForTesting,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
