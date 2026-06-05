import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';

class RebanhoController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  
  var bovinos = <Map<String, dynamic>>[].obs;
  var ovinos = <Map<String, dynamic>>[].obs;
  var caprinos = <Map<String, dynamic>>[].obs;

  // Variáveis para Busca e Filtro
  var searchText = "".obs;
  var selectedFilter = "Todos".obs; // Todos, Extensivo, Semiextensivo, Intensivo

  // Paginação
  var currentPage = 1.obs;
  final int pageSize = 50;

  // Multi-seleção
  var selectedHerds = <int>{}.obs; // IDs dos rebanhos selecionados

  var isLoading = false.obs;
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTabIndex.value = tabController.index;
        currentPage.value = 1; // Reseta página ao mudar de aba
        clearSelection(); // Limpa seleção ao mudar de aba
      }
    });

    carregarRebanhos();
    _autoUpdateAnimalAges();
  }

  /// Atualiza automaticamente a idade de todos os animais
  Future<void> _autoUpdateAnimalAges() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final animals = await db.query('animals');
      final now = DateTime.now();

      for (var a in animals) {
        int currentAgeInDb = a['age_months'] as int? ?? 0;
        int calculatedAge = currentAgeInDb;

        if (a['birth_date'] != null) {
          // 1. Cálculo Baseado na Data de Nascimento Real
          DateTime birth = DateTime.parse(a['birth_date'].toString());
          calculatedAge = (now.year - birth.year) * 12 + now.month - birth.month;
          if (now.day < birth.day) calculatedAge--; 
        } else if (a['created_at'] != null) {
          // 2. Cálculo Baseado na Data de Registro + Idade Inicial
          DateTime created = DateTime.parse(a['created_at'].toString());
          int initialAge = a['initial_age_months'] as int? ?? currentAgeInDb;
          
          int monthsSinceCreation = (now.year - created.year) * 12 + now.month - created.month;
          if (now.day < created.day) monthsSinceCreation--;

          calculatedAge = initialAge + monthsSinceCreation;
        }

        if (calculatedAge < 0) calculatedAge = 0;
        
        // Só atualiza o banco se a idade mudou para economizar processamento
        if (calculatedAge != currentAgeInDb) {
          await db.update('animals', {'age_months': calculatedAge}, where: 'id = ?', whereArgs: [a['id']]);
        }
      }
      // O carregarRebanhos() no onInit já vai pegar os dados atualizados pois esta função é awaitada ou roda em paralelo
    } catch (e) {
      print("Erro ao atualizar idades: $e");
    }
  }

  // Métodos de Paginação
  List<Map<String, dynamic>> get paginatedHerds {
    final filtered = _getCurrentFilteredList();
    int start = (currentPage.value - 1) * pageSize;
    int end = start + pageSize;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get totalFilteredCount => _getCurrentFilteredList().length;

  int get currentRangeStart => totalFilteredCount == 0 ? 0 : (currentPage.value - 1) * pageSize + 1;
  int get currentRangeEnd {
    int end = currentPage.value * pageSize;
    return end > totalFilteredCount ? totalFilteredCount : end;
  }

  void nextPage() {
    if (currentPage.value * pageSize < totalFilteredCount) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  void toggleSelection(int id) {
    if (selectedHerds.contains(id)) {
      selectedHerds.remove(id);
    } else {
      selectedHerds.add(id);
    }
  }

  void clearSelection() {
    selectedHerds.clear();
  }

  bool isSelected(int id) => selectedHerds.contains(id);

  bool get isAllSelected {
    final currentList = _getCurrentFilteredList();
    if (currentList.isEmpty) return false;
    return currentList.every((herd) => selectedHerds.contains(herd['id']));
  }

  List<Map<String, dynamic>> _getCurrentFilteredList() {
    switch (selectedTabIndex.value) {
      case 0: return filteredBovinos;
      case 1: return filteredOvinos;
      case 2: return filteredCaprinos;
      default: return [];
    }
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      clearSelection();
    } else {
      final currentList = _getCurrentFilteredList();
      for (var herd in currentList) {
        selectedHerds.add(herd['id']);
      }
    }
  }

  Future<void> deleteSelectedHerds() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      for (int id in selectedHerds) {
        await db.delete('herds', where: 'id = ?', whereArgs: [id]);
        // Os animais são deletados automaticamente via ON DELETE CASCADE no banco
      }
      clearSelection();
      await carregarRebanhos();
      Get.snackbar("Sucesso", "Rebanhos excluídos com sucesso!", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Erro", "Falha ao excluir rebanhos: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Listas Filtradas Reativas
  List<Map<String, dynamic>> get filteredBovinos => _filterList(bovinos);
  List<Map<String, dynamic>> get filteredOvinos => _filterList(ovinos);
  List<Map<String, dynamic>> get filteredCaprinos => _filterList(caprinos);

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> originalList) {
    return originalList.where((herd) {
      final nameMatches = herd['name'].toString().toLowerCase().contains(searchText.value.toLowerCase());
      final locationMatches = (herd['location'] ?? "").toString().toLowerCase().contains(searchText.value.toLowerCase());
      final filterMatches = selectedFilter.value == "Todos" || herd['management_type'] == selectedFilter.value;
      
      return (nameMatches || locationMatches) && filterMatches;
    }).toList();
  }

  String get currentCategory {
    switch (selectedTabIndex.value) {
      case 0: return 'Bovino';
      case 1: return 'Ovino';
      case 2: return 'Caprino';
      default: return 'Bovino';
    }
  }

  Future<void> carregarRebanhos() async {
    try {
      isLoading.value = true;
      bovinos.value = await DatabaseHelper.instance.getHerdsByCategory('Bovino');
      ovinos.value = await DatabaseHelper.instance.getHerdsByCategory('Ovino');
      caprinos.value = await DatabaseHelper.instance.getHerdsByCategory('Caprino');
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
