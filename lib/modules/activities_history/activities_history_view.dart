import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'activities_history_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActivitiesHistoryView extends StatelessWidget {
  final ActivitiesHistoryController controller = Get.put(ActivitiesHistoryController());

  InputDecoration _inputDecoration({IconData? prefixIcon, String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.green[800], size: 20) : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

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
          "Manejo e Atividades", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Get.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
          )
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.green[800],
          labelColor: Colors.green[800],
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Bovinos'),
            Tab(text: 'Ovinos'),
            Tab(text: 'Caprinos'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // BARRA DE BUSCA E FILTROS
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: context.theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => controller.searchText.value = v,
                  decoration: _inputDecoration(prefixIcon: Icons.search, hintText: "Buscar por brinco, nome ou tipo..."),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Todos", "Nutrição", "Reprodução", "Saúde"].map((cat) {
                      return Obx(() {
                        bool isSelected = controller.selectedCategory.value == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            selected: isSelected,
                            onSelected: (val) => controller.selectedCategory.value = cat,
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
                _buildEventList(controller.bovinoEvents),
                _buildEventList(controller.ovinoEvents),
                _buildEventList(controller.caprinoEvents),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(RxList<Map<String, dynamic>> events) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (events.isEmpty) {
        bool isSearching = controller.searchText.value.isNotEmpty || controller.selectedCategory.value != "Todos";
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSearching ? Icons.search_off : Icons.history_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                isSearching ? "Nenhuma atividade encontrada para esta busca" : "Nenhuma atividade registrada", 
                style: const TextStyle(color: Colors.grey)
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];
          return GestureDetector(
            onTap: () => Get.toNamed('/activity-details', arguments: e),
            child: _buildTimelineItem(e, index == events.length - 1),
          );
        },
      );
    });
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isLast) {
    final type = event['type']?.toString() ?? "";
    final color = _getColorByType(type);
    final icon = _getIconByType(type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey[200]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20, right: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(event['date'])),
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type, 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event['animal_id'] != null)
                    Text(
                      "Animal: ${event['identifier']} (${event['animal_name'] ?? 'S/N'})",
                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  _buildEventSpecificSummary(event),
                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event['description'], 
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSpecificSummary(Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? "";
    String summary = "";

    if (type == "Pesagem e Escore") {
      summary = "Peso: ${e['text_value_1'] ?? '0'}kg → ${e['value_1'] ?? '0'}kg | ECC: ${e['value_2'] ?? '3.0'}";
    } else if (type == "Produção de Leite") {
      summary = "Produção: ${e['value_1'] ?? '0'}L";
    } else if (type == "Vacinação") {
      summary = "Vacina: ${e['text_value_1'] ?? 'N/A'}";
    } else if (type == "Medicamento") {
      summary = "Medicamento: ${e['text_value_1'] ?? 'N/A'}";
    } else if (type == "Diagnóstico de Toque") {
      summary = "Resultado: ${e['text_value_1'] ?? 'N/A'}";
    } else if (type == "Inseminação Artificial") {
      summary = "Tipo: ${e['text_value_1'] ?? 'IA'}";
      if (e['text_value_1'] == "Monta") summary += " | Macho: ${e['text_value_2'] ?? 'N/A'}";
    }

    if (summary.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(summary, style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _getColorByType(String type) {
    if (type.contains("Inseminação")) return Colors.pink;
    if (type.contains("Pesagem")) return Colors.blue;
    if (type.contains("Nascimento")) return Colors.orange;
    if (type.contains("Vacinação")) return Colors.red;
    if (type.contains("Medicamento")) return Colors.deepOrange;
    if (type.contains("Leite")) return Colors.teal;
    if (type.contains("Casqueamento")) return Colors.brown;
    if (type.contains("Tosquia")) return Colors.blueGrey;
    return Colors.grey;
  }

  IconData _getIconByType(String type) {
    if (type.contains("Inseminação")) return Icons.favorite_border;
    if (type.contains("Pesagem")) return Icons.scale_outlined;
    if (type.contains("Nascimento")) return Icons.child_care;
    if (type.contains("Vacinação")) return Icons.vaccines_outlined;
    if (type.contains("Medicamento")) return Icons.medication_outlined;
    if (type.contains("Leite")) return Icons.opacity;
    if (type.contains("Casqueamento")) return Icons.cleaning_services;
    if (type.contains("Tosquia")) return Icons.content_cut;
    if (type.contains("Toque")) return Icons.search;
    return Icons.event_note;
  }
}

