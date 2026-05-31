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
                  "Nome do Rebanho (Ex: Lote Elite)",
                  errorText: controller.nomeRebanhoError
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller.localizacaoController, 
                  "Localização / Galpão (Opcional)",
                ),
                const SizedBox(height: 24),
                
                // CATEGORIA (RADIO)
                _buildLabel("Categoria do Rebanho"),
                const SizedBox(height: 12),
                Obx(() => Row(
                  children: controller.categorias.map((cat) => Expanded(
                    child: _buildRadioTile(
                      label: cat,
                      value: cat,
                      groupValue: controller.categoriaSelecionada.value,
                      onChanged: (v) => controller.setCategoria(v!),
                    ),
                  )).toList(),
                )),
                const SizedBox(height: 24),

                // TIPO DE MANEJO (RADIO)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel("Tipo de Manejo"),
                    TextButton.icon(
                      onPressed: () => _showManagementInfo(),
                      icon: Icon(Icons.info_outline, size: 14, color: Colors.green[800]),
                      label: Text("Entenda as diferenças", 
                        style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => Column(
                  children: controller.manejos.map((man) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRadioTile(
                      label: man,
                      value: man,
                      groupValue: controller.manejoSelecionado.value,
                      onChanged: (v) => controller.setManejo(v!),
                      isFullWidth: true,
                    ),
                  )).toList(),
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
      fillColor: context.theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green[800]!),
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

  void _showManagementInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green[800]),
            const SizedBox(width: 10),
            const Text("Guia de Manejo"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem("Extensivo", "O sistema tradicional do Sertão. Os bichos ficam soltos no pasto nativo e buscam comida sozinhos. Baixo custo, mas exige maior controle sanitário contra predadores e sede."),
              const SizedBox(height: 16),
              _buildInfoItem("Semiextensivo", "O animal pasta, mas também recebe um reforço alimentar no cocho . Ideal para manter o peso na seca."),
              const SizedBox(height: 16),
              _buildInfoItem("Intensivo", "Criação 100% no cocho ou em piquetes pequenos irrigados. Foco total em ganho de peso rápido e máxima produção de leite. Custo maior, retorno mais rápido."),
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
}

