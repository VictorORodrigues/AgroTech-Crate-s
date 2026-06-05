import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'perfil_animal_controller.dart';
import 'widgets/animal_qrcode_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../detalhes_rebanho/detalhes_rebanho_controller.dart';
import '../rebanho_controller.dart';

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
            icon: const Icon(Icons.move_up_outlined, color: Colors.white),
            tooltip: "Realocar Animal",
            onPressed: () => _showRelocateSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _showConfirmDeleteDialog(context),
          ),
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
                        child: ColorFiltered(
                          colorFilter: controller.animal['vital_status'] == 'Inativo'
                            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: Opacity(
                            opacity: controller.animal['vital_status'] == 'Inativo' ? 0.8 : 1.0,
                            child: controller.photoPath.value.isNotEmpty
                                ? Image.file(File(controller.photoPath.value), fit: BoxFit.cover)
                                : _buildPlaceholderIcon(),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() => _buildViewDetails(context)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildViewDetails(BuildContext context) {
    final isInactive = controller.animal['vital_status'] == 'Inativo';
    
    return Column(
      children: [
        if (isInactive)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[100]!)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                const Text("ANIMAL INATIVO (ÓBITO)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        _buildInfoCard(
          "Dados Principais",
          Icons.info_outline,
          [
            _buildDetailRow("ID ou Brinco", controller.animal['identifier']?.toString() ?? "N/A"),
            _buildDetailRow("Apelido", controller.animal['name']?.toString() ?? "N/A"),
            _buildDetailRow("Data Nascimento", controller.animal['birth_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(controller.animal['birth_date'])) : "Não informada"),
            if (isInactive)
              _buildDetailRow("Data do Óbito", controller.animal['death_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(controller.animal['death_date'])) : "N/A"),
            _buildDetailRow("Peso", "${controller.animal['weight'] ?? '0'} kg"),
            _buildDetailRow("Idade", "${controller.animal['age_months'] ?? '0'} meses"),
            _buildDetailRow("Sexo", controller.animal['sex']?.toString() ?? "N/A"),
            _buildDetailRow("Nome da Raça", controller.animal['breed_name']?.toString() ?? "N/A"),
            _buildDetailRow("Categoria", controller.animal['breed']?.toString() ?? "N/A"),
            _buildDetailRow("ECC", controller.animal['ecc']?.toString() ?? "3.0"),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          "Genética e Genealogia",
          Icons.account_tree_outlined,
          [
            _buildDetailRow("Linhagem", controller.animal['lineage']?.toString() ?? "N/A"),
            _buildDetailRow("Pai", controller.animal['id_pai']?.toString() ?? "Desconhecido"),
            _buildDetailRow("Mãe", controller.animal['id_mae']?.toString() ?? "Desconhecido"),
          ],
        ),
        const SizedBox(height: 20),
        _buildActionTile(
          title: "Histórico de Atividades",
          subtitle: "Ver registros de manejo deste animal",
          icon: Icons.history,
          onTap: () => _showAnimalHistoryTimeline(context),
        ),
        if (controller.animal['sex'] == 'Fêmea') ...[
          const SizedBox(height: 20),
          _buildInfoCard(
            "Dados Reprodutivos",
            Icons.favorite_border,
            [
              _buildDetailRow("Aptidão", controller.animal['aptitude']?.toString() == "Rústico" ? "Rústica" : (controller.animal['aptitude']?.toString() ?? "N/A")),
              _buildDetailRow("Paridade", controller.animal['parity']?.toString() ?? "N/A"),
              if (controller.animal['parity']?.toString().trim() != 'Nulípara')
                _buildDetailRow("DPP", controller.animal['dpp_status']?.toString() ?? "N/A"),
              _buildDetailRow("Status Atual", controller.animal['reproductive_status']?.toString() ?? "Vazia / Apta"),
            ],
          ),
        ],
        if (controller.animal['sex'] == 'Macho') ...[
          const SizedBox(height: 20),
          _buildInfoCard(
            "Dados de Reprodutor",
            Icons.bolt,
            [
              _buildDetailRow("Aptidão", controller.animal['aptitude']?.toString() ?? "N/A"),
              _buildDetailRow("Fertilidade", "${(((controller.animal['semen_fertility'] ?? 0.0) as double) * 100).toInt()}%"),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _buildRastreabilidadeSection(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRastreabilidadeSection(BuildContext context) {
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
          Row(
            children: [
              Icon(Icons.qr_code_2_outlined, size: 20, color: Colors.green[800]),
              const SizedBox(width: 8),
              const Text("Rastreabilidade", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          
          // Seção do PDF (Somente visualização)
          const Text("Documentação (PDF)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.pdfPath.value.isEmpty) {
              return const Text("Nenhum documento anexado.", style: TextStyle(fontSize: 12, color: Colors.grey));
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.openPDF(),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Documento de Rastreabilidade.pdf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Toque para visualizar", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          
          // QR Code (Apenas visualização usando o ID numérico do banco)
          Center(
            child: AnimalQRCodeWidget(
              animalId: controller.animal['id']?.toString() ?? "0",
              identifier: controller.animal['identifier']?.toString() ?? "ID Desconhecido",
              showExport: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    final String category = controller.animal['category'] ?? "Bovino";
    String assetPath = 'assets/images/bovino_default.png';
    if (category == 'Ovino') assetPath = 'assets/images/ovino_default.png';
    if (category == 'Caprino') assetPath = 'assets/images/caprino_default.png';

    return Opacity(
      opacity: 0.5,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.green[800]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value ?? "Não informado", style: const TextStyle(color: Colors.black54))),
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

  void _showAnimalHistoryTimeline(BuildContext context) async {
    controller.selectedHistoryFilter.value = "Todos"; // Reset filter
    await controller.loadAnimalHistory();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Histórico: ${controller.animal['identifier']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Filtros de Histórico
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Todos", "Nutrição", "Reprodução", "Saúde"].map((cat) {
                  return Obx(() {
                    bool isSelected = controller.selectedHistoryFilter.value == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat, style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                        selected: isSelected,
                        onSelected: (val) => controller.selectedHistoryFilter.value = cat,
                        selectedColor: Colors.green[800],
                        backgroundColor: context.theme.cardColor,
                        checkmarkColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: Obx(() {
                if (controller.isLoadingHistory.value) return const Center(child: CircularProgressIndicator());
                
                final events = controller.filteredHistory;
                
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          controller.selectedHistoryFilter.value == "Todos"
                            ? "Nenhuma atividade registrada."
                            : "Nenhuma atividade de ${controller.selectedHistoryFilter.value}.",
                          style: const TextStyle(color: Colors.grey)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final e = events[index];
                    return GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.toNamed('/activity-details', arguments: e);
                      },
                      child: _buildHistoryTimelineItem(e, index == events.length - 1),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildHistoryTimelineItem(Map<String, dynamic> event, bool isLast) {
    final type = event['type']?.toString() ?? "";
    final color = _getTimelineColor(type);
    final icon = _getTimelineIcon(type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey[200]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, right: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(event['date'])),
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(type, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event['description'], 
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimelineColor(String type) {
    if (type.contains("Inseminação")) return Colors.pink;
    if (type.contains("Pesagem")) return Colors.blue;
    if (type.contains("Nascimento")) return Colors.orange;
    if (type.contains("Vacinação")) return Colors.red;
    if (type.contains("Medicamento")) return Colors.deepOrange;
    if (type.contains("Leite")) return Colors.teal;
    return Colors.green;
  }

  IconData _getTimelineIcon(String type) {
    if (type.contains("Inseminação")) return Icons.favorite_border;
    if (type.contains("Pesagem")) return Icons.scale_outlined;
    if (type.contains("Nascimento")) return Icons.child_care;
    if (type.contains("Vacinação")) return Icons.vaccines_outlined;
    if (type.contains("Medicamento")) return Icons.medication_outlined;
    if (type.contains("Leite")) return Icons.opacity;
    return Icons.event_note;
  }

  void _showConfirmDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Animal"),
        content: Text("Tem certeza que deseja excluir o animal '${controller.animal['identifier']}'? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('animals', where: 'id = ?', whereArgs: [controller.animal['id']]);
              
              if (Get.isRegistered<DetalhesRebanhoController>()) {
                Get.find<DetalhesRebanhoController>().carregarDados();
              }
              if (Get.isRegistered<RebanhoController>()) {
                Get.find<RebanhoController>().carregarRebanhos();
              }

              Get.back(); // Fecha modal
              Get.back(); // Volta para a lista de animais
              AgroAlert.show(title: "Sucesso", message: "Animal excluído permanentemente.", isSuccess: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRelocateSelector(BuildContext context) async {
    final herds = await controller.getAvailableHerds();
    if (herds.isEmpty) {
      AgroAlert.show(
        title: "Aviso",
        message: "Não existem outros rebanhos desta mesma categoria para realocação.",
      );
      return;
    }

    var filteredHerds = <Map<String, dynamic>>[].obs;
    filteredHerds.value = herds;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const Text(
              "Realocar Animal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Selecione o novo rebanho (${controller.animal['category']})",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) {
                filteredHerds.value = herds
                    .where((h) => h['name'].toString().toLowerCase().contains(v.toLowerCase()))
                    .toList();
              },
              decoration: InputDecoration(
                hintText: "Pesquisar rebanho...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.isDarkMode ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: filteredHerds.length,
                itemBuilder: (context, index) {
                  final h = filteredHerds[index];
                  return ListTile(
                    leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                    title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(h['management_type'] ?? "Extensivo"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.relocateAnimal(h['id'], h['name']),
                  );
                },
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
