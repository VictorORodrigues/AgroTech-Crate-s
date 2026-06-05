import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';

class ActivitiesHistoryController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  var isLoading = false.obs;

  var bovinoEvents = <Map<String, dynamic>>[].obs;
  var ovinoEvents = <Map<String, dynamic>>[].obs;
  var caprinoEvents = <Map<String, dynamic>>[].obs;

  var searchText = "".obs;
  var selectedCategory = "Todos".obs; // Todos, Nutrição, Reprodução, Saúde

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    loadAllEvents();
    
    debounce(searchText, (_) => loadAllEvents(), time: const Duration(milliseconds: 300));
    ever(selectedCategory, (_) => loadAllEvents());
  }

  Future<void> loadAllEvents() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      
      String queryBase = '''
        SELECT ae.*, a.identifier, a.name as animal_name,
               COALESCE(h_animal.name, h_event.name) as herd_name,
               COALESCE(h_animal.category, h_event.category) as category
        FROM animal_events ae
        LEFT JOIN animals a ON ae.animal_id = a.id
        LEFT JOIN herds h_animal ON a.herd_id = h_animal.id
        LEFT JOIN herds h_event ON ae.herd_id = h_event.id
      ''';
      
      List<String> conditions = [];
      List<dynamic> args = [];
      
      if (searchText.value.isNotEmpty) {
        conditions.add("(a.identifier LIKE ? OR a.name LIKE ? OR ae.type LIKE ? OR h.name LIKE ? OR a.breed_name LIKE ?)");
        String search = "%${searchText.value}%";
        args.addAll([search, search, search, search, search]);
      }

      if (selectedCategory.value != "Todos") {
        List<String> types = [];
        if (selectedCategory.value == "Nutrição") {
          types = ["Pesagem e Escore", "Produção de Leite"];
        } else if (selectedCategory.value == "Reprodução") {
          types = ["Inseminação Artificial", "Nascimento", "Aborto / Perda Gestacional", "Diagnóstico de Toque"];
        } else if (selectedCategory.value == "Saúde") {
          types = ["Vacinação", "Medicamento", "Casqueamento", "Tosquia"];
        }
        
        if (types.isNotEmpty) {
          String placeholders = List.filled(types.length, "?").join(",");
          conditions.add("ae.type IN ($placeholders)");
          args.addAll(types);
        }
      }

      String whereClause = conditions.isNotEmpty ? " WHERE ${conditions.join(" AND ")}" : "";

      final allEvents = await db.rawQuery(queryBase + whereClause + " ORDER BY ae.date DESC", args);
      
      bovinoEvents.value = allEvents.where((e) => e['category'] == 'Bovino').toList();
      ovinoEvents.value = allEvents.where((e) => e['category'] == 'Ovino').toList();
      caprinoEvents.value = allEvents.where((e) => e['category'] == 'Caprino').toList();
      
    } catch (e) {
      print("Erro ao carregar eventos: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
