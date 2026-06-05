import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../../database/database_helper.dart';
import '../../../../utils/currency_input_formatter.dart';
import 'add_activity_controller.dart';

class AddActivityView extends StatelessWidget {
  final AddActivityController controller = Get.put(AddActivityController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Get.isDarkMode ? Colors.white : Colors.black87),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          "Novo Manejo", 
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black87, 
            fontWeight: FontWeight.bold, 
            fontSize: 18
          )
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final type = controller.selectedType.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("CONFIGURAÇÃO BÁSICA", Icons.settings_outlined),
              const SizedBox(height: 16),
              
              _buildLabel("Tipo de Atividade"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type.isEmpty ? null : type,
                hint: const Text("Selecione o manejo"),
                isExpanded: true,
                items: controller.types.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                )).toList(),
                onChanged: (v) => controller.selectedType.value = v ?? "",
                decoration: _inputDecoration(),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              if (type == "Outro") ...[
                const SizedBox(height: 20),
                _buildLabel("Título da Atividade (Obrigatório)"),
                const SizedBox(height: 8),
                _buildTextField(controller.value1Ctrl, "Ex: Conserto de cerca, Limpeza...", Icons.title),
              ],

              if (type == "Compra de Animal") ...[
                const SizedBox(height: 20),
                _buildLabel("Deseja cadastrar o animal agora?"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRadioTile(
                      label: "Sim", 
                      value: "SIM", 
                      groupValue: controller.registerNewOnPurchase.value ? "SIM" : "NAO", 
                      onChanged: (v) {
                        controller.registerNewOnPurchase.value = true;
                        _showHerdSelectionForPurchase(context);
                      }
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRadioTile(
                      label: "Não", 
                      value: "NAO", 
                      groupValue: controller.registerNewOnPurchase.value ? "SIM" : "NAO", 
                      onChanged: (v) => controller.registerNewOnPurchase.value = false
                    )),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              _buildLabel("Animal Envolvido ${type == "Outro" ? "(Opcional)" : ""}"),
              const SizedBox(height: 8),
              _buildAnimalSelector(context),

              if (type == "Outro") ...[
                const SizedBox(height: 20),
                _buildLabel("Rebanho Relacionado (Opcional)"),
                const SizedBox(height: 8),
                _buildHerdSelector(context),
              ],

              const SizedBox(height: 20),
              _buildLabel("Data e Hora do Manejo"),
              const SizedBox(height: 8),
              _buildDateTimePickers(context),

              const Divider(height: 48),
              if (type.isNotEmpty) ...[
                _buildSectionTitle("DADOS TÉCNICOS ESPECÍFICOS", Icons.analytics_outlined),
                const SizedBox(height: 20),
                _buildDynamicInputs(context),
              ],

              const SizedBox(height: 24),
              _buildLabel("Observações / Detalhes"),
              const SizedBox(height: 8),
              _buildTextField(controller.descriptionCtrl, "Relate aqui detalhes técnicos do manejo...", Icons.notes, maxLines: 3),

              const SizedBox(height: 48),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          );
        }),
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

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87));
  }

  InputDecoration _inputDecoration({IconData? prefixIcon, String? suffixText, String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.green[800], size: 20) : null,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTimePickers(BuildContext context) {
    return Row(
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(DateFormat('dd/MM/yyyy').format(controller.manualDate.value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
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
              final picked = await showTimePicker(context: context, initialTime: controller.manualTime.value);
              if (picked != null) controller.manualTime.value = picked;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(controller.manualTime.value.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicInputs(BuildContext context) {
    final type = controller.selectedType.value;
    
    if (type == "Vacinação") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Nome da Vacina"),
          const SizedBox(height: 8),
          _buildTextField(controller.value1Ctrl, "Ex: Febre Aftosa, Raiva...", Icons.vaccines_outlined),
          const SizedBox(height: 20),
          _buildLabel("Valor Gasto (R\$)"),
          const SizedBox(height: 8),
          TextField(
            controller: controller.value2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.moneyMask],
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
          ),
          const SizedBox(height: 20),
          _buildLabel("Agendar 2ª Dose (Opcional)"),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 21)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              controller.date2Ctrl.value = picked;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                    controller.date2Ctrl.value != null ? DateFormat('dd/MM/yyyy').format(controller.date2Ctrl.value!) : "Toque para selecionar",
                    style: TextStyle(color: controller.date2Ctrl.value == null ? Colors.grey : Colors.black87),
                  )),
                  if (controller.date2Ctrl.value != null)
                    GestureDetector(onTap: () => controller.date2Ctrl.value = null, child: const Icon(Icons.close, size: 18, color: Colors.red))
                  else
                    const Icon(Icons.event_repeat, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (type == "Medicamento") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Nome da Medicação"),
          const SizedBox(height: 8),
          _buildTextField(controller.value1Ctrl, "Ex: Ivomec, Terramicina...", Icons.medication_outlined),
          const SizedBox(height: 20),
          _buildLabel("Valor Gasto (R\$)"),
          const SizedBox(height: 8),
          TextField(
            controller: controller.value2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.moneyMask],
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
          ),
        ],
      );
    }

    if (type == "Pesagem e Escore") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Peso Atual (kg)"),
          const SizedBox(height: 8),
          _buildTextField(
            controller.value1Ctrl, 
            "Ex: 450", 
            Icons.scale_outlined, 
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.weightMask],
          ),
          const SizedBox(height: 24),
          _buildECCSlider(context),
        ],
      );
    }

    if (type == "Óbito") {
      final causas = ["Acidente", "Doença", "Predador", "Intoxicação", "Desnutrição", "Desconhecida"];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Causa da Morte"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.deathCause.value,
            items: causas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => controller.deathCause.value = v!,
            decoration: _inputDecoration(prefixIcon: Icons.warning_amber_rounded),
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      );
    }

    if (type == "Inseminação Artificial") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Método"),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          if (controller.inseminationType.value == "Monta") ...[
            _buildLabel("Selecionar Reprodutor (Macho)"),
            const SizedBox(height: 8),
            _buildSireSelector(context),
          ] else ...[
            _buildLabel("Fertilidade do Sêmen (0.0 - 1.0)"),
            const SizedBox(height: 8),
            _buildFertilityInput(),
          ],
          const SizedBox(height: 20),
          _buildLabel("Valor Gasto (R\$)"),
          const SizedBox(height: 8),
          TextField(
            controller: controller.value2Ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
          ),
        ],
      );
    }

    if (type == "Diagnóstico de Toque") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Resultado do Exame"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRadioTile(label: "Positivo", value: "Positivo", groupValue: controller.touchResult.value, onChanged: (v) => controller.touchResult.value = v!, activeColor: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildRadioTile(label: "Negativo", value: "Negativo", groupValue: controller.touchResult.value, onChanged: (v) => controller.touchResult.value = v!, activeColor: Colors.red)),
            ],
          ),
        ],
      );
    }

    if (type == "Aborto / Perda Gestacional") {
      final motivos = ["Estresse Térmico Extremo", "Intoxicação por Plantas Tóxicas", "Desnutrição / Privação Hídrica", "Brucelose / Leptospirose / Toxoplasmose", "Traumatismo / Pancada", "Consanguinidade Avançada", "Reação Vacinal / Medicamentosa", "Desconhecida"];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Motivo da Perda"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.abortionCause.value,
            items: motivos.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => controller.abortionCause.value = v!,
            decoration: _inputDecoration(prefixIcon: Icons.heart_broken_outlined),
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      );
    }

    if (type == "Produção de Leite") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Quantidade (Litros)"),
          const SizedBox(height: 8),
          _buildTextField(
            controller.value1Ctrl, 
            "Ex: 12.5", 
            Icons.opacity, 
            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
            suffixText: "L",
            inputFormatters: [controller.weightMask], // Reusando máscara decimal #.###.1
          ),
        ],
      );
    }

    if (type == "Nascimento") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Tipo de Parto"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRadioTile(label: "Vaginal", value: "Parto Vaginal (Normal)", groupValue: controller.birthType.value, onChanged: (v) => controller.birthType.value = v!)),
              const SizedBox(width: 12),
              Expanded(child: _buildRadioTile(label: "Cesárea", value: "Cesárea", groupValue: controller.birthType.value, onChanged: (v) => controller.birthType.value = v!)),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel("Idade Gestacional"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.gestationalAge.value,
            items: ["Prematuro", "A Termo (no tempo certo)", "Pós-termo"].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: (v) => controller.gestationalAge.value = v!,
            decoration: _inputDecoration(prefixIcon: Icons.hourglass_empty_outlined),
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      );
    }

    if (type == "Venda de Animal") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Valor da Venda (R\$)"),
          const SizedBox(height: 8),
          TextField(
            controller: controller.value2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.moneyMask],
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
          ),
        ],
      );
    }

    if (type == "Abate") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                const Expanded(child: Text("Ao confirmar o abate, o animal será marcado como Inativo e sairá dos índices de reprodução.", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      );
    }

    if (type == "Compra de Animal") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Valor da Compra (R\$)"),
          const SizedBox(height: 8),
          TextField(
            controller: controller.value2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.moneyMask],
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showHerdSelectionForPurchase(BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    final herds = await db.query('herds');

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const Text("Selecione o Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Para onde o animal comprado irá?", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: herds.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final h = herds[index];
                  return ListTile(
                    leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                    title: Text(h['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${h['category']} | ${h['management_type']}"),
                    onTap: () async {
                      Get.back();
                      final result = await Get.toNamed('/add-animal', arguments: {
                        'herd': h,
                        'isEdition': false,
                      });
                      if (result != null && result is Map<String, dynamic>) {
                         controller.selectedAnimal.value = result;
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildECCSlider(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("ECC Atual (1.0 - 5.0)"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(20)),
              child: Obx(() => Text(controller.eccValue.value.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.green[800],
            thumbColor: Colors.green[800],
            valueIndicatorColor: Colors.green[800],
          ),
          child: Slider(
            value: controller.eccValue.value,
            min: 1, max: 5, divisions: 8,
            onChanged: (v) => controller.eccValue.value = v,
          ),
        ),
      ],
    );
  }

  Widget _buildFertilityInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.value1Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.semenMask],
            onChanged: controller.validateSemenInput,
            decoration: _inputDecoration(prefixIcon: Icons.bolt_outlined),
          ),
        ),
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

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, String? suffixText, List<TextInputFormatter>? inputFormatters, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: _inputDecoration(prefixIcon: icon, suffixText: suffixText, hintText: hint),
    );
  }

  Widget _buildRadioTile({required String label, required String value, required String groupValue, required Function(String?) onChanged, Color? activeColor}) {
    final isSelected = value == groupValue;
    final themeColor = activeColor ?? Colors.green[800]!;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? themeColor : Colors.grey[200]!, width: 2),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? themeColor : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildAnimalSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAnimalSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Obx(() => Text(
                controller.selectedAnimal.value != null 
                  ? "${controller.selectedAnimal.value!['identifier']} (${controller.selectedAnimal.value!['name'] ?? 'S/N'})"
                  : "Toque para buscar animal...",
                style: TextStyle(color: controller.selectedAnimal.value == null ? Colors.grey : Colors.black87),
              )),
            ),
            Obx(() => controller.selectedAnimal.value != null
              ? IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => controller.selectedAnimal.value = null)
              : const Icon(Icons.search, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHerdSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHerdSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Obx(() => Text(
                controller.selectedHerd.value != null ? controller.selectedHerd.value!['name'] : "Toque para buscar rebanho...",
                style: TextStyle(color: controller.selectedHerd.value == null ? Colors.grey : Colors.black87),
              )),
            ),
            Obx(() => controller.selectedHerd.value != null
              ? IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => controller.selectedHerd.value = null)
              : const Icon(Icons.search, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSireSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSireSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!, width: 1.5)),
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

  void _showAnimalSearch(BuildContext context) {
    controller.searchCategoryFilter.value = "Todos";
    controller.searchSexFilter.value = "Todos";
    var query = "".obs;
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const Text("Buscar Animal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(onChanged: (v) => query.value = v, decoration: _inputDecoration(prefixIcon: Icons.search).copyWith(hintText: "ID, Nome, Raça, Rebanho...")),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...["Todos", "Bovino", "Ovino", "Caprino"].map((c) => Obx(() => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(label: Text(c, style: TextStyle(fontSize: 11, color: controller.searchCategoryFilter.value == c ? Colors.white : Colors.black)), selected: controller.searchCategoryFilter.value == c, onSelected: (_) => controller.searchCategoryFilter.value = c, selectedColor: Colors.green[800]),
                  ))),
                  const VerticalDivider(),
                  ...["Todos", "Macho", "Fêmea"].map((s) => Obx(() => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(label: Text(s, style: TextStyle(fontSize: 11, color: controller.searchSexFilter.value == s ? Colors.white : Colors.black)), selected: controller.searchSexFilter.value == s, onSelected: (_) => controller.searchSexFilter.value = s, selectedColor: Colors.blue[800]),
                  ))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final results = controller.getFilteredAnimalsList(query.value);
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text("Nenhum animal encontrado", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final a = results[index];
                    return ListTile(
                      title: Text(a['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${a['name'] ?? 'S/N'} | ${a['breed']} | ${a['herd_name']}"),
                      onTap: () { controller.selectedAnimal.value = a; Get.back(); },
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

  void _showHerdSearch(BuildContext context) {
    var query = "".obs;
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const Text("Buscar Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(onChanged: (v) => query.value = v, decoration: _inputDecoration(prefixIcon: Icons.search).copyWith(hintText: "Nome do rebanho...")),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                final res = controller.allHerds.where((h) => h['name'].toString().toLowerCase().contains(query.value.toLowerCase())).toList();
                if (res.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text("Nenhum rebanho encontrado", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: res.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) => ListTile(title: Text(res[index]['name']), subtitle: Text(res[index]['category']), onTap: () { controller.selectedHerd.value = res[index]; Get.back(); }),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSireSearch(BuildContext context) {
    var query = "".obs;
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const Text("Buscar Reprodutor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(onChanged: (v) => query.value = v, decoration: _inputDecoration(prefixIcon: Icons.search).copyWith(hintText: "ID ou Nome do Macho...")),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                final res = controller.potentialSires.where((s) => s['identifier'].toString().toLowerCase().contains(query.value.toLowerCase())).toList();
                if (res.isEmpty && query.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text("Nenhum reprodutor encontrado", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: res.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return ListTile(title: const Text("Reprodutor Desconhecido"), leading: const Icon(Icons.help_outline), onTap: () { controller.selectedReprodutor.value = {'id': -1, 'identifier': 'Desconhecido', 'semen_fertility': 1.0}; Get.back(); });
                    final s = res[index-1];
                    return ListTile(title: Text(s['identifier']), subtitle: Text("${s['name'] ?? 'S/N'} | ${s['breed']}"), onTap: () { controller.selectedReprodutor.value = s; Get.back(); });
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

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.saveActivity,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: controller.isLoading.value ? const CircularProgressIndicator(color: Colors.white) : const Text("SALVAR REGISTRO TÉCNICO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
    ));
  }
}
