import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import '../auth/auth_controller.dart';
import '../navigation/navigation_controller.dart';
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
    String getGreeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) return 'Bom dia';
      if (hour < 18) return 'Boa tarde';
      return 'Boa noite';
    }

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 110,
        leadingWidth: 85,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[900]!,
                Colors.green[800]!,
                Colors.green[700]!,
              ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.find<NavigationController>().changePage(4),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: Obx(() {
                final localPath = controller.userPhotoPath.value;
                final networkUrl = controller.networkPhotoUrl.value;
                bool useLocal = localPath.isNotEmpty && File(localPath).existsSync();
                final ImageProvider? provider = useLocal 
                    ? FileImage(File(localPath)) 
                    : (networkUrl.isNotEmpty ? NetworkImage(networkUrl) : null);

                return Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: provider != null 
                        ? DecorationImage(image: provider, fit: BoxFit.cover) 
                        : null,
                  ),
                  child: provider == null 
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                );
              }),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${getGreeting()},',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Obx(() => Text(
              controller.firstName.value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            )),
            const SizedBox(height: 2),
            Obx(() => Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white60, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${controller.farmName.value} • ${controller.userLocation.value}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            )),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  onPressed: () {
                    Get.toNamed('/notifications');
                    controller.notificationsController.markAllAsRead();
                  },
                ),
                Obx(() {
                  final count = controller.notificationsController.unreadCount.value;
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshHome,
        color: Colors.green[800],
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                              Obx(() => Row(
                                children: [
                                  if (controller.isOffline.value)
                                    const Icon(Icons.cloud_off_outlined, color: Colors.orange, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.localizacao.value,
                                    style: TextStyle(fontSize: 12, color: controller.isOffline.value ? Colors.orange[800] : Colors.green[700], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => controller.updateWeatherData(),
                                    child: Obx(() => controller.isLoadingWeather.value 
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                                      : Icon(Icons.refresh, size: 16, color: Colors.green[800])),
                                  ),
                                ],
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
                                child: Obx(() => _buildMonitorItem(
                                  _getWeatherIcon(controller.climaIcon.value), 
                                  controller.temperatura.value, 
                                  'Temperatura'
                                )),
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
                                      showInfo: true,
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
                    subtitle: 'Análise preditiva de cada animal',
                    icon: Icons.analytics_outlined,
                    isFullWidth: true,
                    onTap: () => Get.toNamed('/fertility-patterns'),
                  ),
                  const SizedBox(height: 20),
                  // --- NOVO CARROSSEL DE COTAÇÕES ---
                  _buildSectionHeader("Mercado e Cotações", Icons.trending_up),
                  const SizedBox(height: 12),
                  MarketCarousel(),
                  const SizedBox(height: 20),
                  // Grid de Atalhos Atualizado
                  _buildSectionHeader("Gerenciamento", Icons.grid_view_outlined),
                  const SizedBox(height: 12),
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
                  // --- NOVO CARROSSEL DE NOTÍCIAS REGIONAIS ---
                  _buildSectionHeader("Conexão Crateús", Icons.newspaper_outlined),
                  const SizedBox(height: 12),
                  NewsCarousel(),
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

  Widget _buildMonitorItem(IconData icon, String value, String label, {Color? valueColor, bool showBadge = false, bool showInfo = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[500], size: 28),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Get.context!.theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showTHIInfo(),
                child: Icon(Icons.info_outline, size: 14, color: Colors.green[800]),
              ),
            ],
          ],
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

  IconData _getWeatherIcon(String code) {
    // Mapeamento de ícones do OpenWeather para Icons do Flutter
    switch (code) {
      case '01d': return Icons.wb_sunny_outlined;
      case '01n': return Icons.nightlight_round;
      case '02d':
      case '02n':
      case '03d':
      case '03n':
      case '04d':
      case '04n': return Icons.cloud_outlined;
      case '09d':
      case '09n':
      case '10d':
      case '10n': return Icons.umbrella_outlined;
      case '11d':
      case '11n': return Icons.thunderstorm_outlined;
      case '13d':
      case '13n': return Icons.ac_unit;
      case '50d':
      case '50n': return Icons.blur_on;
      default: return Icons.wb_sunny_outlined;
    }
  }

  void _showTHIInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green[800]),
            const SizedBox(width: 10),
            const Text("O que é THI?"),
          ],
        ),
        content: const Text(
          "O THI (Índice de Temperatura e Umidade) mede o nível de estresse térmico dos animais. \n\n"
          "✅ Abaixo de 72: Conforto\n"
          "⚠️ 72 a 78: Estresse Leve\n"
          "🚨 79 a 88: Estresse Moderado\n"
          "🔥 Acima de 89: Estresse Grave\n\n"
          "Mantenha seus animais hidratados e em locais arejados nos dias de THI alto!",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("ENTENDI", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[900]!,
              const Color(0xFF1B5E20),
              const Color(0xFF003300),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  padding: EdgeInsets.all(isFullWidth ? 14 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3 * value),
                        blurRadius: 15 * value,
                        spreadRadius: 2 * value,
                      )
                    ],
                  ),
                  child: Icon(icon, color: Colors.greenAccent, size: isFullWidth ? 28 : 22),
                );
              },
            ),
            SizedBox(width: isFullWidth ? 20 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isFullWidth ? 17 : 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.greenAccent.withOpacity(0.7),
                      fontSize: isFullWidth ? 13 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.greenAccent.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }
}
