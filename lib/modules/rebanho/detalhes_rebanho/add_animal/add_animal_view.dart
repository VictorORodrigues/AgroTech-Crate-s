import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'add_animal_controller.dart';
import '../../perfil_animal/widgets/animal_qrcode_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddAnimalView extends StatelessWidget {
  final AddAnimalController controller = Get.put(AddAnimalController());

  @override
  Widget build(BuildContext context) {
    final String category = controller.herd['category'] ?? "Animal";
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (controller.hasChanges()) {
          final shouldPop = await _showExitConfirmation(context);
          if (shouldPop) {
            Get.back();
          }
        } else {
          Get.back();
        }
      },
      child: Scaffold(
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
                      _buildTextField(controller.idCtrl, "ID ou Brinco", errorText: controller.idError, maxLength: 35),
                      const SizedBox(height: 16),
                      _buildTextField(controller.nomeAnimalCtrl, "Apelido (Opcional)", maxLength: 35),
                      const SizedBox(height: 16),
                      _buildTextField(controller.racaNomeCtrl, "Nome da Raça (Ex: Nelore, Boer...)", maxLength: 35),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller.idadeCtrl, "Idade (meses)", keyboardType: TextInputType.number, errorText: controller.idadeError)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(
                            controller.pesoCtrl, 
                            "Peso", 
                            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                            errorText: controller.pesoError,
                            suffixText: "kg",
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final text = newValue.text.replaceAll(',', '.');
                                return newValue.copyWith(text: text);
                              }),
                            ],
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Sexo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        children: ["Macho", "Fêmea"].map((s) {
                          final isSelected = controller.sexoSelecionado.value == s;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: s == "Macho" ? 8 : 0),
                              child: GestureDetector(
                                onTap: () => controller.sexoSelecionado.value = s,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? (s == "Macho" ? Colors.blue[50] : Colors.pink[50]) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? (s == "Macho" ? Colors.blue : Colors.pink) : (controller.sexoError.value != null ? Colors.red : Colors.grey[300]!),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        s == "Macho" ? Icons.male : Icons.female,
                                        size: 18,
                                        color: isSelected ? (s == "Macho" ? Colors.blue : Colors.pink) : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        s,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? (s == "Macho" ? Colors.blue[800] : Colors.pink[800]) : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                      Obx(() => controller.sexoError.value != null 
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(controller.sexoError.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          )
                        : const SizedBox.shrink()),
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel("Categoria (IA)"),
                          TextButton.icon(
                            onPressed: () => _showBreedIAInfo(),
                            icon: Icon(Icons.info_outline, size: 14, color: Colors.green[800]),
                            label: Text("Guia de Raças", 
                              style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() => _buildDropdown(
                        "Selecione a Categoria", 
                        controller.racaSelecionada.value, 
                        controller.racas, 
                        (v) => controller.racaSelecionada.value = v!,
                        errorText: controller.racaError.value,
                      )),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Condição Corporal (ECC)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabel("Paridade"),
                                TextButton.icon(
                                  onPressed: () => _showParityInfo(),
                                  icon: Icon(Icons.info_outline, size: 14, color: Colors.green[800]),
                                  label: Text("Guia Técnico", 
                                    style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() => Row(
                              children: controller.paridades.map((p) => Expanded(
                                child: _buildRadioTile(
                                  label: p,
                                  value: p,
                                  groupValue: controller.paridadeSelecionada.value,
                                  onChanged: (val) => controller.setParidade(val),
                                ),
                              )).toList(),
                            )),
                            Obx(() => controller.paridadeError.value != null 
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Text(controller.paridadeError.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                )
                              : const SizedBox.shrink()),
                            
                            if (controller.paridadeSelecionada.value.isNotEmpty && controller.paridadeSelecionada.value != "Nulípara") ...[
                              const SizedBox(height: 24),
                              _buildLabel("Dias Pós-Parto (DPP)"),
                              const SizedBox(height: 12),
                              Obx(() => Column(
                                children: controller.dppOpcoes.map((dpp) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildRadioTile(
                                    label: dpp,
                                    value: dpp,
                                    groupValue: controller.dppSelecionado.value,
                                    onChanged: (val) => controller.dppSelecionado.value = val ?? "",
                                    isFullWidth: true,
                                  ),
                                )).toList(),
                              )),
                            ],

                            const SizedBox(height: 24),
                            _buildLabel("Status Reprodutivo Atual"),
                            const SizedBox(height: 12),
                            Obx(() => Column(
                              children: controller.statusOpcoes.where((st) {
                                // Se for Nulípara, mostra apenas Vazia/Apta e Inseminada
                                if (controller.paridadeSelecionada.value == "Nulípara") {
                                  return st == "Vazia / Apta" || st == "Inseminada";
                                }
                                return true;
                              }).map((st) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildRadioTile(
                                    label: st,
                                    value: st,
                                    groupValue: controller.statusAtualSelecionado.value,
                                    onChanged: (val) => controller.statusAtualSelecionado.value = val ?? "",
                                    isFullWidth: true,
                                  ),
                                );
                              }).toList(),
                            )),
                            Obx(() => controller.statusError.value != null 
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Text(controller.statusError.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                )
                              : const SizedBox.shrink()),
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
                            _buildLabel("Aptidão"),
                            const SizedBox(height: 12),
                            Obx(() => Row(
                              children: controller.aptidoes.map((a) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: a == controller.aptidoes.first ? 8 : 0),
                                  child: _buildRadioTile(
                                    label: a,
                                    value: a,
                                    groupValue: controller.aptidaoSelecionada.value,
                                    onChanged: (v) => controller.aptidaoSelecionada.value = v!,
                                  ),
                                ),
                              )).toList(),
                            )),
                            const SizedBox(height: 24),
                            _buildLabel("Fertilidade do Sêmen"),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller.fertilidadeSemenCtrl, 
                                    "Valor (0.0 a 1.0)", 
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                                    errorText: controller.semenFertilityError,
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
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  if (controller.isEdition) ...[
                    const SizedBox(height: 20),
                    _buildRastreabilidadeEditSection(context),
                  ],
                  
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
      ),
    );
  }

  Widget _buildRastreabilidadeEditSection(BuildContext context) {
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
              Icon(Icons.qr_code_2_outlined, size: 20, color: Colors.green[800]),
              const SizedBox(width: 8),
              const Text("Rastreabilidade", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          
          const Text("Documentação (PDF)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.pdfPath.value.isEmpty) {
              return OutlinedButton.icon(
                onPressed: () => controller.pickPDF(),
                icon: const Icon(Icons.upload_file),
                label: const Text("Fazer Upload de Certificado/Guia"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
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
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Documento Vinculado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => controller.removePDF(),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          
          Center(
            child: AnimalQRCodeWidget(
              animalId: controller.animalToEdit?['id']?.toString() ?? "0",
              identifier: controller.animalToEdit?['identifier']?.toString() ?? "ID Desconhecido",
              showExport: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildRadioTile({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
    bool isFullWidth = false,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[800]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green[800] : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
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

  Widget _buildTextField(TextEditingController ctrl, String label, {TextInputType? keyboardType, Rxn<String>? errorText, int? maxLength, List<TextInputFormatter>? inputFormatters, String? suffixText}) {
    final context = Get.context!;
    final decoration = InputDecoration(
      labelText: label,
      filled: true,
      fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: "", // Esconde o contador padrão para manter o design clean
      suffixText: suffixText,
    );

    if (errorText == null) {
      return TextField(
        controller: ctrl, 
        keyboardType: keyboardType, 
        maxLength: maxLength, 
        inputFormatters: inputFormatters,
        decoration: decoration
      );
    }

    return Obx(() => TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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
    String assetPath = 'assets/images/bovino_default.png';
    if (category == 'Ovino') assetPath = 'assets/images/ovino_default.png';
    if (category == 'Caprino') assetPath = 'assets/images/caprino_default.png';

    return Image.asset(assetPath, fit: BoxFit.cover);
  }

  void _showBreedIAInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.green[800]),
            const SizedBox(width: 10),
            const Text("Guia de Categorias IA"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem("Nativa Pura", "Raças adaptadas por séculos ao Semiárido (Ex: Moxotó, Repartida). Máxima resiliência térmica e resistência a doenças."),
              const SizedBox(height: 16),
              _buildInfoItem("Mestiço Sertanejo", "Cruzamentos de base local. Equilíbrio entre rusticidade para o calor e produção de carne/leite."),
              const SizedBox(height: 16),
              _buildInfoItem("Mestiço Exótico", "Foco em melhoramento produtivo. Exige maior cuidado nutricional e sombra, mas oferece retorno rápido."),
              const SizedBox(height: 16),
              _buildInfoItem("Exótica Pura", "Raças europeias de alta performance (Ex: Holandesa, Saanen). Muito sensíveis ao calor do Sertão; a IA aplicará penalidade de estresse térmico."),
              const SizedBox(height: 16),
              _buildInfoItem("SRD (Comum)", "Sem Raça Definida. Animais de base genética mista sem padrão produtivo específico."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Entendi", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showParityInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.child_care, color: Colors.green[800]),
            const SizedBox(width: 10),
            const Text("Guia de Paridade"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem("Nulípara", "Fêmea que nunca pariu. Geralmente novilhas ou cabras/ovelhas jovens em idade reprodutiva inicial."),
              const SizedBox(height: 16),
              _buildInfoItem("Primípara", "Fêmea que pariu apenas uma vez. Requer atenção especial pois ainda está em fase de crescimento."),
              const SizedBox(height: 16),
              _buildInfoItem("Multípara", "Fêmea que já pariu duas ou mais vezes. Matrizes experientes com histórico produtivo consolidado."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Entendi", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
      ],
    );
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

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sair sem salvar?"),
        content: const Text("Você fez alterações que não foram salvas. Deseja realmente sair e descartar as mudanças?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("DESCARTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
