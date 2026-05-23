import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';

class RebanhoController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  
  var bovinos = <Map<String, dynamic>>[].obs;
  var ovinos = <Map<String, dynamic>>[].obs;
  var caprinos = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    
    // Escuta a mudança de abas para atualizar o índice reativamente
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedTabIndex.value = tabController.index;
      }
    });

    carregarRebanhos();
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
