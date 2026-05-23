import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        title: const Text("Meu Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.isEditing.value ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: controller.toggleEdit,
          )),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Verde com Foto
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: controller.photoUrl.value.isNotEmpty ? NetworkImage(controller.photoUrl.value) : null,
                      child: controller.photoUrl.value.isEmpty 
                        ? Icon(Icons.person, size: 60, color: Colors.green[800])
                        : null,
                    ),
                  )),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Obx(() => controller.isEditing.value ? _buildEditForm(context) : _buildProfileDetails(context)),
            ),

            const SizedBox(height: 40),
            
            // Botão de Excluir Conta (Sutil mas visível)
            TextButton(
              onPressed: controller.confirmDeleteAccount,
              child: const Text("Excluir Conta", style: TextStyle(color: Colors.redAccent, fontSize: 13, decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    return Column(
      children: [
        _buildInfoCard(
          title: "Dados do Produtor",
          children: [
            _buildDetailRow("Nome Completo", controller.userName.value, Icons.person_outline),
            _buildDetailRow("E-mail", controller.email.value, Icons.email_outlined),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: "Sua Propriedade",
          children: [
            _buildDetailRow("Fazenda", controller.farmName.value, Icons.agriculture),
            _buildDetailRow("Localização", controller.location.value, Icons.location_on_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Editando Informações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildEditField(controller.nameCtrl, "Seu Nome", Icons.person_outline),
        const SizedBox(height: 16),
        _buildEditField(controller.farmCtrl, "Nome da Fazenda", Icons.agriculture),
        const SizedBox(height: 16),
        _buildEditField(controller.locationCtrl, "Localização (Ex: Crateús, CE)", Icons.location_on_outlined),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: controller.toggleEdit,
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[800]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green[800]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green[800]!)),
      ),
    );
  }
}
