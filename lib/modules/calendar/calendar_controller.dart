import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../database/database_helper.dart';

class CalendarController extends GetxController {
  var calendarFormat = CalendarFormat.month.obs;
  var focusedDay = DateTime.now().obs;
  var selectedDay = DateTime.now().obs;
  
  // Estados de visibilidade dos seletores
  var isMonthPickerVisible = false.obs;
  var isYearPickerVisible = false.obs;
  
  var isLoading = false.obs;
  var allEvents = <Map<String, dynamic>>[].obs;
  var selectedFilter = "Todos".obs; // Todos, Nutrição, Reprodução, Saúde
  var selectedSpeciesFilter = "Todas".obs; // Todas, Bovino, Ovino, Caprino

  // Feriados Nacionais e Estaduais (CE)
  final Map<String, String> holidays = {
    "01-01": "Confraternização Universal",
    "03-19": "São José (Padroeiro do CE)",
    "03-25": "Data Magna do Ceará",
    "04-21": "Tiradentes",
    "05-01": "Dia do Trabalho",
    "09-07": "Independência do Brasil",
    "10-12": "Nossa Senhora Aparecida",
    "11-02": "Finados",
    "11-15": "Proclamação da República",
    "11-20": "Dia de Zumbi e da Consciência Negra",
    "12-25": "Natal",
  };

  // Feriados Móveis 2024-2026
  final Map<String, String> mobileHolidays = {
    "2024-02-13": "Carnaval",
    "2024-03-29": "Sexta-feira Santa",
    "2024-05-30": "Corpus Christi",
    "2025-03-04": "Carnaval",
    "2025-04-18": "Sexta-feira Santa",
    "2025-06-19": "Corpus Christi",
    "2026-02-17": "Carnaval",
    "2026-04-03": "Sexta-feira Santa",
    "2026-06-04": "Corpus Christi",
  };

  String? getHoliday(DateTime day) {
    String fixedKey = DateFormat('MM-dd').format(day);
    String mobileKey = DateFormat('yyyy-MM-dd').format(day);
    return holidays[fixedKey] ?? mobileHolidays[mobileKey];
  }

  final List<String> months = [
    "jan.", "fev.", "mar.", "abr.", "mai.", "jun.", 
    "jul.", "ago.", "set.", "out.", "nov.", "dez."
  ];

  // Campos para Nova Tarefa/Evento
  var taskTitle = "".obs;
  var isTask = true.obs; // true = Tarefa, false = Evento
  var isAllDay = false.obs;
  var taskDate = DateTime.now().obs;
  var taskTime = TimeOfDay.now().obs;
  var repetition = "Não se repete".obs;
  var taskDetails = "".obs;
  var selectedTaskColor = Colors.green[800]!.obs;

  final List<Color> taskColors = [
    const Color(0xFF2E7D32), // Verde Escuro
    const Color(0xFF1976D2), // Azul
    const Color(0xFFD32F2F), // Vermelho
    const Color(0xFFFBC02D), // Amarelo
    const Color(0xFF7B1FA2), // Roxo
    const Color(0xFF0097A7), // Ciano
    const Color(0xFFE64A19), // Laranja
    const Color(0xFF5D4037), // Marrom
    const Color(0xFF455A64), // Cinza Azulado
    const Color(0xFFC2185B), // Rosa
  ];

  // Estado para expansão dinâmica do calendário baseado no arraste das tarefas
  var currentSheetSize = 0.4.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  void toggleMonthPicker() {
    isMonthPickerVisible.value = !isMonthPickerVisible.value;
    isYearPickerVisible.value = false;
  }

  void toggleYearPicker() {
    isYearPickerVisible.value = !isYearPickerVisible.value;
    isMonthPickerVisible.value = false;
  }

  void selectMonth(int monthIndex) {
    focusedDay.value = DateTime(focusedDay.value.year, monthIndex + 1, focusedDay.value.day);
    isMonthPickerVisible.value = false;
  }

  void selectYear(int year) {
    focusedDay.value = DateTime(year, focusedDay.value.month, focusedDay.value.day);
    isYearPickerVisible.value = false;
  }

  Future<void> saveTask() async {
    if (taskTitle.value.isEmpty) return;

    try {
      final db = await DatabaseHelper.instance.database;
      
      DateTime finalDate = DateTime(
        taskDate.value.year,
        taskDate.value.month,
        taskDate.value.day,
        isAllDay.value ? 0 : taskTime.value.hour,
        isAllDay.value ? 0 : taskTime.value.minute,
      );

      await db.insert('animal_events', {
        'animal_id': null, // Tarefas genéricas não precisam de animal
        'type': taskTitle.value,
        'date': finalDate.toIso8601String(),
        'description': taskDetails.value,
        'is_task': isTask.value ? 1 : 0,
        'is_all_day': isAllDay.value ? 1 : 0,
        'color_hex': selectedTaskColor.value.value.toRadixString(16),
      });

      await loadEvents();
      Get.back();
      
      // Limpar campos
      taskTitle.value = "";
      taskDetails.value = "";
      isAllDay.value = false;
    } catch (e) {
      print("Erro ao salvar tarefa: $e");
    }
  }

  Future<void> loadEvents() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      
      final results = await db.rawQuery('''
        SELECT ae.*, a.identifier, a.name as animal_name, h.category, h.name as herd_name
        FROM animal_events ae
        LEFT JOIN animals a ON ae.animal_id = a.id
        LEFT JOIN herds h ON a.herd_id = h.id
      ''');
      allEvents.value = results;
    } catch (e) {
      print("Erro ao carregar eventos para o calendário: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    // 1. Filtra por data
    var events = allEvents.where((e) {
      final date = DateTime.parse(e['date']);
      return date.year == day.year && date.month == day.month && date.day == day.day;
    }).toList();

    // 2. Filtra por categoria técnica
    if (selectedFilter.value != "Todos") {
      events = events.where((e) {
        final type = e['type'].toString();
        if (selectedFilter.value == "Nutrição") {
          return type == "Pesagem e Escore" || type == "Produção de Leite";
        }
        if (selectedFilter.value == "Reprodução") {
          return type == "Inseminação Artificial" || type == "Nascimento" || 
                 type == "Diagnóstico de Toque" || type == "Aborto / Perda Gestacional";
        }
        if (selectedFilter.value == "Saúde") {
          return type == "Vacinação" || type == "Medicamento";
        }
        return true;
      }).toList();
    }

    // 3. Filtra por espécie
    if (selectedSpeciesFilter.value != "Todas") {
      events = events.where((e) {
        // Para tarefas genéricas (animal_id = null), podemos decidir se mostramos ou não.
        // Geralmente mostramos em "Todas" e filtramos quando uma espécie específica é pedida.
        if (e['animal_id'] == null) return false; 
        return e['category'] == selectedSpeciesFilter.value;
      }).toList();
    }

    // 4. Ordena por hora crescente
    events.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateA.compareTo(dateB);
    });

    return events;
  }
}
