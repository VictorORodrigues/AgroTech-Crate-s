import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../rebanho_controller.dart';
import '../../../services/sync_service.dart';

class DetalhesRebanhoController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  late Map<String, dynamic> rebanhoInicial;
  
  var rebanho = <String, dynamic>{}.obs;
  var animais = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  // Busca e Filtro
  var searchText = "".obs;
  var selectedSexFilter = "Todos".obs; // Todos, Macho, Fêmea
  var selectedStatusFilter = "Todos".obs; // Todos, Prenhe, Vazia / Apta, Em Lactação, Inseminada

  // Paginação
  var currentAnimalPage = 1.obs;
  final int animalPageSize = 50;

  // Multi-seleção de animais
  var selectedAnimals = <int>{}.obs;

  // Estatísticas
  var totalFemeas = 0.obs;
  var totalMachos = 0.obs;
  var totalPrenhes = 0.obs;
  var totalLactacao = 0.obs;
  var totalInseminada = 0.obs;
  var femeasAptas = 0.obs;
  var avgEcc = 0.0.obs;

  var taxaPrenhez = "0%".obs;
  var taxaAptas = "0%".obs;
  var taxaLactacao = "0%".obs;
  var taxaInseminada = "0%".obs;

  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTabIndex.value = tabController.index;
        if (selectedTabIndex.value == 0) clearAnimalSelection();
      }
    });

    // Tratamento seguro de argumentos
    final dynamic args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      rebanhoInicial = args;
    } else {
      rebanhoInicial = {'id': 0, 'name': 'Desconhecido', 'category': 'Bovino'};
    }

    rebanho.value = rebanhoInicial;
    carregarDados();

    // Resetar página ao mudar busca ou filtros
    ever(searchText, (_) => currentAnimalPage.value = 1);
    ever(selectedSexFilter, (_) => currentAnimalPage.value = 1);
    ever(selectedStatusFilter, (_) => currentAnimalPage.value = 1);
  }

  // Métodos de Paginação de Animais
  List<Map<String, dynamic>> get paginatedAnimais {
    final filtered = filteredAnimais;
    int start = (currentAnimalPage.value - 1) * animalPageSize;
    int end = start + animalPageSize;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get totalFilteredAnimalsCount => filteredAnimais.length;

  int get currentAnimalRangeStart => totalFilteredAnimalsCount == 0 ? 0 : (currentAnimalPage.value - 1) * animalPageSize + 1;
  int get currentAnimalRangeEnd {
    int end = currentAnimalPage.value * animalPageSize;
    return end > totalFilteredAnimalsCount ? totalFilteredAnimalsCount : end;
  }

  void nextAnimalPage() {
    if (currentAnimalPage.value * animalPageSize < totalFilteredAnimalsCount) {
      currentAnimalPage.value++;
    }
  }

  void previousAnimalPage() {
    if (currentAnimalPage.value > 1) {
      currentAnimalPage.value--;
    }
  }

  void toggleAnimalSelection(int id) {
    if (selectedAnimals.contains(id)) {
      selectedAnimals.remove(id);
    } else {
      selectedAnimals.add(id);
    }
  }

  void clearAnimalSelection() {
    selectedAnimals.clear();
  }

  Future<List<Map<String, dynamic>>> getRelocationOptions() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'herds',
      where: 'category = ? AND id != ?',
      whereArgs: [rebanho['category'], rebanho['id']],
    );
  }

  Future<void> relocateSelectedAnimals(int targetHerdId, String targetHerdName) async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      for (int id in selectedAnimals) {
        await db.update('animals', {'herd_id': targetHerdId}, where: 'id = ?', whereArgs: [id]);
      }
      clearAnimalSelection();
      await carregarDados();
      if (Get.isRegistered<RebanhoController>()) {
        Get.find<RebanhoController>().carregarRebanhos();
      }
      SyncService.instance.syncLocalToCloud();
      AgroAlert.show(title: "Realocados!", message: "Animais movidos para $targetHerdName", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao mover animais: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  bool get isAllAnimalsSelected {
    if (filteredAnimais.isEmpty) return false;
    return filteredAnimais.every((a) => selectedAnimals.contains(a['id']));
  }

  void toggleSelectAllAnimals() {
    if (isAllAnimalsSelected) {
      clearAnimalSelection();
    } else {
      for (var a in filteredAnimais) {
        selectedAnimals.add(a['id']);
      }
    }
  }

  Future<void> deleteSelectedAnimals() async {
    try {
      isLoading.value = true;
      for (int id in selectedAnimals) {
        await DatabaseHelper.instance.deleteAnimal(id);
      }
      clearAnimalSelection();
      await carregarDados();
      if (Get.isRegistered<RebanhoController>()) {
        Get.find<RebanhoController>().carregarRebanhos();
      }
      SyncService.instance.syncLocalToCloud();
      AgroAlert.show(title: "Sucesso", message: "Animais excluídos com sucesso!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao excluir animais: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredAnimais {
    final filtered = animais.where((a) {
      final nameMatches = (a['name'] ?? "").toString().toLowerCase().contains(searchText.value.toLowerCase());
      final idMatches = a['identifier'].toString().toLowerCase().contains(searchText.value.toLowerCase());
      final breedMatches = (a['breed_name'] ?? a['breed'] ?? "").toString().toLowerCase().contains(searchText.value.toLowerCase());
      
      final sexMatches = selectedSexFilter.value == "Todos" || a['sex'] == selectedSexFilter.value;

      // Filtro de Status Reprodutivo
      bool statusMatches = true;
      if (selectedStatusFilter.value != "Todos") {
        statusMatches = a['reproductive_status'] == selectedStatusFilter.value;
      }

      return (nameMatches || idMatches || breedMatches) && sexMatches && statusMatches;
    }).toList();

    // Ordenação: Ativos primeiro, depois Inativos (Vendido > Abatido > Óbito)
    filtered.sort((a, b) {
      final statusA = a['vital_status'] ?? "Ativo";
      final statusB = b['vital_status'] ?? "Ativo";
      
      if (statusA != statusB) {
        if (statusA == "Ativo") return -1;
        if (statusB == "Ativo") return 1;

        // Ambos são inativos, aplicar ordem personalizada: Vendido > Abatido > Óbito
        final priority = {"Vendido": 1, "Abatido": 2, "Óbito": 3};
        int pA = priority[statusA] ?? 99;
        int pB = priority[statusB] ?? 99;
        
        if (pA != pB) return pA.compareTo(pB);
      }
      
      return a['identifier'].toString().compareTo(b['identifier'].toString());
    });

    return filtered;
  }

  Future<void> carregarDados() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      final rebanhoAtualizado = await db.query('herds', where: 'id = ?', whereArgs: [rebanho['id']]);
      if (rebanhoAtualizado.isNotEmpty) {
        rebanho.value = rebanhoAtualizado.first;
      }

      animais.value = await db.query('animals', where: 'herd_id = ?', whereArgs: [rebanho['id']]);
      
      _calcularEstatisticas();
    } finally {
      isLoading.value = false;
    }
  }

  void _calcularEstatisticas() {
    int femeas = 0;
    int machos = 0;
    int prenhes = 0;
    int aptas = 0;
    int lactacao = 0;
    int inseminada = 0;

    for (var animal in animais) {
      if (animal['sex'] == 'Fêmea') {
        femeas++;
        final status = animal['reproductive_status']?.toString() ?? "";
        if (status == 'Prenhe') {
          prenhes++;
        } else if (status == 'Vazia / Apta') {
          aptas++;
        } else if (status == 'Em Lactação') {
          lactacao++;
        } else if (status == 'Inseminada') {
          inseminada++;
        }
      } else {
        machos++;
      }
    }

    totalFemeas.value = femeas;
    totalMachos.value = machos;
    totalPrenhes.value = prenhes;
    femeasAptas.value = aptas;
    totalLactacao.value = lactacao;
    totalInseminada.value = inseminada;
    
    double sumEcc = 0;
    for (var a in animais) {
      sumEcc += (a['ecc'] ?? 3.0);
    }
    avgEcc.value = animais.isNotEmpty ? sumEcc / animais.length : 0.0;
    
    if (femeas > 0) {
      taxaPrenhez.value = "${((prenhes / femeas) * 100).toStringAsFixed(1)}%";
      taxaAptas.value = "${((aptas / femeas) * 100).toStringAsFixed(1)}%";
      taxaLactacao.value = "${((lactacao / femeas) * 100).toStringAsFixed(1)}%";
      taxaInseminada.value = "${((inseminada / femeas) * 100).toStringAsFixed(1)}%";
    } else {
      taxaPrenhez.value = "0%";
      taxaAptas.value = "0%";
      taxaLactacao.value = "0%";
      taxaInseminada.value = "0%";
    }
  }

  Future<void> excluirAnimal(int id) async {
    await DatabaseHelper.instance.deleteAnimal(id);
    await carregarDados();
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
    SyncService.instance.syncLocalToCloud();
  }

  Future<void> editarRebanho(String novoNome, String novaLocalizacao, String novoManejo) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('herds', {
      'name': novoNome,
      'location': novaLocalizacao,
      'management_type': novoManejo,
    }, where: 'id = ?', whereArgs: [rebanho['id']]);
    await carregarDados();
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
  }

  Future<void> excluirRebanho() async {
    await DatabaseHelper.instance.deleteHerd(rebanho['id']);
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
    SyncService.instance.syncLocalToCloud();
    Get.back(); // Volta para a lista de rebanhos
    AgroAlert.show(title: "Sucesso", message: "Rebanho excluído permanentemente.", isSuccess: true);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
