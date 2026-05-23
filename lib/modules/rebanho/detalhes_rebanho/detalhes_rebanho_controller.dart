import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../rebanho_controller.dart';

class DetalhesRebanhoController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final Map<String, dynamic> rebanhoInicial = Get.arguments;
  
  var rebanho = <String, dynamic>{}.obs;
  var animais = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  // Estatísticas
  var totalFemeas = 0.obs;
  var totalMachos = 0.obs;
  var taxaPrenhez = "0%".obs;
  var femeasAptas = 0.obs;
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTabIndex.value = tabController.index;
      }
    });
    rebanho.value = rebanhoInicial;
    carregarDados();
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

    for (var animal in animais) {
      if (animal['sex'] == 'Fêmea') {
        femeas++;
        if (animal['reproductive_status'] == '🟢 Prenhe') {
          prenhes++;
        } else if (animal['reproductive_status'] == '🟡 Vazia / Apta') {
          aptas++;
        }
      } else {
        machos++;
      }
    }

    totalFemeas.value = femeas;
    totalMachos.value = machos;
    femeasAptas.value = aptas;
    
    if (femeas > 0) {
      double taxa = (prenhes / femeas) * 100;
      taxaPrenhez.value = "${taxa.toStringAsFixed(1)}% Prenhes";
    } else {
      taxaPrenhez.value = "0% Prenhes";
    }
  }

  Future<void> excluirAnimal(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('animals', where: 'id = ?', whereArgs: [id]);
    await carregarDados();
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
  }

  Future<void> editarNomeRebanho(String novoNome) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('herds', {'name': novoNome}, where: 'id = ?', whereArgs: [rebanho['id']]);
    await carregarDados();
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
  }

  Future<void> excluirRebanho() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('herds', where: 'id = ?', whereArgs: [rebanho['id']]);
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
    Get.back(); // Volta para a lista de rebanhos
    AgroAlert.show(title: "Sucesso", message: "Rebanho excluído permanentemente.", isSuccess: true);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
