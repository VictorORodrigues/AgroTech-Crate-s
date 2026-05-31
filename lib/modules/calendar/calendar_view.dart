import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_controller.dart';

class CalendarView extends StatelessWidget {
  final CalendarController controller = Get.put(CalendarController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final Color secondaryBg = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => controller.toggleMonthPicker(),
              child: Obx(() => Text(
                DateFormat('MMMM', 'pt_BR').format(controller.focusedDay.value).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => controller.toggleYearPicker(),
              child: Obx(() => Text(
                controller.focusedDay.value.year.toString(),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
              )),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Get.toNamed('/calendar-search'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              controller.focusedDay.value = DateTime.now();
              controller.selectedDay.value = DateTime.now();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Grade do Calendário (Fica no fundo)
          Column(
            children: [
              Obx(() {
                if (controller.isMonthPickerVisible.value) {
                  return _buildMonthPicker(backgroundColor, textColor, isDark);
                }
                if (controller.isYearPickerVisible.value) {
                  return _buildYearPicker(backgroundColor, textColor, isDark);
                }
                return const SizedBox.shrink();
              }),
              
              // Filtros Técnicos e de Espécie (Linha Única)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Categorias de Manejo
                      ...["Todos", "Nutrição", "Reprodução", "Saúde"].map((filter) {
                        return Obx(() {
                          bool isSelected = controller.selectedFilter.value == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter, style: TextStyle(
                                color: isSelected ? Colors.white : textColor.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              )),
                              selected: isSelected,
                              onSelected: (val) => controller.selectedFilter.value = filter,
                              selectedColor: Colors.green[800],
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              checkmarkColor: Colors.white,
                              shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                            ),
                          );
                        });
                      }),
                      // Divisor vertical sutil
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(width: 1, height: 20, color: textColor.withOpacity(0.1)),
                      ),
                      // Categorias de Espécie
                      ...["Todas", "Bovino", "Ovino", "Caprino"].map((species) {
                        return Obx(() {
                          bool isSelected = controller.selectedSpeciesFilter.value == species;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(species, style: TextStyle(
                                color: isSelected ? Colors.white : textColor.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              )),
                              selected: isSelected,
                              onSelected: (val) => controller.selectedSpeciesFilter.value = species,
                              selectedColor: Colors.orange[800],
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              checkmarkColor: Colors.white,
                              shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.orange[800]! : Colors.transparent)),
                            ),
                          );
                        });
                      }),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Obx(() {
                  // Sincronização reativa total: observa filtros e mudanças na lista de eventos
                  final _ = controller.selectedFilter.value;
                  final __ = controller.selectedSpeciesFilter.value;
                  final ___ = controller.allEvents.length;

                  double totalAvailable = Get.height - kToolbarHeight - 150;
                  double dynamicRowHeight = (totalAvailable * (1 - controller.currentSheetSize.value)) / 6;
                  if (dynamicRowHeight < 35) dynamicRowHeight = 35;
                  if (dynamicRowHeight > 100) dynamicRowHeight = 100;

                  return TableCalendar(
                    locale: 'pt_BR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: controller.focusedDay.value,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    headerVisible: false,
                    daysOfWeekHeight: 35,
                    rowHeight: dynamicRowHeight,
                    
                    selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      controller.selectedDay.value = selectedDay;
                      controller.focusedDay.value = focusedDay;
                    },
                    onPageChanged: (focusedDay) {
                      controller.focusedDay.value = focusedDay;
                    },

                    eventLoader: (day) => controller.getEventsForDay(day),

                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        final text = DateFormat.E('pt_BR').format(day)[0].toUpperCase();
                        return Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: day.weekday == DateTime.sunday ? Colors.redAccent : textColor.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, textColor, isSelected: false, isDark: isDark),
                      todayBuilder: (context, day, focusedDay) => _buildDayCell(day, textColor, isToday: true, isSelected: false, isDark: isDark),
                      selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, textColor, isSelected: true, isDark: isDark),
                      outsideBuilder: (context, day, focusedDay) => _buildDayCell(day, textColor.withOpacity(0.24), isSelected: false, isDark: isDark),
                      markerBuilder: (context, day, events) {
                        final holiday = controller.getHoliday(day);
                        return _buildDotsWithHoliday(events as List<Map<String, dynamic>>, holiday);
                      },
                    ),
                    
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      tableBorder: TableBorder(
                        horizontalInside: BorderSide(color: borderColor, width: 0.5),
                        verticalInside: BorderSide(color: borderColor, width: 0.5),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          // DraggableScrollableSheet para as Tarefas
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              controller.currentSheetSize.value = notification.extent;
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.35, // Aumentado para restringir o arraste para baixo
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: secondaryBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      Expanded(
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Obx(() => Text(
                                      "${controller.selectedDay.value.day} ${DateFormat('EEE.', 'pt_BR').format(controller.selectedDay.value).toUpperCase()}",
                                      style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                            Obx(() {
                              final events = controller.getEventsForDay(controller.selectedDay.value);
                              if (events.isEmpty) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Text(
                                      "Nenhuma tarefa para hoje!", 
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : Colors.grey[800], 
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final e = events[index];
                                    final color = _getColorByType(e['type'], hex: e['color_hex']);
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                      child: InkWell(
                                        onTap: () => Get.toNamed('/activity-details', arguments: e),
                                        child: Row(
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              e['is_all_day'] == 1 
                                                  ? "Todo dia" 
                                                  : DateFormat('HH:mm').format(DateTime.parse(e['date'])),
                                              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                                            ),
                                          ),
                                          Container(
                                            width: 35,
                                            height: 35,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(_getIconByType(e['type']), color: color, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(e['type'], style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                                                if (e['animal_id'] != null)
                                                  Text("Animal: ${e['identifier']} - ${e['herd_name']}", 
                                                    style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      ),
                                    );
                                  },
                                  childCount: events.length,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // Barra de input rápido integrada ao DraggableSheet
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Center(
                                  child: Obx(() => TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                      hintText: "Adic. evento em ${controller.selectedDay.value.day} de ${DateFormat('MMM.', 'pt_BR').format(controller.selectedDay.value)}",
                                      hintStyle: TextStyle(color: textColor.withOpacity(0.3), fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  )),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              onPressed: () => Get.toNamed('/add-activity', arguments: {'selectedDate': controller.selectedDay.value}),
                              backgroundColor: textColor.withOpacity(0.05),
                              elevation: 0,
                              mini: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: borderColor),
                              ),
                              child: Icon(Icons.add, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-activity', arguments: {'selectedDate': controller.selectedDay.value}),
        backgroundColor: textColor.withOpacity(0.05),
        elevation: 0,
        mini: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: Icon(Icons.add, color: textColor),
      ),
    );
  }

  Widget _buildMonthPicker(Color bg, Color text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: bg,
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isSelected = controller.focusedDay.value.month == (index + 1);
          return GestureDetector(
            onTap: () => controller.selectMonth(index),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green[800] : Colors.transparent,
                border: Border.all(color: isSelected ? Colors.green[800]! : (isDark ? Colors.white24 : Colors.black12)),
              ),
              child: Center(
                child: Text(
                  controller.months[index],
                  style: TextStyle(color: isSelected ? Colors.white : text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPicker(Color bg, Color text, bool isDark) {
    final currentYear = DateTime.now().year;
    final years = List.generate(12, (index) => currentYear - 5 + index);
    return Container(
      padding: const EdgeInsets.all(16),
      color: bg,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_left, color: text.withOpacity(0.5)),
              Text("${years.first} - ${years.last}", style: TextStyle(color: text, fontWeight: FontWeight.bold)),
              Icon(Icons.arrow_drop_up, color: text),
              Icon(Icons.arrow_right, color: text.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = controller.focusedDay.value.year == year;
              return GestureDetector(
                onTap: () => controller.selectYear(year),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.green[800] : Colors.transparent,
                    border: Border.all(color: isSelected ? Colors.green[800]! : (isDark ? Colors.white24 : Colors.black12)),
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(color: isSelected ? Colors.white : text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, Color textColor, {bool isToday = false, required bool isSelected, required bool isDark}) {
    final isSunday = day.weekday == DateTime.sunday;
    return Container(
      decoration: BoxDecoration(
        border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.green[800]!, width: 2) : null,
      ),
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Text(
            day.day.toString(),
            style: TextStyle(
              color: isSunday ? Colors.redAccent : (isToday ? Colors.redAccent : textColor),
              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsWithHoliday(List<Map<String, dynamic>> events, String? holiday) {
    return Positioned(
      bottom: 4,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (holiday != null)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                holiday,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.redAccent, fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
          if (events.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              children: events.take(3).map((e) {
                final color = _getColorByType(e['type'], hex: e['color_hex']);
                return Icon(_getIconByType(e['type']), size: 8, color: color);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDots(List<Map<String, dynamic>> events) {
    return Positioned(
      bottom: 4,
      left: 0,
      right: 0,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        children: events.take(3).map((e) {
          final color = _getColorByType(e['type'], hex: e['color_hex']);
          return Icon(_getIconByType(e['type']), size: 10, color: color);
        }).toList(),
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
    return Icons.event_note;
  }

  Color _getColorByType(String type, {String? hex}) {
    if (hex != null && hex.isNotEmpty) {
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (e) {}
    }
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
