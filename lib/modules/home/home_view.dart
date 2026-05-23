import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import '../auth/auth_controller.dart';
import 'home_controller.dart';
import '../../services/sync_service.dart';
import '../../utils/agro_alerts.dart';
import 'market_carousel/market_carousel_view.dart';
import 'news_carousel/news_carousel_view.dart';
import 'theme_controller.dart';

class HomeView extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final HomeController controller = Get.put(HomeController());
  final ThemeController themeController = Get.find<ThemeController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String photoUrl = user?.photoURL ?? "";
    
    final String userName = _storage.read('userName') ?? user?.displayName ?? "Usuário";
    final String farmName = _storage.read('farmName') ?? "Sua Fazenda";
    final String location = _storage.read('location') ?? "Crateús, CE";
    final String email = user?.email ?? "";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        toolbarHeight: 120,
        leadingWidth: 85,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person_outline, color: Colors.white, size: 30)
                    : null,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Olá, $userName!',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$farmName, $location',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            onPressed: () => Get.toNamed('/chatbot'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
            onPressed: () => Get.toNamed('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: false,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.green[800]),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Icon(Icons.person, size: 40, color: Colors.green[800])
                    : null,
              ),
              accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () => _showSettingsBottomSheet(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Meu Perfil'),
              onTap: () {
                Get.back();
                Get.toNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Manejo'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Tutorial'),
              onTap: () {
                Get.back();
                Get.toNamed('/tutorial');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                authController.logout();
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Card de Monitoramento em Tempo Real
                Container(
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monitoramento em Tempo Real',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Obx(() => Text(
                                  controller.localizacao.value,
                                  style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                                )),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Obx(() => _buildMonitorItem(Icons.thermostat, controller.temperatura.value, 'Temperatura')),
                            ),
                            _buildDivider(),
                            Expanded(
                              child: Obx(() => _buildMonitorItem(Icons.water_drop_outlined, controller.umidade.value, 'Umidade')),
                            ),
                            _buildDivider(),
                            Expanded(
                              child: Obx(() => _buildMonitorItem(
                                    Icons.warning_amber_rounded,
                                    controller.thi.value,
                                    'THI',
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Obx(() => Text(
                                  'Última atualização: ${controller.lastUpdate.value}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // --- NOVO CARROSSEL DE COTAÇÕES ---
                MarketCarousel(),
                const SizedBox(height: 20),
                // Três cards verdes principais empilhados verticalmente
                _buildActionCard(
                  title: 'Nova Análise de Prenhez com IA',
                  subtitle: 'Analisar chance real de Inseminação',
                  icon: Icons.psychology_outlined,
                  isFullWidth: true,
                  onTap: () => Get.toNamed('/ia-analysis'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Ranking de Reprodutores',
                  subtitle: 'IA de Melhoramento Genético',
                  icon: Icons.star_border,
                  isFullWidth: true,
                  onTap: () => Get.toNamed('/ranking-abs'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Padrões de fertilidade',
                  subtitle: 'Módulo em breve no seu painel',
                  icon: Icons.analytics_outlined,
                  isFullWidth: true,
                  onTap: () => Get.toNamed('/fertility-patterns'),
                ),
                const SizedBox(height: 20),
                // --- NOVO CARROSSEL DE NOTÍCIAS REGIONAIS ---
                _buildSectionHeader("Conexão Crateús", Icons.newspaper_outlined),
                const SizedBox(height: 12),
                NewsCarousel(),
                const SizedBox(height: 20),
                // Grid de Atalhos Atualizado
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/rebanho'),
                        child: _buildGridCard(Icons.pets, 'Meus Rebanhos', 'Gerencie seus Animais'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/reports'),
                        child: _buildGridCard(Icons.description_outlined, 'Relatórios', 'Dashboard e Exportação'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/activities-history'),
                        child: _buildGridCard(Icons.history, 'Atividades e Histórico', 'Eventos Salvos'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/calendar'),
                        child: _buildGridCard(Icons.calendar_month_outlined, 'Calendário', 'Vacinas e Manejo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Card de Resumo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total de Animais', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('45', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Análises este mês', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final context = Get.context!;
    return Row(
      children: [
        Icon(icon, color: Colors.green[800], size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green[800], size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorItem(IconData icon, String value, String label, {Color? valueColor, bool showBadge = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[500], size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Get.context!.theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        if (showBadge) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Crítico',
              style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Obx(() => SwitchListTile(
                  title: const Text('Modo Escuro'),
                  subtitle: const Text('Alternar entre tema claro e escuro'),
                  value: themeController.isDarkMode.value,
                  activeColor: Colors.green[800],
                  onChanged: (val) => themeController.toggleTheme(),
                  secondary: Icon(
                    themeController.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                    color: themeController.isDarkMode.value ? Colors.blueAccent : Colors.orange,
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isFullWidth,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isFullWidth ? 12 : 8),
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: isFullWidth ? 30 : 22),
            ),
            SizedBox(width: isFullWidth ? 16 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isFullWidth ? 16 : 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isFullWidth ? 13 : 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
