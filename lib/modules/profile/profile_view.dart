import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../database/database_helper.dart';
import '../../utils/agro_alerts.dart';
import '../navigation/navigation_controller.dart';
import '../home/theme_controller.dart';
import '../../services/sync_service.dart';
import 'profile_controller.dart';

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: textColor),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Get.back();
                } else if (Get.isRegistered<NavigationController>()) {
                  Get.find<NavigationController>().changePage(0);
                }
              },
            ),
          ),
        ),
        title: Text(
          "Meu Perfil",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Card do Usuário (Minimalista)
            _buildUserCard(context, cardColor, textColor, secondaryTextColor),
            
            const SizedBox(height: 40),
            
            _buildSmallTitle("CONFIGURAÇÕES TÉCNICAS", secondaryTextColor),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: "Dados Pessoais",
                onTap: () => Get.toNamed('/edit-profile'),
                textColor: textColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.science_outlined,
                title: "Prazos Biológicos (IA)",
                onTap: () => Get.toNamed('/biologic-config'),
                textColor: textColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.settings_outlined,
                title: "Sistema e Interface",
                onTap: () => _showSettingsBottomSheet(context),
                textColor: textColor,
                isDark: isDark,
              ),
            ], cardColor),
            
            const SizedBox(height: 32),
            _buildSmallTitle("SUPORTE E AJUDA", secondaryTextColor),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.menu_book_outlined,
                title: "Guia de Uso",
                onTap: () => Get.toNamed('/tutorial'),
                textColor: textColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.support_agent_outlined,
                title: "Suporte Técnico",
                onTap: () => Get.toNamed('/support'),
                textColor: textColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: "Sobre o AgroGen",
                onTap: () => _showAboutDialog(context),
                textColor: textColor,
                isDark: isDark,
              ),
            ], cardColor),
            
            const SizedBox(height: 32),
            _buildSmallTitle("ACESSO", secondaryTextColor),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.logout,
                title: "Sair da Conta",
                onTap: controller.logout,
                textColor: Colors.redAccent,
                isDark: isDark,
                showChevron: false,
              ),
            ], cardColor),
            
            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: controller.confirmDeleteAccount,
                child: Text(
                  "ENCERRAR CONTA PERMANENTEMENTE",
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTitle(String text, Color? color) {
    return Text(
      text,
      style: TextStyle(color: color ?? Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  Widget _buildUserCard(BuildContext context, Color cardColor, Color textColor, Color? secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Obx(() {
            final localPath = controller.localPhotoPath.value;
            final networkUrl = controller.photoUrl.value;
            bool useLocal = localPath.isNotEmpty && File(localPath).existsSync();
            final ImageProvider? provider = useLocal ? FileImage(File(localPath)) : (networkUrl.isNotEmpty ? NetworkImage(networkUrl) : null);

            return Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
              ),
              child: provider == null ? Icon(Icons.person, color: Colors.green[800], size: 30) : null,
            );
          }),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.userName.value,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                )),
                const SizedBox(height: 4),
                Text(
                  "Produtor Rural",
                  style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondaryTextColor?.withOpacity(0.3), size: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
    required bool isDark,
    bool showChevron = true,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: textColor.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: textColor.withOpacity(0.7), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: showChevron 
        ? Icon(Icons.chevron_right, color: textColor.withOpacity(0.2), size: 20)
        : null,
    );
  }

  Widget _buildDarkThemeTile(bool isDark, Color textColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(Icons.dark_mode_outlined, color: textColor.withOpacity(0.7), size: 22),
      title: Text(
        "Modo escuro",
        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Obx(() => Switch.adaptive(
        value: themeController.isDarkMode.value,
        activeColor: Colors.green[800],
        onChanged: (v) => themeController.toggleTheme(),
      )),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[800]!.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_outlined, color: Colors.green[800], size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              "AgroGen Crateús",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.0),
            ),
            const Text(
              "Pecuária de Precisão com Inteligência Artificial",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Text(
              "Versão 2.4.0 • Edição Hackathon 2026\n\nDesenvolvido para revolucionar a produtividade no semiárido cearense através de modelos preditivos e rastreabilidade total.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Configurações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDarkThemeTile(context.isDarkMode, context.isDarkMode ? Colors.white : Colors.black87),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.green),
              title: const Text("Sincronizar Agora", style: TextStyle(fontSize: 14)),
              subtitle: const Text("Subir dados locais para a nuvem", style: TextStyle(fontSize: 11)),
              onTap: () async {
                Get.back();
                AgroAlert.show(title: "Sincronizando", message: "Aguarde enquanto enviamos seus dados...");
                await SyncService.instance.syncLocalToCloud();
                Get.back(); // Fecha o alerta de processando
                AgroAlert.show(title: "Concluído", message: "Backup em nuvem realizado com sucesso!", isSuccess: true);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.data_exploration_outlined, color: Colors.blue),
              title: const Text("Gerar Dados de Teste (Mock)", style: TextStyle(fontSize: 14)),
              subtitle: const Text("Adiciona 30 animais e 20 atividades extras", style: TextStyle(fontSize: 11)),
              onTap: () async {
                Get.back();
                AgroAlert.show(title: "Processando", message: "Gerando base de dados massiva...");
                await DatabaseHelper.instance.appendMassiveMockData();
                AgroAlert.show(title: "Sucesso", message: "Dados gerados! Reinicie o app para ver tudo.", isSuccess: true);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("Fechar", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
