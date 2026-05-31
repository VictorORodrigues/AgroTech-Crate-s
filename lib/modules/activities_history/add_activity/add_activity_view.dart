import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'add_activity_controller.dart';

class AddActivityView extends StatelessWidget {
  final AddActivityController controller = Get.put(AddActivityController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Novo Registro de Manejo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Tipo de Atividade"),
            const SizedBox(height: 12),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedType.value.isEmpty ? null : controller.selectedType.value,
              hint: const Text("Selecione o tipo de manejo"),
              isExpanded: true,
              items: controller.types.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (v) => controller.selectedType.value = v ?? "",
              decoration: InputDecoration(
                filled: true,
                fillColor: context.theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              dropdownColor: context.theme.cardColor,
            )),
            
            const SizedBox(height: 24),
            _buildLabel("Selecionar Animal"),
            const SizedBox(height: 12),
            _buildAnimalSelector(context),

            const SizedBox(height: 24),
            _buildLabel("Data e Hora do Registro"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.manualDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) controller.manualDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            DateFormat('dd/MM/yyyy').format(controller.manualDate.value),
                            style: const TextStyle(fontSize: 14),
                          )),
                          const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: controller.manualTime.value,
                      );
                      if (picked != null) controller.manualTime.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            controller.manualTime.value.format(context),
                            style: const TextStyle(fontSize: 14),
                          )),
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Obx(() => _buildDynamicInputs(context)),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: controller.isLoading.value 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Salvar Registro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _buildHerdSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHerdSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
              controller.selectedHerd.value != null 
                ? controller.selectedHerd.value!['name']
                : "Tocar para buscar rebanho...",
              style: TextStyle(color: controller.selectedHerd.value == null ? Colors.grey : Colors.black87),
            )),
            const Icon(Icons.search, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showHerdSearch(BuildContext context) {
    var currentQuery = "".obs;

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
            const Text("Buscar Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => currentQuery.value = v,
              decoration: InputDecoration(
                hintText: "Nome do rebanho...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final results = controller.allHerds.where((h) => 
                  h['name'].toString().toLowerCase().contains(currentQuery.value.toLowerCase())
                ).toList();
                
                if (results.isEmpty) {
                  return const Center(child: Text("Nenhum rebanho encontrado.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final h = results[index];
                    return ListTile(
                      leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                      title: Text(h['name']),
                      subtitle: Text("${h['category']} | ${h['management_type']}"),
                      onTap: () {
                        controller.selectedHerd.value = h;
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAnimalSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
              controller.selectedAnimal.value != null 
                ? "${controller.selectedAnimal.value!['identifier']} (${controller.selectedAnimal.value!['herd_name']})"
                : "Tocar para buscar animal...",
              style: TextStyle(color: controller.selectedAnimal.value == null ? Colors.grey : Colors.black87),
            )),
            const Icon(Icons.search, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAnimalSearch(BuildContext context) {
    // Reset de filtros ao abrir busca
    controller.searchCategoryFilter.value = "Todos";
    controller.searchSexFilter.value = "Todos";
    
    var currentQuery = "".obs;

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
            const Text("Buscar Animal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => currentQuery.value = v,
              decoration: InputDecoration(
                hintText: "ID ou Apelido...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtros de Categoria e Sexo
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Categoria
                  ...["Todos", "Bovino", "Ovino", "Caprino"].map((cat) => Obx(() {
                    bool isSelected = controller.searchCategoryFilter.value == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        onSelected: (_) => controller.searchCategoryFilter.value = cat,
                        selectedColor: Colors.green[800],
                        checkmarkColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                      ),
                    );
                  })),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(height: 20, child: VerticalDivider(width: 1, color: Colors.grey)),
                  ),

                  // Sexo
                  ...["Todos", "Macho", "Fêmea"].map((sex) => Obx(() {
                    bool isSelected = controller.searchSexFilter.value == sex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(sex, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        onSelected: (_) => controller.searchSexFilter.value = sex,
                        selectedColor: Colors.blue[800],
                        checkmarkColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.blue[800]! : Colors.transparent)),
                      ),
                    );
                  })),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final results = controller.getFilteredAnimalsList(currentQuery.value);
                
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            controller.allAnimals.isEmpty 
                              ? "Ops! parece que voce ainda não possui animais cadastrados na sua base de dados"
                              : "Nenhum animal encontrado com esses filtros.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = results[index];
                    return _buildAnimalCard(context, a, () {
                      controller.selectedAnimal.value = a;
                      Get.back();
                    });
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

  Widget _buildDynamicInputs(BuildContext context) {
    final type = controller.selectedType.value;
    if (type.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (type == "Inseminação Artificial") ...[
          _buildLabel("Tipo de Inseminação"),
          const SizedBox(height: 12),
          Row(
            children: ["Inseminação Artificial", "Monta"].map((opt) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildRadioTile(
                  label: opt == "Inseminação Artificial" ? "IA" : "Monta",
                  value: opt,
                  groupValue: controller.inseminationType.value,
                  onChanged: (v) => controller.inseminationType.value = v!,
                ),
              ),
            )).toList(),
          ),
          if (controller.inseminationType.value == "Monta") ...[
            const SizedBox(height: 20),
            _buildLabel("Selecionar Reprodutor (Macho)"),
            const SizedBox(height: 12),
            _buildSireSelector(context),
          ] else ...[
            const SizedBox(height: 20),
            _buildLabel("Fertilidade do Sêmen"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller.value1Ctrl, 
                    "Ex: 0.85",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,1}')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll(',', '.');
                        return newValue.copyWith(text: text);
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.green),
                      onPressed: controller.incrementFertility,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                      onPressed: controller.decrementFertility,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
        if (type == "Vacinação") ...[
          _buildLabel("Nome da Vacina"),
          const SizedBox(height: 12),
          _buildTextField(controller.value1Ctrl, "Ex: Febre Aftosa, Brucelose..."),
        ],
        if (type == "Medicamento") ...[
          _buildLabel("Nome do Medicamento"),
          const SizedBox(height: 12),
          _buildTextField(controller.value1Ctrl, "Ex: Ivomec, Terramicina..."),
        ],
        if (type == "Produção de Leite") ...[
          _buildLabel("Quantidade de Leite"),
          const SizedBox(height: 12),
          _buildTextField(
            controller.value1Ctrl, 
            "Ex: 12.5", 
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: "Litros",
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text.replaceAll(',', '.');
                return newValue.copyWith(text: text);
              }),
            ],
          ),
        ],
        if (type == "Pesagem e Escore") ...[
          _buildLabel("Peso Atual"),
          const SizedBox(height: 12),
          _buildTextField(
            controller.value1Ctrl, 
            "Ex: 450", 
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: "kg",
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text.replaceAll(',', '.');
                return newValue.copyWith(text: text);
              }),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel("ECC Atual"),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.eccValue.value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.green[800],
                  inactiveTrackColor: Colors.green[100],
                  thumbColor: Colors.green[800],
                  overlayColor: Colors.green[800]!.withOpacity(0.2),
                  valueIndicatorColor: Colors.green[800],
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: controller.eccValue.value,
                  min: 1, max: 5, divisions: 8,
                  label: controller.eccValue.value.toStringAsFixed(1),
                  onChanged: (v) => controller.eccValue.value = v,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Muito Magra", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                    Text("Ideal", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    Text("Muito Gorda", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          )),
        ],
        if (type == "Diagnóstico de Toque") ...[
          _buildLabel("Resultado do Exame"),
          const SizedBox(height: 12),
          Row(
            children: ["Positivo", "Negativo"].map((r) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildRadioTile(
                  label: r,
                  value: r,
                  groupValue: controller.touchResult.value,
                  onChanged: (v) => controller.touchResult.value = v!,
                ),
              ),
            )).toList(),
          ),
        ],
        if (type == "Outro") ...[
          _buildLabel("Atividade (Obrigatório)"),
          const SizedBox(height: 12),
          _buildTextField(controller.value1Ctrl, "Ex: Conserto de cerca, Limpeza..."),
          const SizedBox(height: 20),
          _buildLabel("Selecionar Rebanho (Opcional)"),
          const SizedBox(height: 12),
          _buildHerdSelector(context),
        ],
        const SizedBox(height: 16),
        _buildLabel("Observações / Detalhes"),
        const SizedBox(height: 12),
        _buildTextField(controller.descriptionCtrl, "Descreva aqui...", maxLines: 3),
      ],
    );
  }

  Widget _buildSireSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSireSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
              controller.selectedReprodutor.value != null 
                ? "${controller.selectedReprodutor.value!['identifier']} (Fert: ${controller.selectedReprodutor.value!['semen_fertility'] ?? 1.0})"
                : "Buscar reprodutor macho...",
              style: TextStyle(color: controller.selectedReprodutor.value == null ? Colors.grey : Colors.black87),
            )),
            const Icon(Icons.search, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSireSearch(BuildContext context) {
    final list = controller.potentialSires;
    var searchList = <Map<String, dynamic>>[].obs;
    searchList.value = list;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const Text("Buscar Reprodutor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) {
                final q = v.toLowerCase();
                searchList.value = list.where((a) => 
                  a['identifier'].toString().toLowerCase().contains(q) ||
                  (a['name'] ?? "").toString().toLowerCase().contains(q) ||
                  (a['breed_name'] ?? "").toString().toLowerCase().contains(q) ||
                  (a['herd_name'] ?? "").toString().toLowerCase().contains(q)
                ).toList();
              },
              decoration: InputDecoration(
                hintText: "ID do Macho...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (searchList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            "Ops! parece que voce ainda não tem animais casdatrados na sua base de dados",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: searchList.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: const Icon(Icons.help_outline, color: Colors.grey),
                        ),
                        title: const Text("Reprodutor Desconhecido", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Usar sem rastreabilidade do pai"),
                        onTap: () {
                          controller.selectedReprodutor.value = {
                            'id': -1,
                            'identifier': 'Desconhecido',
                            'semen_fertility': 1.0
                          };
                          Get.back();
                        },
                      );
                    }
                    final a = searchList[index - 1];
                    return _buildAnimalCard(context, a, () {
                      controller.selectedReprodutor.value = a;
                      Get.back();
                    });
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType? keyboardType, int maxLines = 1, List<TextInputFormatter>? inputFormatters, String? suffixText}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixText: suffixText,
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, Map<String, dynamic> animal, VoidCallback onTap) {
    final isFemale = animal['sex'] == 'Fêmea';
    final category = animal['category'] ?? "Bovino";
    final String status = animal['reproductive_status']?.toString() ?? "Vazia / Apta";
    final String aptitude = animal['aptitude']?.toString() ?? "";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Foto ou Ícone (Redondo com Opacidade)
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: animal['photo_path'] != null && animal['photo_path'].toString().isNotEmpty
                      ? DecorationImage(image: FileImage(File(animal['photo_path'])), fit: BoxFit.cover)
                      : DecorationImage(
                          image: AssetImage(
                            category == 'Bovino' ? 'assets/images/bovino_default.png' :
                            category == 'Ovino' ? 'assets/images/ovino_default.png' :
                            'assets/images/caprino_default.png'
                          ),
                          fit: BoxFit.cover,
                          // Opacidade removida conforme solicitado para o buscador
                        ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      isFemale ? Icons.female : Icons.male,
                      size: 14,
                      color: isFemale ? Colors.pink[300] : Colors.blue[400],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal['identifier'],
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (animal['name'] != null && animal['name'].toString().isNotEmpty)
                    Text(
                      animal['name'],
                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    "${animal['herd_name']} | ${animal['breed']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags Dinâmicas
                  if (isFemale) 
                    _buildStatusTag(status)
                  else if (aptitude.isNotEmpty)
                    _buildAptitudeTag(aptitude),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: () {
          if (status == "Prenhe") return Colors.pink[50];
          if (status == "Em Lactação") return Colors.blue[50];
          if (status == "Inseminada") return Colors.green[50];
          return Colors.grey[100];
        }(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: () {
            if (status == "Prenhe") return Colors.pink[200]!;
            if (status == "Em Lactação") return Colors.blue[200]!;
            if (status == "Inseminada") return Colors.green[200]!;
            return Colors.grey[300]!;
          }(),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          color: () {
            if (status == "Prenhe") return Colors.pink[800];
            if (status == "Em Lactação") return Colors.blue[800];
            if (status == "Inseminada") return Colors.green[800];
            return Colors.black54;
          }(),
        ),
      ),
    );
  }

  Widget _buildAptitudeTag(String aptitude) {
    final isRustico = aptitude == "Rústico";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRustico ? Colors.orange[50] : Colors.indigo[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRustico ? Colors.orange[200]! : Colors.indigo[200]!,
          width: 1,
        ),
      ),
      child: Text(
        aptitude,
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          color: isRustico ? Colors.orange[800] : Colors.indigo[800],
        ),
      ),
    );
  }

  Widget _buildRadioTile({required String label, required String value, required String groupValue, required Function(String?) onChanged, bool isFullWidth = false}) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? Colors.green[800] : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}
