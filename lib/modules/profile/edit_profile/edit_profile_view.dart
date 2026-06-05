import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../profile_controller.dart';

class EditProfileView extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    // Ao abrir a tela, garantimos que o modo de edição está ativo no controller 
    // para que a lógica de hasChanges funcione corretamente ao voltar.
    controller.isEditing.value = true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green[800],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: "DADOS PESSOAIS",
                icon: Icons.person_outline,
                children: [
                  _buildEditField(controller.nameCtrl, "Nome Completo", Icons.badge_outlined),
                  const SizedBox(height: 20),
                  _buildEditField(
                    controller.phoneCtrl, 
                    "WhatsApp", 
                    Icons.phone_android, 
                    inputFormatters: [controller.phoneMask], 
                    keyboardType: TextInputType.phone
                  ),
                  const SizedBox(height: 20),
                  _buildEditField(
                    controller.emailCtrl, 
                    "E-mail de Contato", 
                    Icons.alternate_email, 
                    enabled: !controller.isGoogleAccount.value,
                    helperText: controller.isGoogleAccount.value ? "Vinculado à conta Google" : null
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: "PROPRIEDADE",
                icon: Icons.agriculture_outlined,
                children: [
                  _buildEditField(controller.farmCtrl, "Nome da Fazenda", Icons.house_outlined),
                  const SizedBox(height: 20),
                  _buildEditField(controller.carCodeCtrl, "Código CAR/INCRA", Icons.qr_code_outlined),
                  const SizedBox(height: 24),
                  const Text("LOCALIZAÇÃO / DISTRITO", 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedDistrict.value.isEmpty ? null : controller.selectedDistrict.value,
                    hint: const Text('Selecione o Distrito'),
                    items: controller.districts.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => controller.setDistrict(val ?? ""),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.green, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  )),
                  Obx(() => controller.isOtherDistrict.value 
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: _buildEditField(
                          controller.locationCtrl,
                          'Nome do Local / Distrito',
                          Icons.map_outlined,
                        ),
                      )
                    : const SizedBox.shrink()),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Obx(() => SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : () => controller.saveProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("SALVAR ALTERAÇÕES", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                ),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() async {
    if (controller.hasChanges()) {
      final shouldPop = await _showExitConfirmation();
      if (shouldPop) {
        // Se desistir da edição, limpamos o estado e voltamos
        controller.isEditing.value = false;
        controller.resetFields();
        Get.back();
      }
    } else {
      controller.isEditing.value = false;
      Get.back();
    }
  }

  Future<bool> _showExitConfirmation() async {
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.green[800]),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, IconData icon, {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType, bool enabled = true, String? helperText}) {
    return TextField(
      controller: ctrl,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
        helperText: helperText,
        prefixIcon: Icon(icon, color: Colors.green[800], size: 20),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green[800]!, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
