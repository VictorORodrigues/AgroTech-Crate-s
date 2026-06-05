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
          'Novo Rebanho', 
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black87, 
            fontWeight: FontWeight.bold, 
            fontSize: 18
          )
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
                _buildSectionTitle("INFORMAÇÕES BÁSICAS", Icons.info_outline),
                const SizedBox(height: 16),
                _buildTextField(
                  controller.nomeRebanhoController, 
                  "Nome do Rebanho (Ex: Lote Elite)",
                  errorText: controller.nomeRebanhoError,
                  icon: Icons.drive_file_rename_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller.localizacaoController, 
                  "Localização / Galpão (Opcional)",
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle("CATEGORIA E MANEJO", Icons.science_outlined),
                const SizedBox(height: 16),
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType? keyboardType, Rxn<String>? errorText, IconData? icon}) {
    final context = Get.context!;
    final decoration = _inputDecoration(hintText: hint, prefixIcon: icon).copyWith(
      errorText: errorText?.value,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[800]),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.green[800]) : null,
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
