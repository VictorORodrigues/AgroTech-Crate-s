import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'detalhes_rebanho_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';

class DetalhesRebanhoView extends StatelessWidget {
  final DetalhesRebanhoController controller = Get.put(DetalhesRebanhoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Obx(() => Text(controller.rebanho['name'] ?? 'Detalhes', style: const TextStyle(color: Colors.white))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Animais'),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: controller.tabController,
            children: [
              _buildGeralTab(context),
              _buildAnimaisTab(context),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedTabIndex.value == 1 
        ? FloatingActionButton(
            onPressed: () => _showAddAnimalPage(),
            backgroundColor: Colors.green[800],
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink()
      ),
    );
  }

  Widget _buildGeralTab(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard(
            title: "Informações do Rebanho",
            onEdit: () => _showEditNomeDialog(context),
            onDelete: () => _showConfirmDeleteHerdDialog(),
            content: [
              _buildInfoRow("Categoria", controller.rebanho['category']),
              _buildInfoRow("Tipo de Manejo", controller.rebanho['management_type'] ?? "Extensivo"),
              _buildInfoRow("Total de Animais", controller.rebanho['animal_count'].toString()),
              _buildInfoRow("Fêmeas", controller.totalFemeas.value.toString()),
              _buildInfoRow("Machos", controller.totalMachos.value.toString()),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            title: "Índices Reprodutivos",
            content: [
              _buildInfoRow("Taxa de Prenhez", controller.taxaPrenhez.value, isHighlight: true),
              _buildInfoRow("Fêmeas Aptas (Vazias)", "${controller.femeasAptas.value} Prontas para I.A.", isHighlight: true),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildAnimaisTab(BuildContext context) {
    return Obx(() {
      final String category = controller.rebanho['category'] ?? "Bovino";
      if (controller.animais.isEmpty) {
        return _buildEmptyAnimaisState(context, category);
      }

      dynamic animalIcon;
      if (category == 'Bovino') {
        animalIcon = FontAwesomeIcons.cow;
      } else if (category == 'Ovino') {
        animalIcon = Icons.pets;
      } else {
        animalIcon = Icons.agriculture;
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.animais.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final animal = controller.animais[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[50],
                backgroundImage: animal['photo_path'] != null && animal['photo_path'].isNotEmpty
                    ? FileImage(File(animal['photo_path']))
                    : null,
                child: (animal['photo_path'] == null || animal['photo_path'].isEmpty)
                    ? (animalIcon is IconData
                        ? Icon(animalIcon, color: Colors.green[800], size: 18)
                        : FaIcon(animalIcon, color: Colors.green[800], size: 18))
                    : null,
              ),
              title: Text(animal['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${animal['sex']} | ${(animal['breed_name'] != null && animal['breed_name'].toString().isNotEmpty) ? animal['breed_name'] : animal['breed']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _showConfirmDeleteDialog(animal),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              onTap: () => Get.toNamed('/perfil-animal', arguments: animal),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyAnimaisState(BuildContext context, String category) {
    dynamic animalIcon;
    if (category == 'Bovino') {
      animalIcon = FontAwesomeIcons.cow;
    } else if (category == 'Ovino') {
      animalIcon = Icons.pets;
    } else {
      animalIcon = Icons.agriculture;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: animalIcon is IconData 
                ? Icon(animalIcon, size: 60, color: Colors.green[200])
                : FaIcon(animalIcon, size: 60, color: Colors.green[200]),
            ),
            const SizedBox(height: 24),
            const Text('Nenhum animal cadastrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Ops! Parece que você ainda não possui animais cadastrados neste rebanho.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => _showAddAnimalPage(),
              icon: const Icon(Icons.add, color: Colors.grey),
              label: Text('Cadastrar $category no Rebanho'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, VoidCallback? onEdit, VoidCallback? onDelete, required List<Widget> content}) {
    return Container(
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (onEdit != null) IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.green), onPressed: onEdit),
                  if (onDelete != null) IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
                ],
              ),
            ],
          ),
          const Divider(),
          ...content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[800] : Colors.black,
          )),
        ],
      ),
    );
  }

  void _showEditNomeDialog(BuildContext context) {
    final textController = TextEditingController(text: controller.rebanho['name']);
    Get.dialog(
      AlertDialog(
        title: const Text("Editar Nome do Rebanho"),
        content: TextField(controller: textController, decoration: const InputDecoration(labelText: "Nome")),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              if (textController.text.trim() != controller.rebanho['name'] && 
                  await DatabaseHelper.instance.herdNameExists(textController.text.trim())) {
                AgroAlert.show(title: "Erro", message: "Este nome de rebanho já existe", isError: true);
                return;
              }
              controller.editarNomeRebanho(textController.text.trim());
              Get.back();
            }, 
            child: const Text("Salvar")
          ),
        ],
      ),
    );
  }

  void _showAddAnimalPage() {
    Get.toNamed('/add-animal', arguments: {
      'herd': controller.rebanho.value,
      'isEdition': false,
    });
  }

  void _showConfirmDeleteDialog(Map<String, dynamic> animal) {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Animal"),
        content: Text("Tem certeza que deseja excluir o animal '${animal['identifier']}'? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.excluirAnimal(animal['id']);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteHerdDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Rebanho"),
        content: Text("Tem certeza que deseja excluir o rebanho '${controller.rebanho['name']}' e TODOS os animais vinculados a ele? Esta ação é irreversível."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Fecha o modal
              controller.excluirRebanho();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir Tudo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
