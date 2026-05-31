import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'calendar_controller.dart';

class CalendarSearchView extends StatelessWidget {
  final CalendarController controller = Get.find<CalendarController>();
  final RxString query = "".obs;

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
      body: Obx(() {
        if (query.value.isEmpty) {
          return Center(
            child: Text(
              "Digite para pesquisar",
              style: TextStyle(color: textColor.withOpacity(0.5)),
            ),
          );
        }

        final filteredEvents = controller.allEvents.where((e) {
          final type = e['type'].toString().toLowerCase();
          final desc = (e['description'] ?? "").toString().toLowerCase();
          final q = query.value.toLowerCase();
          return type.contains(q) || desc.contains(q);
        }).toList();

        if (filteredEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: textColor.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  "Nenhum resultado foi encontrado",
                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Agrupar por data
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
                        leading: Icon(
                          isAllDay ? Icons.calendar_today : Icons.access_time,
                          color: textColor.withOpacity(0.6),
                          size: 20,
                        ),
                        title: Row(
                          children: [
                            Container(width: 3, height: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e['type'],
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Text(
                            isAllDay ? "Todo o dia" : DateFormat('HH:mm').format(DateTime.parse(e['date'])),
                            style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12),
                          ),
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
    );
  }

  Color _getLegacyColor(String type) {
    if (type.contains("Inseminação")) return Colors.pinkAccent;
    if (type.contains("Pesagem")) return Colors.blueAccent;
    if (type.contains("Nascimento")) return Colors.orangeAccent;
    if (type.contains("Vacinação")) return Colors.redAccent;
    if (type.contains("Medicamento")) return Colors.deepOrangeAccent;
    if (type.contains("Leite")) return Colors.tealAccent;
    return Colors.greenAccent;
  }
}
