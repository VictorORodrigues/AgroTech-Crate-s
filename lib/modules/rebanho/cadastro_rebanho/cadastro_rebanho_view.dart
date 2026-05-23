import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'cadastro_rebanho_controller.dart';

class CadastroRebanhoView extends StatelessWidget {
  final CadastroRebanhoController controller = Get.put(CadastroRebanhoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: const Text('Novo Rebanho', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Informações do Rebanho", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField(
                  controller.nomeRebanhoController, 
                  "Nome do Rebanho",
                  errorText: controller.nomeRebanhoError
                ),
                const SizedBox(height: 16),
                Obx(() => _buildDropdown(
                  label: "Categoria",
                  value: controller.categoriaSelecionada.value,
                  items: controller.categorias,
                  onChanged: controller.setCategoria,
                  errorText: controller.categoriaError.value
                )),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showManagementInfo(),
                    icon: Icon(Icons.info_outline, size: 16, color: Colors.green[800]),
                    label: Text("Entenda os tipos de manejo", 
                      style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => _buildDropdown(
                  label: "Tipo de Manejo",
                  value: controller.manejoSelecionado.value,
                  items: controller.manejos,
                  onChanged: (v) => controller.manejoSelecionado.value = v ?? "Extensivo",
                )),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.salvarRebanhoCompleto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cadastrar Rebanho", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Após cadastrar o rebanho, você poderá adicionar os animais individualmente na aba 'Animais'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType? keyboardType, Rxn<String>? errorText}) {
    final context = Get.context!;
    final decoration = InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    if (errorText == null) {
      return TextField(controller: ctrl, keyboardType: keyboardType, decoration: decoration);
    }

    return Obx(() => TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: decoration.copyWith(errorText: errorText.value),
    ));
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged, String? errorText}) {
    final context = Get.context!;
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      hint: Text(label),
      decoration: InputDecoration(
        errorText: errorText,
        filled: true,
        fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  void _showManagementInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green),
            SizedBox(width: 10),
            Text("Tipos de Manejo"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem("Extensivo", "Os animais vivem soltos no pasto e buscam seu próprio alimento na Caatinga/pastagem nativa. Baixo custo de produção."),
              const SizedBox(height: 16),
              _buildInfoItem("Semiextensivo", "Os animais passam parte do dia no pasto e recebem reforço de ração ou silagem no cocho em horários específicos."),
              const SizedBox(height: 16),
              _buildInfoItem("Intensivo", "Criação em confinamento total ou áreas pequenas com alimentação controlada no cocho. Foco em alta produtividade."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Entendi", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
}

