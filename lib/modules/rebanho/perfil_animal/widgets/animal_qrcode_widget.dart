import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get/get.dart';

/// --- COMPONENTE DE RASTREABILIDADE VIA QR CODE ---
/// Este widget renderiza o QR Code único do animal para identificação no campo.
class AnimalQRCodeWidget extends StatelessWidget {
  final String animalId; // ID único do banco de dados ou Identificador (Brinco)
  final String identifier; // Texto amigável para exibir abaixo
  final bool showExport; // Se deve exibir o botão de exportar

  const AnimalQRCodeWidget({
    Key? key,
    required this.animalId,
    required this.identifier,
    this.showExport = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Identificação por QR Code",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Geração do QR Code com Link para a Web
          QrImageView(
            data: "https://agrogen-crateus-2026.web.app/animal/$animalId",
            version: QrVersions.auto,
            size: 150.0,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(10),
          ),
          
          const SizedBox(height: 8),
          Text(
            identifier,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          
          if (showExport) ...[
            const SizedBox(height: 16),
            
            // Botão para exportar/imprimir
            OutlinedButton.icon(
              onPressed: () {
                Get.snackbar(
                  "Exportar QR Code", 
                  "Gerando arquivo PDF para impressão...",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green[800],
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text("Exportar para Impressão"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[800],
                side: BorderSide(color: Colors.green[800]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
