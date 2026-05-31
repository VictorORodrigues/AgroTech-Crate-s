import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';

class AnimalScannerView extends StatefulWidget {
  @override
  State<AnimalScannerView> createState() => _AnimalScannerViewState();
}

class _AnimalScannerViewState extends State<AnimalScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Animal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.red);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  case CameraFacing.external:
                  case CameraFacing.unknown:
                    return const Icon(Icons.camera);
                  default:
                    return const Icon(Icons.camera);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
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
          // Overlay visual para focar o scanner
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Aponte para o QR Code do animal',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) async {
    // Feedback visual/sonoro pode ser implementado aqui
    
    try {
      final db = await DatabaseHelper.instance.database;
      // O QR Code contém o ID único (Primary Key) do animal no banco
      final List<Map<String, dynamic>> result = await db.query(
        'animals',
        where: 'id = ?',
        whereArgs: [code],
      );

      if (result.isNotEmpty) {
        Get.back(); // Fecha a câmera
        Get.toNamed('/perfil-animal', arguments: result.first);
      } else {
        // Tenta buscar pelo identificador (brinco) caso o QR não seja o ID interno
        final List<Map<String, dynamic>> resultByIdentifier = await db.query(
          'animals',
          where: 'identifier = ?',
          whereArgs: [code],
        );
        
        if (resultByIdentifier.isNotEmpty) {
          Get.back();
          Get.toNamed('/perfil-animal', arguments: resultByIdentifier.first);
        } else {
          _isProcessing = false;
          Get.snackbar(
            "Animal não encontrado", 
            "O código '$code' não corresponde a nenhum animal no banco local.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[800],
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      _isProcessing = false;
      AgroAlert.show(title: "Erro no Scanner", message: "Falha ao processar o código: $e", isError: true);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
