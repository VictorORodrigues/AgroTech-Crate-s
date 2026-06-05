import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../../../../utils/currency_input_formatter.dart';
import 'activity_details_controller.dart';

class ActivityDetailsView extends StatelessWidget {
  final ActivityDetailsController controller = Get.put(ActivityDetailsController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ActivityDetailsController>(
      builder: (_) {
        return Obx(() {
          final e = controller.event.value;
          if (e.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final bool isTask = e['is_task'] == 1;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              _handleBack();
            },
            child: Scaffold(
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
                      onPressed: _handleBack,
                    ),
                  ),
                ),
                title: Text(
                  isTask ? "Detalhes da Tarefa" : "Detalhes do Manejo", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
                  )
                ),
                actions: [
                  CircleAvatar(
                    backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                    child: IconButton(
                      icon: Obx(() => Icon(
                        controller.isEditing.value ? Icons.close : Icons.edit_outlined, 
                        color: Colors.green[800],
                        size: 20,
                      )),
                      onPressed: () => controller.toggleEdit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de Data e Hora com visual de "Pílula"
                    _buildDateTimeSection(context),
                    const SizedBox(height: 20),
                    
                    if (isTask) _buildTaskCard(context, e) else _buildManejoHeader(context, e),
                    
                    const SizedBox(height: 24),
                    Obx(() => controller.isEditing.value 
                      ? const Text("EDITAR OBSERVAÇÕES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1))
                      : const Text("OBSERVAÇÕES / NOTAS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1))
                    ),
                    const SizedBox(height: 12),
                    Obx(() => TextField(
                      controller: controller.descriptionCtrl,
                      maxLines: 5,
                      enabled: controller.isEditing.value,
                      decoration: InputDecoration(
                        hintText: "Sem observações registradas.",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
                        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[100]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green[800]!, width: 2)),
                      ),
                    )),
                    const SizedBox(height: 32),
                    Obx(() => (controller.isEditing.value)
                      ? SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: controller.updateActivity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: controller.isLoading.value 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          ),
                        )
                      : const SizedBox.shrink()
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        });
      }
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDateTimePickerTile(
              context,
              icon: Icons.calendar_month_outlined,
              label: "DATA",
              value: DateFormat('dd/MM/yyyy').format(controller.manualDate.value),
              onTap: isEditing ? () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.manualDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) controller.manualDate.value = picked;
              } : null,
            ),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildDateTimePickerTile(
              context,
              icon: Icons.access_time_rounded,
              label: "HORA",
              value: controller.manualTime.value.format(context),
              onTap: isEditing ? () async {
                final picked = await showTimePicker(context: context, initialTime: controller.manualTime.value);
                if (picked != null) controller.manualTime.value = picked;
              } : null,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDateTimePickerTile(BuildContext context, {required IconData icon, required String label, required String value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.green[800]),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() async {
    if (controller.isEditing.value && controller.hasChanges()) {
      final shouldPop = await _showExitConfirmation();
      if (shouldPop) Get.back();
    } else {
      Get.back();
    }
  }

  Future<bool> _showExitConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Descartar alterações?"),
        content: const Text("Você modificou dados que ainda não foram salvos. Deseja realmente sair?"),
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

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> e) {
    final bool isCompleted = e['text_value_1'] == 'Concluída';
    final color = e['color_hex'] != null 
        ? Color(int.parse(e['color_hex'], radix: 16)) 
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("TAREFA PESSOAL", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              GestureDetector(
                onTap: () => controller.toggleTaskCompletion(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCompleted ? Colors.green[200]! : Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(isCompleted ? Icons.check_circle : Icons.pending_actions, 
                        size: 14, color: isCompleted ? Colors.green[800] : Colors.orange[800]),
                      const SizedBox(width: 6),
                      Text(isCompleted ? "CONCLUÍDA" : "PENDENTE", 
                        style: TextStyle(color: isCompleted ? Colors.green[800] : Colors.orange[800], 
                        fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => controller.isEditing.value
            ? TextField(
                controller: controller.value1Ctrl,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: "Título da tarefa",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
                ),
              )
            : Text(
                e['type'], 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black87,
                )
              ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.task_alt, color: isCompleted ? Colors.green : Colors.grey),
            title: const Text("Status da Tarefa", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
            subtitle: Text(isCompleted ? "Realizada com sucesso" : "Aguardando execução", style: const TextStyle(fontSize: 12)),
            value: isCompleted,
            activeColor: Colors.green,
            onChanged: (_) => controller.toggleTaskCompletion(),
          ),
        ],
      ),
    );
  }

  Widget _buildManejoHeader(BuildContext context, Map<String, dynamic> e) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green[800]!.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("MANEJO TÉCNICO", style: TextStyle(color: Colors.green[800], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ),
              if (e['category'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(e['category'].toUpperCase(), style: TextStyle(color: Colors.orange[800], fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(e['type'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1)),
          const SizedBox(height: 20),
          Obx(() => _buildStructuredData(context, e)),
          
          if (e['animal_id'] != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            Text(
              (e['type'] == 'Nascimento' || e['type'] == 'Diagnóstico de Toque') 
                ? "ANIMAL ENVOLVIDO (MÃE)" 
                : "ANIMAL ENVOLVIDO", 
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.animalData.value == null) return const SizedBox.shrink();
              return _buildAnimalCard(context, controller.animalData.value!);
            }),
            
            // Exibição do filhote se existir
            Obx(() {
              if (controller.offspringData.value == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text("FILHOTE CADASTRADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _buildAnimalCard(context, controller.offspringData.value!),
                ],
              );
            }),
          ],
          
          if (e['animal_id'] == null && (e['herd_name'] != null || e['herd_id'] != null)) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Rebanho: ", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                Text(e['herd_name'] ?? 'Carregando...', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
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
        fields.add(_buildDetailRow("Peso Atual", "${e['value_1'] ?? '0.0'} kg", Icons.scale_outlined));
        fields.add(_buildDetailRow("ECC Atual", "${e['value_2'] ?? '3.0'}", Icons.analytics_outlined));
        fields.add(const Divider(height: 24));
        fields.add(_buildDetailRow("Peso Anterior", "${e['text_value_1'] ?? '0.0'} kg", Icons.history, isSecondary: true));
        fields.add(_buildDetailRow("ECC Anterior", "${e['text_value_2'] ?? '3.0'}", Icons.history, isSecondary: true));
      } else {
        fields.add(_buildLabel("PESO ATUAL (KG)"));
        fields.add(_buildTextField(controller.value1Ctrl, "Ex: 450", Icons.scale_outlined, keyboardType: TextInputType.number));
        fields.add(const SizedBox(height: 20));
        fields.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("ECC ATUAL (1.0 - 5.0)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(controller.eccValue.value.toStringAsFixed(1), style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
          ],
        ));
        fields.add(Slider(
          value: controller.eccValue.value,
          min: 1, max: 5, divisions: 8,
          onChanged: (v) => controller.eccValue.value = v,
          activeColor: Colors.green[800],
        ));
      }
    } else if (type == "Produção de Leite") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Volume Coletado", "${e['value_1'] ?? '0'} Litros", Icons.opacity));
      } else {
        fields.add(_buildLabel("QUANTIDADE (LITROS)"));
        fields.add(_buildTextField(controller.value1Ctrl, "Ex: 12.5", Icons.opacity, keyboardType: TextInputType.number));
      }
    } else if (type == "Vacinação") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Vacina Aplicada", "${e['text_value_1'] ?? 'N/A'}", Icons.vaccines_outlined));
        if (e['value_2'] != null && e['value_2'] > 0) {
          fields.add(_buildDetailRow("Valor Gasto", NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e['value_2']), Icons.payments_outlined));
        }
      } else {
        fields.add(_buildLabel("NOME DA VACINA"));
        fields.add(_buildTextField(controller.value1Ctrl, "Ex: Febre Aftosa", Icons.vaccines_outlined));
        fields.add(const SizedBox(height: 20));
        fields.add(_buildLabel("VALOR GASTO (R\$)"));
        fields.add(TextField(
          controller: controller.value2Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
        ));
      }
      if (e['text_value_2'] != null) {
        fields.add(_buildDetailRow("Data da 2ª Dose", DateFormat('dd/MM/yyyy').format(DateTime.parse(e['text_value_2'])), Icons.event_repeat, isSecondary: true));
      }
    } else if (type == "Medicamento") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Medicamento", "${e['text_value_1'] ?? 'N/A'}", Icons.medication_outlined));
        if (e['value_2'] != null && e['value_2'] > 0) {
          fields.add(_buildDetailRow("Valor Gasto", NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e['value_2']), Icons.payments_outlined));
        }
      } else {
        fields.add(_buildLabel("NOME DO MEDICAMENTO"));
        fields.add(_buildTextField(controller.value1Ctrl, "Ex: Ivomec", Icons.medication_outlined));
        fields.add(const SizedBox(height: 20));
        fields.add(_buildLabel("VALOR GASTO (R\$)"));
        fields.add(TextField(
          controller: controller.value2Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
        ));
      }
    } else if (type == "Diagnóstico de Toque") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Resultado Final", e['text_value_1'] ?? "N/A", Icons.search));
      } else {
        fields.add(_buildLabel("RESULTADO DO EXAME"));
        fields.add(const SizedBox(height: 8));
        fields.add(Row(
          children: [
            Expanded(child: _buildRadioTile("Positivo", "Positivo", controller.touchResult.value, (v) => controller.touchResult.value = v, activeColor: Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioTile("Negativo", "Negativo", controller.touchResult.value, (v) => controller.touchResult.value = v, activeColor: Colors.red)),
          ],
        ));
      }
    } else if (type == "Inseminação Artificial") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Método", e['text_value_1'] == "IA" ? "Inseminação Artificial" : "Monta Natural", Icons.favorite_border));
        if (e['value_1'] != null) fields.add(_buildDetailRow("Fertilidade", "${((e['value_1'] ?? 0) * 100).toInt()}%", Icons.bolt_outlined));
        if (e['value_2'] != null) {
          fields.add(_buildDetailRow("Valor Gasto", NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e['value_2']), Icons.payments_outlined));
        }
      } else {
        fields.add(_buildLabel("MÉTODO"));
        fields.add(DropdownButtonFormField<String>(
          value: controller.inseminationMethod.value,
          decoration: _inputDecoration(prefixIcon: Icons.favorite_border),
          items: const [DropdownMenuItem(value: "IA", child: Text("Inseminação Artificial")), DropdownMenuItem(value: "Monta", child: Text("Monta Natural"))],
          onChanged: (v) => controller.inseminationMethod.value = v!,
        ));
        fields.add(const SizedBox(height: 20));
        fields.add(_buildLabel("FERTILIDADE (0.0 - 1.0)"));
        fields.add(TextField(
          controller: controller.value1Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [controller.fertilityMask],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          decoration: _inputDecoration(prefixIcon: Icons.bolt_outlined).copyWith(hintText: "0.8"),
        ));
        fields.add(const SizedBox(height: 20));
        fields.add(_buildLabel("VALOR GASTO (R\$)"));
        fields.add(TextField(
          controller: controller.value2Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
        ));
      }
    } else if (type == "Nascimento") {
      if (!isEditing) {
        String t1 = e['text_value_1']?.toString() ?? "";
        if (t1.contains("|")) {
          String part1 = t1.split("|").first.trim();
          String part2 = t1.split("|").last.trim();
          fields.add(_buildDetailRow("Tipo de Parto", part1, Icons.child_care));
          fields.add(_buildDetailRow("Idade Gestacional", part2, Icons.hourglass_empty));
        } else {
          fields.add(_buildDetailRow("Detalhes do Parto", t1.isEmpty ? "N/A" : t1, Icons.child_care));
        }
      } else {
        fields.add(_buildLabel("TIPO DE PARTO"));
        fields.add(DropdownButtonFormField<String>(
          value: controller.birthType.value,
          decoration: _inputDecoration(prefixIcon: Icons.pets),
          items: ["Parto Vaginal (Normal)", "Cesárea"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => controller.birthType.value = v!,
        ));
        fields.add(const SizedBox(height: 20));
        fields.add(_buildLabel("IDADE GESTACIONAL"));
        fields.add(DropdownButtonFormField<String>(
          value: controller.gestationalAge.value,
          decoration: _inputDecoration(prefixIcon: Icons.hourglass_empty),
          items: ["Prematuro", "A Termo (no tempo certo)", "Pós-termo"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => controller.gestationalAge.value = v!,
        ));
      }
    } else if (type == "Óbito") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Causa da Morte", e['text_value_1'] ?? "Desconhecida", Icons.warning_amber_rounded));
      } else {
        fields.add(_buildLabel("CAUSA DA MORTE"));
        fields.add(DropdownButtonFormField<String>(
          value: controller.deathCause.value,
          decoration: _inputDecoration(prefixIcon: Icons.warning_amber_rounded),
          items: ["Acidente", "Doença", "Predador", "Intoxicação", "Desnutrição", "Desconhecida"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => controller.deathCause.value = v!,
        ));
      }
    } else if (type == "Aborto / Perda Gestacional") {
      if (!isEditing) {
        fields.add(_buildDetailRow("Causa Provável", e['text_value_1'] ?? "Desconhecida", Icons.heart_broken_outlined));
      } else {
        fields.add(_buildLabel("MOTIVO DA PERDA"));
        fields.add(DropdownButtonFormField<String>(
          value: controller.abortionCause.value,
          decoration: _inputDecoration(prefixIcon: Icons.heart_broken_outlined),
          items: ["Estresse Térmico Extremo", "Intoxicação por Plantas Tóxicas", "Desnutrição", "Traumatismo / Pancada", "Desconhecida"].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => controller.abortionCause.value = v!,
        ));
      }
    } else if (type == "Venda de Animal") {
      if (!isEditing) {
        if (e['value_2'] != null) {
          fields.add(_buildDetailRow("Valor da Venda", NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e['value_2']), Icons.payments_outlined));
        }
      } else {
        fields.add(_buildLabel("VALOR DA VENDA (R\$)"));
        fields.add(TextField(
          controller: controller.value2Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
        ));
      }
    } else if (type == "Compra de Animal") {
      if (!isEditing) {
        if (e['value_2'] != null) {
          fields.add(_buildDetailRow("Valor da Compra", NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e['value_2']), Icons.payments_outlined));
        }
      } else {
        fields.add(_buildLabel("VALOR DA COMPRA (R\$)"));
        fields.add(TextField(
          controller: controller.value2Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
        ));
      }
    } else if (type == "Abate") {
      fields.add(Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
        child: const Text("Este animal foi destinado ao abate.", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields,
        Obx(() {
          if (controller.breederData.value != null) {
            final String sireLabel = (type == 'Nascimento') ? "PAI DO FILHOTE (REPRODUTOR)" : "REPRODUTOR (PAI PROVÁVEL)";
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                Text(sireLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                _buildAnimalCard(context, controller.breederData.value!),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildRadioTile(String label, String value, String groupValue, Function(String) onChanged, {Color? activeColor}) {
    final isSelected = value == groupValue;
    final color = activeColor ?? Colors.green[800]!;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[200]!, width: 2),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  InputDecoration _inputDecoration({IconData? prefixIcon, String? suffixText, String? hintText, String? label}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.green[800], size: 20) : null,
      suffixText: suffixText,
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

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: _inputDecoration(prefixIcon: icon, hintText: hint),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isSecondary ? Colors.grey[400] : Colors.green[800]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: isSecondary ? Colors.grey[700] : Colors.black87, fontSize: 15, fontWeight: isSecondary ? FontWeight.bold : FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, Map<String, dynamic> animal) {
    return GestureDetector(
      onTap: () => Get.toNamed('/perfil-animal', arguments: animal),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green[50],
              backgroundImage: animal['photo_path'] != null && animal['photo_path'].toString().isNotEmpty
                ? FileImage(File(animal['photo_path'])) as ImageProvider
                : null,
              child: animal['photo_path'] == null || animal['photo_path'].toString().isEmpty
                ? Icon(Icons.pets, color: Colors.green[800])
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal['identifier'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("${animal['herd_name']} | ${animal['breed']}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
    final type = controller.event['type']?.toString() ?? "";
    const reproTypes = ["Inseminação Artificial", "Diagnóstico de Toque", "Nascimento", "Aborto / Perda Gestacional"];
    
    bool isRepro = reproTypes.contains(type);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text(isRepro ? "Atenção Biológica" : "Excluir Registro"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRepro 
                ? "Este manejo faz parte da árvore reprodutiva. Ao excluí-lo, todas as atividades posteriores e alterações automáticas (como o status da fêmea) serão desfeitas para manter a coerência do histórico."
                : "Tem certeza que deseja remover este registro? Esta ação não pode ser desfeita.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (isRepro) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  "Exemplo: Excluir uma Inseminação apagará também o Toque e o Parto vinculados a ela.",
                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteActivity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
