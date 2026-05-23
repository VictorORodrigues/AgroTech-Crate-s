import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'perfil_animal_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PerfilAnimalView extends StatelessWidget {
  final PerfilAnimalController controller = Get.put(PerfilAnimalController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Obx(() => Text(
          controller.isEditing.value ? "Editando Animal" : (controller.animal['identifier'] ?? 'Perfil'),
          style: const TextStyle(color: Colors.white)
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Get.toNamed('/add-animal', arguments: {
              'herd': {'id': controller.animal['herd_id'], 'category': controller.animal['category']},
              'isEdition': true,
              'animal': controller.animal.value,
            }),
          )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Seção da Foto
            Center(
              child: Stack(
                children: [
                  Obx(() => Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (controller.photoPath.value.isNotEmpty) {
                          _showFullScreenImage(context);
                        }
                      },
                      child: ClipOval(
                        child: controller.photoPath.value.isNotEmpty
                            ? Image.file(File(controller.photoPath.value), fit: BoxFit.cover)
                            : _buildPlaceholderIcon(),
                      ),
                    ),
                  )),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showPickerOptions(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green[800], shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildViewDetails(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildViewDetails() {
    return Column(
      children: [
        _buildInfoCard(
          "Dados Principais",
          [
            _buildDetailRow("ID ou Brinco", controller.animal['identifier']),
            _buildDetailRow("Apelido", controller.animal['name'] ?? "N/A"),
            _buildDetailRow("Peso", "${controller.animal['weight']} kg"),
            _buildDetailRow("Idade", "${controller.animal['age_months']} meses"),
            _buildDetailRow("Sexo", controller.animal['sex']),
            _buildDetailRow("Nome da Raça", controller.animal['breed_name'] ?? "N/A"),
            _buildDetailRow("Categoria (IA)", controller.animal['breed']),
            _buildDetailRow("ECC", controller.animal['ecc'].toString()),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          "Genética e Genealogia",
          [
            _buildDetailRow("Linhagem", controller.animal['lineage'] ?? "N/A"),
            _buildDetailRow("Pai", controller.animal['id_pai'] ?? "Desconhecido"),
            _buildDetailRow("Mãe", controller.animal['id_mae'] ?? "Desconhecido"),
          ],
        ),
        if (controller.animal['sex'] == 'Fêmea') ...[
          const SizedBox(height: 20),
          _buildActionTile(
            title: "Histórico Reprodutivo",
            subtitle: "Ver ciclos, cios e inseminações deste animal",
            icon: Icons.history,
            onTap: () => Get.toNamed('/historico-animal', arguments: controller.animal),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            "Dados Reprodutivos",
            [
              _buildDetailRow("Paridade", controller.animal['parity'] ?? "N/A"),
              if (controller.animal['parity'] != 'Nulípara') 
                _buildDetailRow("DPP", controller.animal['dpp_status'] ?? "N/A"),
              _buildDetailRow("Status Atual", controller.animal['reproductive_status'] ?? "Vazia / Apta"),
            ],
          ),
        ],
        if (controller.animal['sex'] == 'Macho') ...[
          const SizedBox(height: 20),
          _buildInfoCard(
            "Dados de Reprodutor",
            [
              _buildDetailRow("Aptidão", controller.animal['aptitude'] ?? "N/A"),
              _buildDetailRow("Fertilidade", "${((controller.animal['semen_fertility'] ?? 0.0) * 100).toInt()}%"),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    final String category = controller.animal['category'] ?? "Bovino";
    if (category == 'Bovino') return const Center(child: FaIcon(FontAwesomeIcons.cow, size: 50, color: Colors.grey));
    if (category == 'Ovino') return const Center(child: Icon(Icons.pets, size: 50, color: Colors.grey));
    return const Center(child: Icon(Icons.agriculture, size: 50, color: Colors.grey));
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: Icon(icon, color: Colors.green[800]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(controller.photoPath.value),
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ));
  }

  void _showPickerOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Foto do Animal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Tirar Foto"),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("Escolher da Galeria"),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.gallery);
              },
            ),
            Obx(() => controller.photoPath.value.isNotEmpty
              ? ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Remover Foto", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    controller.removePhoto();
                  },
                )
              : const SizedBox.shrink()),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
