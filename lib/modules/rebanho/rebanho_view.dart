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
        title: Obx(() {
          final isSelecting = controller.selectedHerds.isNotEmpty;
          return Text(
            isSelecting ? "${controller.selectedHerds.length} selecionados" : 'Meus Rebanhos',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        leading: IconButton(
          icon: Obx(() => Icon(controller.selectedHerds.isNotEmpty ? Icons.close : Icons.arrow_back, color: Colors.white)),
          onPressed: () {
            if (controller.selectedHerds.isNotEmpty) {
              controller.clearSelection();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          Obx(() => controller.selectedHerds.isNotEmpty 
            ? Row(
                children: [
                  Checkbox(
                    value: controller.isAllSelected,
                    onChanged: (val) => controller.toggleSelectAll(),
                    activeColor: Colors.white,
                    checkColor: Colors.red[800],
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _showDeleteConfirmation(),
                  ),
                ],
              )
            : const SizedBox.shrink()),
        ],
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
      body: Column(
        children: [
          // BARRA DE PESQUISA E FILTROS SEMPRE VISÍVEIS
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => controller.searchText.value = v,
                  decoration: InputDecoration(
                    hintText: "Buscar rebanho por nome ou galpão...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Todos", "Extensivo", "Semiextensivo", "Intensivo"].map((f) {
                      return Obx(() {
                        bool isSelected = controller.selectedFilter.value == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            selected: isSelected,
                            onSelected: (val) => controller.selectedFilter.value = f,
                            selectedColor: Colors.green[800],
                            backgroundColor: Colors.grey[200],
                            checkmarkColor: Colors.white,
                            shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildRebanhoList(category: 'Bovino', labelPlural: 'Bovinos', icon: FontAwesomeIcons.cow),
                _buildRebanhoList(category: 'Ovino', labelPlural: 'Ovinos', icon: Icons.pets),
                _buildRebanhoList(category: 'Caprino', labelPlural: 'Caprinos', icon: Icons.agriculture),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() => controller.selectedHerds.isEmpty 
        ? FloatingActionButton(
            onPressed: () => Get.toNamed('/cadastro-rebanho', arguments: controller.currentCategory),
            backgroundColor: Colors.green[800],
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink()),
    );
  }

  Widget _buildRebanhoList({required String category, required String labelPlural, required dynamic icon}) {
    return Obx(() {
      // Forçamos a escuta das variáveis que mudam a lista
      final searchText = controller.searchText.value;
      final filter = controller.selectedFilter.value;
      final page = controller.currentPage.value;
      
      // Pegamos a lista específica da categoria para evitar que uma aba interfira na outra
      List<Map<String, dynamic>> fullList;
      if (category == 'Bovino') fullList = controller.filteredBovinos;
      else if (category == 'Ovino') fullList = controller.filteredOvinos;
      else fullList = controller.filteredCaprinos;

      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

      if (fullList.isEmpty) {
        return _buildEmptyState(labelPlural, icon, category);
      }

      // Paginação manual local para garantir que cada aba tenha sua view
      int start = (page - 1) * controller.pageSize;
      int end = start + controller.pageSize;
      final paginatedList = fullList.sublist(start, end > fullList.length ? fullList.length : end);

      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paginatedList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final herd = paginatedList[index];
                return _buildHerdCard(herd, icon);
              },
            ),
          ),
          if (fullList.length > controller.pageSize)
            _buildPaginationControls(fullList.length),
        ],
      );
    });
  }

  Widget _buildHerdCard(Map<String, dynamic> herd, dynamic icon) {
    final int herdId = herd['id'];
    return Obx(() {
      final isSelected = controller.selectedHerds.contains(herdId);
      final isSelecting = controller.selectedHerds.isNotEmpty;

      return GestureDetector(
        onLongPress: () => controller.toggleSelection(herdId),
        onTap: () => isSelecting ? controller.toggleSelection(herdId) : Get.toNamed('/detalhes-rebanho', arguments: herd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[200]!, width: isSelected ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                    child: icon is IconData ? Icon(icon, color: Colors.green[800]) : FaIcon(icon, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(herd['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (herd['location'] != null) Text(herd['location'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isSelecting) Icon(isSelected ? Icons.check_circle : Icons.radio_button_off, color: Colors.green[800]),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(Icons.pets, "${herd['total_animals'] ?? 0}", "Animais"),
                  _buildStatItem(Icons.pregnant_woman, "${herd['pregnant_females'] ?? 0}", "Prenhes"),
                  _buildStatItem(Icons.monitor_weight, "${(herd['avg_ecc'] ?? 0.0).toStringAsFixed(1)}", "ECC Médio"),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPaginationControls(int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("${controller.currentRangeStart}–${controller.currentRangeEnd} de $total", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: controller.currentPage.value > 1 ? controller.previousPage : null),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: controller.currentPage.value * controller.pageSize < total ? controller.nextPage : null),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String label, dynamic icon, String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon is IconData ? icon : Icons.pets, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Nenhum rebanho de $label", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.toNamed('/cadastro-rebanho', arguments: category),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text("Cadastrar agora", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Obx(() => Text("Excluir ${controller.selectedHerds.length} rebanhos?")),
          ],
        ),
        content: const Text("Esta ação é irreversível. Todos os animais e registros vinculados a estes rebanhos serão apagados permanentemente."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSelectedHerds();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("SIM, EXCLUIR TUDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
