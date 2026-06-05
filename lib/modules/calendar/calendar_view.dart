import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../database/database_helper.dart';
import 'calendar_controller.dart';
import '../navigation/navigation_controller.dart';

class CalendarView extends StatelessWidget {
  final CalendarController controller = Get.put(CalendarController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final Color secondaryBg = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color borderColor = isDark ? Colors.white10 : Colors.black12;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => controller.toggleMonthPicker(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Obx(() => Text(
                            DateFormat('MMMM', 'pt_BR').format(controller.focusedDay.value).toUpperCase(),
                            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        Icon(Icons.arrow_drop_down, color: textColor.withOpacity(0.5), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.toggleYearPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Text(
                        controller.focusedDay.value.year.toString(),
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                      )),
                      Icon(Icons.unfold_more, color: textColor.withOpacity(0.3), size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: textColor.withOpacity(0.7)),
              onPressed: () => Get.toNamed('/calendar-search'),
            ),
          ],
        ),
        body: Stack(
          children: [
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
                
                // CALENDÁRIO COM ALTURA DINÂMICA (IA ELASTIC)
                Obx(() {
                  final extent = controller.currentSheetSize.value;
                  // Calculamos a altura disponível subtraindo a aba de tarefas
                  // Get.height (tela) - AppBar - Padding - Espaço da Aba
                  double availableHeight = Get.height - kToolbarHeight - Get.mediaQuery.padding.top - 20;
                  double dynamicHeight = availableHeight * (1 - extent);

                  return SizedBox(
                    height: dynamicHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TableCalendar(
                        locale: 'pt_BR',
                        firstDay: DateTime.utc(controller.minYear, 1, 1),
                        lastDay: DateTime.utc(controller.maxYear, 12, 31),
                        focusedDay: controller.focusedDay.value,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        headerVisible: false,
                        daysOfWeekHeight: 30,
                        shouldFillViewport: true, // Crucial para esticar as células
                        
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
                      ),
                    ),
                  );
                }),
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
                minChildSize: 0.35,
                maxChildSize: 0.95,
                snap: true,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: secondaryBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        // HEADER ONDE O ARRASTE É PERMITIDO
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          controller: scrollController,
                          child: Container(
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40, height: 4,
                                  decoration: BoxDecoration(color: textColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                  child: Obx(() {
                                    final date = controller.selectedDay.value;
                                    final holiday = controller.getHoliday(date);
                                    final bool isSelecting = controller.selectedEventIds.isNotEmpty;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isSelecting 
                                                  ? "${controller.selectedEventIds.length} selecionados"
                                                  : DateFormat('EEEE, dd \'de\' MMMM', 'pt_BR').format(date).capitalizeFirst!,
                                                style: TextStyle(
                                                  color: isSelecting ? Colors.green[800] : textColor, 
                                                  fontSize: 18, 
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              if (holiday != null && !isSelecting)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(holiday, style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green[800], fontSize: 14, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelecting)
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.grey),
                                                onPressed: () => controller.clearSelection(),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () => _confirmBulkDelete(),
                                              ),
                                            ],
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                                const TabBar(
                                  labelColor: Colors.green,
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: Colors.green,
                                  tabs: [
                                    Tab(text: "Manejo"),
                                    Tab(text: "Tarefas"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildTabList(null, true, textColor, isDark),
                              _buildTabList(null, false, textColor, isDark),
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
          onPressed: () => _showAddOptions(context),
          backgroundColor: Colors.green[800],
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildTabList(ScrollController? scrollController, bool isManejo, Color textColor, bool isDark) {
    return Obx(() {
      final allEventsForDay = controller.getEventsForDay(controller.selectedDay.value);
      
      List<Map<String, dynamic>> events;
      if (isManejo) {
        events = allEventsForDay.where((e) => e['is_task'] == 0 || e['is_task'] == null).toList();
      } else {
        events = allEventsForDay.where((e) => e['is_task'] == 1).toList();
      }
      
      final _ = controller.allEvents.length;

      if (events.isEmpty) {
        return Center(
          child: Text(
            isManejo ? "Nenhum manejo para hoje!" : "Nenhuma tarefa para hoje!", 
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400], 
              fontSize: 15, 
              fontWeight: FontWeight.w500
            ),
          ),
        );
      }

      // Se for Tarefas, vamos separar em seções: A Fazer e Concluídas
      if (!isManejo) {
        final pending = events.where((e) => e['text_value_1'] != 'Concluída').toList();
        final completed = events.where((e) => e['text_value_1'] == 'Concluída').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          children: [
            if (pending.isNotEmpty) ...[
              _buildSubHeader("A FAZER", Colors.grey[700]!),
              ...pending.map((e) => _buildEventItem(e, textColor, isManejo)),
            ],
            if (completed.isNotEmpty) ...[
              if (pending.isNotEmpty) const SizedBox(height: 24),
              _buildSubHeader("CONCLUÍDAS", Colors.grey[700]!),
              ...completed.map((e) => _buildEventItem(e, textColor, isManejo)),
            ],
          ],
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventItem(events[index], textColor, isManejo);
        },
      );
    });
  }

  Widget _buildSubHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> e, Color textColor, bool isManejo) {
    final color = _getColorByType(e['type'], hex: e['color_hex']);
    final bool isCompleted = e['text_value_1'] == 'Concluída';
    final int eventId = e['id'];

    return Obx(() {
      final isSelected = controller.selectedEventIds.contains(eventId);
      final bool isSelecting = controller.selectedEventIds.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onLongPress: () => controller.toggleEventSelection(eventId),
          onTap: () {
            if (isSelecting) {
              controller.toggleEventSelection(eventId);
            } else {
              Get.toNamed('/activity-details', arguments: e);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.green[800]! : Colors.grey[100]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_off,
                      color: isSelected ? Colors.green[800] : Colors.grey[300],
                    ),
                  )
                else if (!isManejo) 
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () async {
                        final db = await DatabaseHelper.instance.database;
                        final newStatus = isCompleted ? 'Pendente' : 'Concluída';
                        await db.update('animal_events', {'text_value_1': newStatus}, where: 'id = ?', whereArgs: [e['id']]);
                        controller.loadEvents();
                      },
                      child: Icon(
                        isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                
                SizedBox(
                  width: 55,
                  child: Text(
                    e['is_all_day'] == 1 
                        ? "Todo dia" 
                        : DateFormat('HH:mm').format(DateTime.parse(e['date'])),
                    style: TextStyle(
                      color: textColor.withOpacity(0.7), 
                      fontSize: 13,
                      decoration: (!isManejo && isCompleted) ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  width: 35, height: 35,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_getIconByType(e['type']), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['type'], 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCompleted && !isManejo ? textColor.withOpacity(0.4) : textColor, 
                          fontSize: 15, 
                          fontWeight: FontWeight.bold,
                          decoration: (!isManejo && isCompleted) ? TextDecoration.lineThrough : null,
                        )
                      ),
                      if (e['animal_id'] != null && e['identifier'] != null)
                        Text("Animal: ${e['identifier']} (${e['category'] ?? ''})", 
                          style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11)),
                      if (e['animal_id'] == null && (e['herd_name'] != null || e['herd_id'] != null))
                        Text("Rebanho: ${e['herd_name'] ?? 'Carregando...'}",
                          style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _confirmBulkDelete() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text("Excluir registros?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tem certeza que deseja remover ${controller.selectedEventIds.length} itens? \n\nAtividades técnicas de reprodução (Parto, Inseminação, Toque) terão seus desdobramentos e status biológicos revertidos automaticamente.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSelectedEvents();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("EXCLUIR TUDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("O que deseja registrar?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAddOption(
                    title: "Manejo",
                    subtitle: "Atividade Técnica",
                    icon: Icons.auto_graph_outlined,
                    color: Colors.green,
                    onTap: () {
                      Get.back();
                      Get.toNamed('/add-activity', arguments: {'selectedDate': controller.selectedDay.value});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAddOption(
                    title: "Tarefa",
                    subtitle: "Evento Pessoal",
                    icon: Icons.event_note_outlined,
                    color: Colors.blue,
                    onTap: () {
                      Get.back();
                      controller.taskDate.value = controller.selectedDay.value;
                      controller.taskTime.value = TimeOfDay.now();
                      _showAddTaskModal(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
          ],
        ),
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
    return Container(
      height: 280, // Altura fixa para acomodar o seletor
      padding: const EdgeInsets.all(16),
      color: bg,
      child: Obx(() {
        final startYear = controller.yearPickerStartYear.value;
        final years = List.generate(12, (index) => startYear + index);
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: text),
                  onPressed: () => controller.previousYearRange(),
                ),
                Text(
                  "${years.first} - ${years.last}",
                  style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: text),
                  onPressed: () => controller.nextYearRange(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    controller.previousYearRange();
                  } else if (details.primaryVelocity! < 0) {
                    controller.nextYearRange();
                  }
                },
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Scroll controlado pelo drag detection
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final isSelected = controller.focusedDay.value.year == year;
                    final isCurrentYear = DateTime.now().year == year;
                    
                    return GestureDetector(
                      onTap: () => controller.selectYear(year),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green[800] : (isCurrentYear ? Colors.green[800]!.withOpacity(0.1) : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.green[800]! : (isCurrentYear ? Colors.green[800]! : (isDark ? Colors.white12 : Colors.black12)),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isCurrentYear ? Colors.green[800] : text),
                              fontWeight: isSelected || isCurrentYear ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime day, Color textColor, {bool isToday = false, required bool isSelected, required bool isDark}) {
    final isSunday = day.weekday == DateTime.sunday;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? (isDark ? Colors.white12 : Colors.green[800]!.withOpacity(0.1)) : Colors.transparent,
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
                color: Colors.green[800]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                holiday,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.green[800], fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
          if (events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: events.take(4).map((e) {
                  final color = _getColorByType(e['type'], hex: e['color_hex']);
                  return Container(
                    height: 2,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }).toList(),
              ),
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
    if (type.contains("Toque")) return Icons.search; // Lupa para Diagnóstico de Toque
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
    if (type.contains("Leite")) return Colors.teal;
    if (type.contains("Casqueamento")) return Colors.brown;
    if (type.contains("Tosquia")) return Colors.blueGrey;
    return Colors.green[800]!;
  }

  void _showAddTaskModal(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nova Tarefa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) => controller.taskTitle.value = v,
                decoration: InputDecoration(
                  labelText: "Título da Tarefa",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text("Data e Hora", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: controller.taskDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) controller.taskDate.value = picked;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(() => Text(DateFormat('dd/MM/yyyy').format(controller.taskDate.value), style: const TextStyle(fontSize: 14))),
                            const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: controller.taskTime.value);
                        if (picked != null) controller.taskTime.value = picked;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(() => Text(controller.taskTime.value.format(context), style: const TextStyle(fontSize: 14))),
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                onChanged: (v) => controller.taskDetails.value = v,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Detalhes (Opcional)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Cor da Tarefa", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.taskColors.length,
                  itemBuilder: (context, index) {
                    final color = controller.taskColors[index];
                    return GestureDetector(
                      onTap: () => controller.selectedTaskColor.value = color,
                      child: Obx(() => Container(
                        width: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: controller.selectedTaskColor.value == color ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      )),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => controller.saveTask(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("SALVAR TAREFA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
