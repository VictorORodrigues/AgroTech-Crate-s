import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../navigation/navigation_controller.dart';

class AnimalScannerView extends StatefulWidget {
  @override
  State<AnimalScannerView> createState() => _AnimalScannerViewState();
}

class _AnimalScannerViewState extends State<AnimalScannerView> with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _scannerAnimationController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerAnimationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Get.back();
    } else if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changePage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _handleBack,
            ),
          ),
        ),
        title: const Text(
          'Escanear Animal', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: cameraController,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: state.torchState == TorchState.on ? Colors.yellow : Colors.white,
                    size: 20,
                  );
                },
              ),
              onPressed: () => cameraController.toggleTorch(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 20),
              onPressed: () => cameraController.switchCamera(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                _isProcessing = true;
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _handleScannedCode(code);
                }
              }
            },
          ),
          // Overlay de escaneamento escuro
          Container(
            decoration: ShapeDecoration(
              shape: ScannerOverlayShape(
                borderColor: Colors.green[800]!,
                borderRadius: 20,
                borderLength: 30,
                borderWidth: 6,
                cutOutSize: 260,
              ),
            ),
          ),
          // Linha de scan animada
          Center(
            child: AnimatedBuilder(
              animation: _scannerAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -130 + (260 * _scannerAnimationController.value)),
                  child: Container(
                    width: 240,
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.greenAccent.withOpacity(0),
                          Colors.greenAccent,
                          Colors.greenAccent.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Instrução na base
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Aproxime o QR Code do animal',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) async {
    try {
      // 1. Verifica se é o Link da Web (Agro 4.0)
      if (code.contains("agrogen-crateus-2026.web.app/animal/")) {
        final uri = Uri.parse(code);
        if (await canLaunchUrl(uri)) {
          Get.back();
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // 2. Fallback: Busca por ID ou Identificador Local (Legacy)
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> result = await db.query(
        'animals',
        where: 'id = ? OR identifier = ?',
        whereArgs: [code, code],
      );

      if (result.isNotEmpty) {
        Get.back();
        Get.toNamed('/perfil-animal', arguments: result.first);
      } else {
        _showInvalidCodeSheet(code);
      }
    } catch (e) {
      _isProcessing = false;
      AgroAlert.show(title: "Erro no Scanner", message: "Falha ao processar o código: $e", isError: true);
    }
  }

  void _showInvalidCodeSheet(String code) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_scanner, color: Colors.red[800], size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              "Código não reconhecido",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "O código lido não pertence a nenhum animal cadastrado no sistema AgroTech Crateús.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black54),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  _isProcessing = false;
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("TENTAR NOVAMENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final cutoutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(cutoutRect.left, cutoutRect.top + borderLength);
    path.lineTo(cutoutRect.left, cutoutRect.top + borderRadius);
    path.quadraticBezierTo(cutoutRect.left, cutoutRect.top, cutoutRect.left + borderRadius, cutoutRect.top);
    path.lineTo(cutoutRect.left + borderLength, cutoutRect.top);

    path.moveTo(cutoutRect.right - borderLength, cutoutRect.top);
    path.lineTo(cutoutRect.right - borderRadius, cutoutRect.top);
    path.quadraticBezierTo(cutoutRect.right, cutoutRect.top, cutoutRect.right, cutoutRect.top + borderRadius);
    path.lineTo(cutoutRect.right, cutoutRect.top + borderLength);

    path.moveTo(cutoutRect.right, cutoutRect.bottom - borderLength);
    path.lineTo(cutoutRect.right, cutoutRect.bottom - borderRadius);
    path.quadraticBezierTo(cutoutRect.right, cutoutRect.bottom, cutoutRect.right - borderRadius, cutoutRect.bottom);
    path.lineTo(cutoutRect.right - borderLength, cutoutRect.bottom);

    path.moveTo(cutoutRect.left + borderLength, cutoutRect.bottom);
    path.lineTo(cutoutRect.left + borderRadius, cutoutRect.bottom);
    path.quadraticBezierTo(cutoutRect.left, cutoutRect.bottom, cutoutRect.left, cutoutRect.bottom - borderRadius);
    path.lineTo(cutoutRect.left, cutoutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
