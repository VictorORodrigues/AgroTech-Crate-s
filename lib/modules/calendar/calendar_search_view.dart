import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'calendar_controller.dart';

class CalendarSearchView extends StatelessWidget {
  final CalendarController controller = Get.find<CalendarController>();
  final RxString query = "".obs;
  
  // Novos filtros para pesquisa
  final RxString typeFilter = "Todos".obs; // Todos, Nutrição, Reprodução, Saúde
  final RxString speciesFilter = "Todas".obs; // Todas, Bovino, Ovino, Caprino

  CalendarSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          autofocus: true,
          onChanged: (v) => query.value = v,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Pesquisar eventos e tarefas",
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            border: InputBorder.none,
          ),
        ),
        actions: [
          Obx(() => query.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => query.value = "",
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros na Pesquisa
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...["Todos", "Nutrição", "Reprodução", "Saúde"].map((f) => Obx(() {
                    bool isSelected = typeFilter.value == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : textColor.withOpacity(0.7))),
                        selected: isSelected,
                        onSelected: (_) => typeFilter.value = f,
                        selectedColor: Colors.green[800],
                        checkmarkColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                      ),
                    );
                  })),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(width: 1, height: 20, color: textColor.withOpacity(0.1)),
                  ),
                  ...["Todas", "Bovino", "Ovino", "Caprino"].map((s) => Obx(() {
                    bool isSelected = speciesFilter.value == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : textColor.withOpacity(0.7))),
                        selected: isSelected,
                        onSelected: (_) => speciesFilter.value = s,
                        selectedColor: Colors.orange[800],
                        checkmarkColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.orange[800]! : Colors.transparent)),
                      ),
                    );
                  })),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (query.value.isEmpty && typeFilter.value == "Todos" && speciesFilter.value == "Todas") {
                return Center(
                  child: Text(
                    "Digite ou use os filtros para pesquisar",
                    style: TextStyle(color: textColor.withOpacity(0.5)),
                  ),
                );
              }

              var filteredEvents = controller.allEvents.where((e) {
                final type = e['type'].toString().toLowerCase();
                final desc = (e['description'] ?? "").toString().toLowerCase();
                final animalName = (e['animal_name'] ?? "").toString().toLowerCase();
                final identifier = (e['identifier'] ?? "").toString().toLowerCase();
                final breed = (e['breed_name'] ?? "").toString().toLowerCase();
                final q = query.value.toLowerCase();
                
                bool matchesQuery = query.value.isEmpty || 
                       type.contains(q) || 
                       desc.contains(q) || 
                       animalName.contains(q) || 
                       identifier.contains(q) || 
                       breed.contains(q);

                bool matchesType = true;
                if (typeFilter.value != "Todos") {
                   final t = e['type'].toString();
                   if (typeFilter.value == "Nutrição") matchesType = (t == "Pesagem e Escore" || t == "Produção de Leite");
                   else if (typeFilter.value == "Reprodução") matchesType = (t == "Inseminação Artificial" || t == "Nascimento" || t == "Diagnóstico de Toque" || t == "Aborto / Perda Gestacional");
                   else if (typeFilter.value == "Saúde") matchesType = (t == "Vacinação" || t == "Medicamento" || t == "Casqueamento" || t == "Tosquia");
                }

                bool matchesSpecies = true;
                if (speciesFilter.value != "Todas") {
                  matchesSpecies = e['animal_id'] != null && e['category'] == speciesFilter.value;
                }

                return matchesQuery && matchesType && matchesSpecies;
              }).toList();

              if (filteredEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: textColor.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "Nenhuma tarefa ou evento encontrado",
                        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              Map<String, List<Map<String, dynamic>>> grouped = {};
              for (var e in filteredEvents) {
                final date = DateTime.parse(e['date']);
                final key = DateFormat('EEE., d MMM.', 'pt_BR').format(date);
                if (!grouped.containsKey(key)) grouped[key] = [];
                grouped[key]!.add(e);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final dateKey = grouped.keys.elementAt(index);
                  final dayEvents = grouped[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Text(
                          dateKey,
                          style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1C1E) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: dayEvents.map((e) {
                            final isAllDay = e['is_all_day'] == 1;
                            final color = e['color_hex'] != null 
                                ? Color(int.parse(e['color_hex'], radix: 16))
                                : _getLegacyColor(e['type']);
                            
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(_getIconByType(e['type']), color: color, size: 20),
                              ),
                              title: Text(
                                e['type'],
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAllDay ? "Todo o dia" : DateFormat('HH:mm').format(DateTime.parse(e['date'])),
                                    style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11),
                                  ),
                                  if (e['animal_id'] != null)
                                    Text(
                                      "${e['identifier']} (${e['category']})",
                                      style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              onTap: () => Get.toNamed('/activity-details', arguments: e),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
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

  Color _getLegacyColor(String type) {
    if (type.contains("Inseminação")) return Colors.pinkAccent;
    if (type.contains("Pesagem")) return Colors.blueAccent;
    if (type.contains("Nascimento")) return Colors.orangeAccent;
    if (type.contains("Vacinação")) return Colors.redAccent;
    if (type.contains("Medicamento")) return Colors.deepOrangeAccent;
    if (type.contains("Leite")) return Colors.tealAccent;
    if (type.contains("Casqueamento")) return Colors.brown;
    if (type.contains("Tosquia")) return Colors.blueGrey;
    return Colors.greenAccent;
  }
}
