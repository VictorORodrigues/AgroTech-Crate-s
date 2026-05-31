import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'activity_details_controller.dart';

class ActivityDetailsView extends StatelessWidget {
  final ActivityDetailsController controller = Get.put(ActivityDetailsController());

  @override
  Widget build(BuildContext context) {
    final e = controller.event;
    
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Detalhes do Manejo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: Obx(() => Icon(controller.isEditing.value ? Icons.close : Icons.edit, color: Colors.white)),
            onPressed: () => controller.toggleEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, e),
            const SizedBox(height: 24),
            Obx(() => controller.isEditing.value 
              ? const Text("Editando Informações", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
              : const Text("Editar Observações", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Adicionar observações...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
            const SizedBox(height: 32),
            Obx(() => (controller.isEditing.value || controller.descriptionCtrl.text != (e['description'] ?? ""))
              ? SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.updateActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Salvar Alterações", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              : const SizedBox.shrink()
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> e) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(e['date'])),
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Text(e['category'] ?? "Animal", style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(e['type'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Obx(() => _buildStructuredData(context, e)),
          const Divider(height: 32),
          const Text("Animal Envolvido:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.animalData.value == null) return const LinearProgressIndicator();
            return _buildAnimalCard(context, controller.animalData.value!);
          }),
          const Divider(height: 32),
          Text("Rebanho: ${e['herd_name']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStructuredData(BuildContext context, Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? "";
    final isEditing = controller.isEditing.value;
    final List<Widget> fields = [];

    if (type == "Pesagem e Escore") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Peso Anterior", "${e['text_value_1'] ?? '0.0'} kg"));
        fields.add(_buildDetailRow("Peso Atual", "${e['value_1'] ?? '0.0'} kg"));
        fields.add(const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)));
        fields.add(_buildDetailRow("ECC Anterior", "${e['text_value_2'] ?? '3.0'}"));
        fields.add(_buildDetailRow("ECC Atual", "${e['value_2'] ?? '3.0'}"));
      } else {
        fields.add(_buildEditableDetailRow("Peso Atual (kg)", controller.value1Ctrl, keyboardType: TextInputType.number));
        fields.add(const SizedBox(height: 16));
        fields.add(const Text("ECC Atual", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)));
        fields.add(Slider(
          value: controller.eccValue.value,
          min: 1, max: 5, divisions: 8,
          label: controller.eccValue.value.toStringAsFixed(1),
          onChanged: (v) => controller.eccValue.value = v,
          activeColor: Colors.green[800],
        ));
      }
    } else if (type == "Produção de Leite") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Quantidade", "${e['value_1'] ?? '0'} Litros"));
      } else {
        fields.add(_buildEditableDetailRow("Quantidade (Litros)", controller.value1Ctrl, keyboardType: TextInputType.number));
      }
    } else if (type == "Vacinação") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Nome da Vacina", "${e['text_value_1'] ?? 'Não informado'}"));
      } else {
        fields.add(_buildEditableDetailRow("Nome da Vacina", controller.value1Ctrl));
      }
    } else if (type == "Medicamento") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Nome do Medicamento", "${e['text_value_1'] ?? 'Não informado'}"));
      } else {
        fields.add(_buildEditableDetailRow("Nome do Medicamento", controller.value1Ctrl));
      }
    } else if (type == "Diagnóstico de Toque") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Resultado", "${e['text_value_1'] ?? 'Não informado'}"));
      } else {
        fields.add(const Text("Resultado", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)));
        fields.add(Row(
          children: ["Positivo", "Negativo"].map((r) => Expanded(
            child: RadioListTile<String>(
              title: Text(r, style: const TextStyle(fontSize: 12)),
              value: r,
              groupValue: controller.touchResult.value,
              onChanged: (v) => controller.touchResult.value = v!,
              contentPadding: EdgeInsets.zero,
            ),
          )).toList(),
        ));
      }
    } else if (type == "Inseminação Artificial") {
      fields.add(_buildDetailRow("Método", "${e['text_value_1'] ?? 'IA'}"));
      if (e['text_value_1'] == "Monta") {
        fields.add(_buildDetailRow("Identificador do Reprodutor", "${e['text_value_2']?.split('#').first ?? 'N/A'}"));
        fields.add(_buildDetailRow("Fertilidade Estimada", "${((e['value_1'] ?? 1.0) * 100).toInt()}%"));
      }
    }

    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields,
        Obx(() {
          if (controller.breederData.value != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text("Reprodutor (Pai Provável):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildAnimalCard(context, controller.breederData.value!),
              ],
            );
          }
          
          if (type == "Inseminação Artificial" && e['text_value_1'] == "Monta") {
             return Padding(
               padding: const EdgeInsets.only(top: 16),
               child: Text("Reprodutor: ${e['text_value_2']?.split('#').first ?? 'N/A'} (Card não disponível)", 
                 style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
             );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildEditableDetailRow(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, Map<String, dynamic> animal) {
    final category = animal['category'] ?? "Bovino";
    
    return GestureDetector(
      onTap: () => Get.toNamed('/perfil-animal', arguments: animal),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                image: animal['photo_path'] != null && animal['photo_path'].toString().isNotEmpty
                  ? DecorationImage(image: FileImage(File(animal['photo_path'])), fit: BoxFit.cover)
                  : DecorationImage(
                      image: AssetImage(
                        category == 'Bovino' ? 'assets/images/bovino_default.png' :
                        category == 'Ovino' ? 'assets/images/ovino_default.png' :
                        'assets/images/caprino_default.png'
                      ),
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal['identifier'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (animal['name'] != null && animal['name'].toString().isNotEmpty)
                    Text(
                      animal['name'],
                      style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    "${animal['herd_name']} | ${animal['breed']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Registro"),
        content: const Text("Tem certeza que deseja remover este registro de manejo? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteActivity();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
