import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'rebanho_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RebanhoView extends StatelessWidget {
  final RebanhoController controller = Get.put(RebanhoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        title: const Text('Meus Rebanhos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bovinos'),
            Tab(text: 'Ovinos'),
            Tab(text: 'Caprinos'),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: controller.tabController,
            children: [
              _buildRebanhoList(controller.bovinos, 'Bovinos', FontAwesomeIcons.cow, 'Bovino'),
              _buildRebanhoList(controller.ovinos, 'Ovinos', Icons.pets, 'Ovino'),
              _buildRebanhoList(controller.caprinos, 'Caprinos', Icons.agriculture, 'Caprino'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/cadastro-rebanho', arguments: controller.currentCategory),
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRebanhoList(RxList<Map<String, dynamic>> list, String labelPlural, dynamic icon, String categoryKey) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: icon is IconData 
                    ? Icon(icon, size: 60, color: Colors.green[200])
                    : FaIcon(icon, size: 60, color: Colors.green[200]),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nenhum rebanho encontrado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ops! Parece que você ainda não possui rebanhos de $labelPlural em sua base de dados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/cadastro-rebanho', arguments: categoryKey),
                  icon: const Icon(Icons.add, color: Colors.grey),
                  label: Text('Cadastrar rebanho de $labelPlural'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Get.context!.theme.cardColor,
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final herd = list[index];
          final count = herd['animal_count'] ?? 0;
          return Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: icon is IconData 
                  ? Icon(icon, color: Colors.green[800], size: 24)
                  : FaIcon(icon, color: Colors.green[800], size: 24),
              ),
              title: Text(
                herd['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                count == 1 ? '1 animal registrado' : '$count animais registrados',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Get.toNamed('/detalhes-rebanho', arguments: herd),
            ),
          );
        },
      );
    });
  }
}
