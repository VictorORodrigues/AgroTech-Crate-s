import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'add_animal_controller.dart';
import 'package:image_picker/image_picker.dart';

class AddAnimalView extends StatelessWidget {
  final AddAnimalController controller = Get.put(AddAnimalController());

  @override
  Widget build(BuildContext context) {
    final category = controller.herd['category'] ?? 'Animal';
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (controller.hasChanges()) {
          final shouldPop = await _showExitConfirmation(context);
          if (shouldPop) Get.back();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
              child: IconButton(
                icon: Icon(Icons.chevron_left, color: Get.isDarkMode ? Colors.white : Colors.black87),
                onPressed: () async {
                  if (controller.hasChanges()) {
                    final shouldPop = await _showExitConfirmation(context);
                    if (shouldPop) Get.back();
                  } else {
                    Get.back();
                  }
                },
              ),
            ),
          ),
          title: Text(
            controller.isEdition ? "Editar $category" : "Adicionar $category",
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black87, 
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto do Animal
              Center(
                child: Stack(
                  children: [
                    Obx(() => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                          decoration: BoxDecoration(color: Colors.green[800], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle("IDENTIFICAÇÃO", Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(controller.idCtrl, "ID ou Brinco (Obrigatório)", icon: Icons.tag, errorText: controller.idError),
              const SizedBox(height: 16),
              _buildTextField(controller.nomeAnimalCtrl, "Apelido do Animal (Opcional)", icon: Icons.drive_file_rename_outline),
              const SizedBox(height: 32),
              
              _buildSectionTitle("DADOS BIOLÓGICOS", Icons.analytics_outlined),
              const SizedBox(height: 16),
              _buildLabel("Data de Nascimento (Cálculo Automático)"),
              const SizedBox(height: 8),
              _buildDatePicker(context),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.pesoCtrl, "Peso (kg)", icon: Icons.scale, errorText: controller.pesoError, inputFormatters: [controller.weightMask], keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller.idadeCtrl, "Idade (Meses)", icon: Icons.calendar_month, errorText: controller.idadeError, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel("Sexo"),
              const SizedBox(height: 12),
              Obx(() => Row(
                children: [
                  Expanded(child: _buildRadioTile(label: "Macho", value: "Macho", groupValue: controller.sexoSelecionado.value, onChanged: (v) => controller.sexoSelecionado.value = v!)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRadioTile(label: "Fêmea", value: "Fêmea", groupValue: controller.sexoSelecionado.value, onChanged: (v) => controller.sexoSelecionado.value = v!)),
                ],
              )),

              const SizedBox(height: 32),
              _buildSectionTitle("RAÇA E GENÉTICA", Icons.auto_awesome),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildLabel("Categoria IA"),
                  IconButton(onPressed: () => _showBreedIAInfo(), icon: const Icon(Icons.help_outline, size: 16, color: Colors.grey)),
                ],
              ),
              Obx(() => _buildDropdown(
                "Selecione a raça", 
                controller.racaSelecionada.value, 
                controller.racas, 
                (v) => controller.racaSelecionada.value = v!,
                errorText: controller.racaError.value
              )),
              const SizedBox(height: 24),
              _buildLabel("Aptidão do Animal"),
              const SizedBox(height: 12),
              Obx(() => _buildDropdown(
                "Selecione a aptidão", 
                controller.aptidaoSelecionada.value, 
                controller.aptidoes, 
                (v) => controller.aptidaoSelecionada.value = v!,
                errorText: controller.aptidaoError.value
              )),
              const SizedBox(height: 24),
              _buildTextField(controller.racaNomeCtrl, "Nome da Raça (Ex: Nelore, Boer...)", icon: Icons.pets),
              const SizedBox(height: 16),
              _buildTextField(controller.linhagemCtrl, "Linhagem Genética (Ex: PI, PO...)", icon: Icons.account_tree_outlined),

              const SizedBox(height: 32),
              _buildSectionTitle("FAMÍLIA", Icons.family_restroom_outlined),
              const SizedBox(height: 16),
              _buildParentSelector("Pai", controller.idPaiSelecionado, controller.potentialFathers),
              const SizedBox(height: 16),
              _buildParentSelector("Mãe", controller.idMaeSelecionada, controller.potentialMothers),

              Obx(() {
                if (controller.sexoSelecionado.value == "Fêmea") {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildSectionTitle("HISTÓRICO REPRODUTIVO", Icons.child_care),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildLabel("Paridade"),
                          IconButton(onPressed: () => _showParityInfo(), icon: const Icon(Icons.help_outline, size: 16, color: Colors.grey)),
                        ],
                      ),
                      _buildDropdown("Selecione a paridade", controller.paridadeSelecionada.value, controller.paridades, (v) => controller.setParidade(v)),
                      const SizedBox(height: 24),
                      _buildLabel("Status Atual"),
                      const SizedBox(height: 12),
                      _buildDropdown("Status reprodutivo", controller.statusAtualSelecionado.value, controller.statusOpcoes, (v) => controller.statusAtualSelecionado.value = v!),
                    ],
                  );
                }
                if (controller.sexoSelecionado.value == "Macho") {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildSectionTitle("QUALIDADE DO REPRODUTOR", Icons.bolt),
                      const SizedBox(height: 16),
                      _buildLabel("Fertilidade do Sêmen (0.0 a 1.0)"),
                      const SizedBox(height: 12),
                      _buildFertilityInput(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 48),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : () => controller.salvar(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: controller.isSaving.value 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("SALVAR ANIMAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[800]),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? label}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.green[800], size: 20) : null,
      filled: true,
      fillColor: Get.isDarkMode ? Colors.white10 : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), 
        borderSide: BorderSide(color: Colors.grey[300]!)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), 
        borderSide: BorderSide(color: Colors.green[800]!, width: 2)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), 
        borderSide: const BorderSide(color: Colors.redAccent)
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), 
        borderSide: const BorderSide(color: Colors.redAccent, width: 2)
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1, Rxn<String>? errorText, List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType, Function(String)? onChanged, IconData? icon}) {
    if (errorText == null) {
      return TextField(
        controller: ctrl,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: _inputDecoration(icon: icon, label: label),
      );
    }
    return Obx(() => TextField(
      controller: ctrl,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _inputDecoration(icon: icon, label: label).copyWith(
        errorText: errorText.value,
      ),
    ));
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, {String? errorText}) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      hint: Text(label),
      isExpanded: true,
      decoration: _inputDecoration(label: label).copyWith(errorText: errorText),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildRadioTile({required String label, required String value, required String groupValue, required Function(String?) onChanged}) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[200]!, width: 2),
          boxShadow: [
            if (isSelected) BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.green[800] : Colors.grey[700], 
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500
            )
          )
        ),
      ),
    );
  }

  Widget _buildFertilityInput() {
    return Row(
      children: [
        Expanded(child: _buildTextField(controller.fertilidadeSemenCtrl, "Fertilidade (Ex: 0.8)", icon: Icons.bolt, inputFormatters: [controller.semenMask])),
        const SizedBox(width: 12),
        Column(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: controller.incrementFertility),
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.green), onPressed: controller.decrementFertility),
          ],
        )
      ],
    );
  }

  Widget _buildParentSelector(String label, RxString selectedValue, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSearchBottomSheet(label, selectedValue, items),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.grey[200]!, width: 1.5)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(selectedValue.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
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
      Material(
        color: Colors.transparent,
        child: Container(
          height: Get.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            children: [
              Text("Selecionar $label", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                onChanged: (v) => filteredItems.value = items.where((i) => i['identifier'].toString().toLowerCase().contains(v.toLowerCase())).toList(),
                decoration: InputDecoration(
                  hintText: "Pesquisar por ID ou Brinco...", 
                  prefixIcon: const Icon(Icons.search), 
                  filled: true,
                  fillColor: Get.isDarkMode ? Colors.white10 : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  if (filteredItems.isEmpty && items.isNotEmpty) return const Center(child: Text("Nenhum animal encontrado"));
                  return ListView.separated(
                    itemCount: filteredItems.length + 1,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      if (index == 0) return ListTile(title: const Text("Desconhecido"), onTap: () { selectedValue.value = "Desconhecido"; Get.back(); });
                      final item = filteredItems[index - 1];
                      return ListTile(
                        title: Text(item['identifier'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () { selectedValue.value = item['identifier'].toString(); Get.back(); }
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: controller.birthDate.value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.birthDate.value = picked;
          // Atualiza idade automaticamente
          final now = DateTime.now();
          int months = (now.year - picked.year) * 12 + now.month - picked.month;
          if (months < 0) months = 0;
          controller.idadeCtrl.text = months.toString();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
              controller.birthDate.value != null 
                ? DateFormat('dd/MM/yyyy').format(controller.birthDate.value!)
                : "Selecionar data",
              style: TextStyle(
                color: controller.birthDate.value == null ? Colors.grey : Colors.black87,
                fontWeight: FontWeight.w500
              ),
            )),
            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    final String category = controller.herd['category'] ?? "Bovino";
    String assetPath = 'assets/images/bovino_default.png';
    if (category == 'Ovino') assetPath = 'assets/images/ovino_default.png';
    if (category == 'Caprino') assetPath = 'assets/images/caprino_default.png';
    return Opacity(
      opacity: 0.5,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }

  void _showBreedIAInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Guia de Categorias IA", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("As categorias ajudam nossa IA a calcular o estresse térmico e a heterose.\n\n• Nativa Pura: Máxima resiliência.\n• Mestiço: Equilíbrio produtivo.\n• Exótica: Alta performance, alta sensibilidade."),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  void _showParityInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Guia de Paridade", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("• Nulípara: Nunca pariu.\n• Primípara: Primeiro parto.\n• Multípara: 2 ou mais partos."),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  void _showPhotoOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Foto do Animal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue), 
              title: const Text("Tirar Foto", style: TextStyle(fontWeight: FontWeight.bold)), 
              onTap: () { Get.back(); controller.pickImage(ImageSource.camera); }
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green), 
              title: const Text("Escolher da Galeria", style: TextStyle(fontWeight: FontWeight.bold)), 
              onTap: () { Get.back(); controller.pickImage(ImageSource.gallery); }
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sair sem salvar?"),
        content: const Text("Você fez alterações que não foram salvas. Deseja realmente sair e descartar as mudanças?"),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("DESCARTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
