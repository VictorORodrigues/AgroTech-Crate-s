import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'add_animal_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddAnimalView extends StatelessWidget {
  final AddAnimalController controller = Get.put(AddAnimalController());

  @override
  Widget build(BuildContext context) {
    final String category = controller.herd['category'] ?? "Animal";
    
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        title: Text(
          controller.isEdition ? "Editar $category" : "Adicionar $category",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Seção de Foto
            Center(
              child: Stack(
                children: [
                  Obx(() => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipOval(
                      child: controller.photoPath.value.isNotEmpty
                          ? Image.file(File(controller.photoPath.value), fit: BoxFit.cover)
                          : _buildPlaceholderIcon(),
                    ),
                  )),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showPhotoOptions(),
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

            _buildSection(
              title: "Dados Principais",
              icon: Icons.info_outline,
              children: [
                _buildTextField(controller.idCtrl, "ID ou Brinco", errorText: controller.idError),
                const SizedBox(height: 16),
                _buildTextField(controller.nomeAnimalCtrl, "Apelido (Opcional)"),
                const SizedBox(height: 16),
                _buildTextField(controller.racaNomeCtrl, "Nome da Raça (Ex: Nelore, Boer...)"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller.idadeCtrl, "Idade (meses)", keyboardType: TextInputType.number, errorText: controller.idadeError)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller.pesoCtrl, "Peso (kg)", keyboardType: TextInputType.number, errorText: controller.pesoError)),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() => _buildDropdown("Sexo", controller.sexoSelecionado.value, ["Macho", "Fêmea"], (val) {
                  controller.sexoSelecionado.value = val ?? "";
                }, errorText: controller.sexoError.value)),
                const SizedBox(height: 16),
                Obx(() => _buildDropdown("Raça", controller.racaSelecionada.value, controller.racas, (val) {
                  controller.racaSelecionada.value = val ?? "";
                }, errorText: controller.racaError.value)),
                const SizedBox(height: 20),
                const Text("Escore de Condição Corporal (ECC)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Obx(() => Column(
                  children: [
                    Slider(
                      value: controller.eccValue.value,
                      min: 1, max: 5, divisions: 4,
                      activeColor: Colors.green[800],
                      onChanged: (v) => controller.eccValue.value = v,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("1 - Magra", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("5 - Obesa", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: "Genealogia e Linhagem",
              icon: Icons.account_tree_outlined,
              children: [
                _buildTextField(controller.linhagemCtrl, "Linhagem / Família"),
                Obx(() => controller.existingLineages.isNotEmpty 
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: controller.existingLineages.map((l) => ActionChip(
                          label: Text(l, style: const TextStyle(fontSize: 11)),
                          onPressed: () => controller.linhagemCtrl.text = l,
                          backgroundColor: Colors.green[50],
                        )).toList(),
                      ),
                    ) 
                  : const SizedBox.shrink()),
                const SizedBox(height: 16),
                _buildSearchableParentSelector("Pai", controller.idPaiSelecionado, controller.potentialFathers),
                const SizedBox(height: 16),
                _buildSearchableParentSelector("Mãe", controller.idMaeSelecionada, controller.potentialMothers),
              ],
            ),
            
            Obx(() {
              if (controller.sexoSelecionado.value == "Fêmea") {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _buildSection(
                    title: "Dados Reprodutivos",
                    icon: Icons.favorite_border,
                    children: [
                      _buildDropdown("Paridade", controller.paridadeSelecionada.value, controller.paridades, (val) => controller.setParidade(val)),
                      
                      if (controller.paridadeSelecionada.value != "Nulípara" && controller.paridadeSelecionada.value.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDropdown("Dias Pós-Parto", controller.dppSelecionado.value, controller.dppOpcoes, (val) => controller.dppSelecionado.value = val ?? ""),
                        const SizedBox(height: 16),
                        _buildDropdown("Status Atual", controller.statusAtualSelecionado.value, controller.statusOpcoes, (val) => controller.statusAtualSelecionado.value = val ?? ""),
                      ],
                    ],
                  ),
                );
              } else if (controller.sexoSelecionado.value == "Macho") {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _buildSection(
                    title: "Dados de Reprodutor",
                    icon: Icons.bolt,
                    children: [
                      _buildDropdown("Aptidão", controller.aptidaoSelecionada.value, controller.aptidoes, (v) => controller.aptidaoSelecionada.value = v!),
                      const SizedBox(height: 16),
                      _buildTextField(controller.fertilidadeSemenCtrl, "Fertilidade do Sêmen (0.0 a 1.0)", keyboardType: TextInputType.number, errorText: controller.semenFertilityError),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  controller.isEdition ? "Salvar Alterações" : "Adicionar Animal",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    final context = Get.context!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
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
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSearchableParentSelector(String label, RxString selectedValue, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSearchBottomSheet(label, selectedValue, items),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(selectedValue.value, style: const TextStyle(fontSize: 14))),
                const Icon(Icons.search, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchBottomSheet(String label, RxString selectedValue, List<Map<String, dynamic>> items) {
    var filteredItems = <Map<String, dynamic>>[].obs;
    filteredItems.value = items;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Text("Selecionar $label", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) {
                filteredItems.value = items.where((i) => i['identifier'].toString().toLowerCase().contains(v.toLowerCase())).toList();
              },
              decoration: InputDecoration(
                hintText: "Pesquisar por ID ou Brinco...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: filteredItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text("Desconhecido"),
                      onTap: () {
                        selectedValue.value = "Desconhecido";
                        Get.back();
                      },
                    );
                  }
                  final item = filteredItems[index - 1];
                  return ListTile(
                    title: Text(item['identifier'].toString()),
                    onTap: () {
                      selectedValue.value = item['identifier'].toString();
                      Get.back();
                    },
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

  Widget _buildTextField(TextEditingController ctrl, String label, {TextInputType? keyboardType, Rxn<String>? errorText}) {
    final context = Get.context!;
    final decoration = InputDecoration(
      labelText: label,
      filled: true,
      fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    if (errorText == null) {
      return TextField(controller: ctrl, keyboardType: keyboardType, decoration: decoration);
    }

    return Obx(() => TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: decoration.copyWith(
        errorText: errorText.value,
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      ),
    ));
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, {String? errorText}) {
    final context = Get.context!;
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      hint: Text(label),
      isExpanded: true,
      decoration: InputDecoration(
        errorText: errorText,
        filled: true,
        fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPlaceholderIcon() {
    final String category = controller.herd['category'] ?? "Bovino";
    if (category == 'Bovino') return const Center(child: FaIcon(FontAwesomeIcons.cow, size: 40, color: Colors.grey));
    if (category == 'Ovino') return const Center(child: Icon(Icons.pets, size: 40, color: Colors.grey));
    return const Center(child: Icon(Icons.agriculture, size: 40, color: Colors.grey));
  }

  void _showPhotoOptions() {
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
          ],
        ),
      ),
    );
  }
}
