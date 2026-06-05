import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';

class FertilityPatternsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  
  var isLoading = false.obs;
  var selectedSpecies = "Geral".obs;

  // Matrizes Individuais
  var individualInsights = <Map<String, dynamic>>[].obs;
  
  // Dados de Rebanho
  var herdMetrics = <Map<String, dynamic>>[].obs;

  // Dados Globais (Simulados para a apresentação)
  var overallFertilityScore = 82.5.obs;
  var avgIEPFarm = 12.8.obs;
  var avgIPCFarm = 1.6.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final db = await DatabaseHelper.instance.database;
      final animals = await db.query('animals', where: 'sex = "Fêmea" AND vital_status = "Ativo"');
      
      // GERAÇÃO DE DADOS DE APRESENTAÇÃO (ELITE / ALERTA / RISCO)
      List<Map<String, dynamic>> mockAnimals = [
        {'identifier': 'NEL-201', 'breed': 'Nelore PO', 'score': 94.5, 'iep': 11.2, 'ipc': 1.1, 'status': 'Elite', 'comment': 'Matriz de altíssimo desempenho. Recomendado coleta de embriões.'},
        {'identifier': 'NEL-305', 'breed': 'Nelore PO', 'score': 88.2, 'iep': 12.1, 'ipc': 1.2, 'status': 'Elite', 'comment': 'Excelente habilidade materna detectada pela IA.'},
        {'identifier': 'ANG-112', 'breed': 'Angus', 'score': 74.0, 'iep': 14.5, 'ipc': 2.1, 'status': 'Atenção', 'comment': 'IEP acima da média regional. Sugerimos reforço proteico.'},
        {'identifier': 'GIR-042', 'breed': 'Gir Leiteiro', 'score': 62.1, 'iep': 16.8, 'ipc': 3.4, 'status': 'Risco', 'comment': 'Baixa taxa de concepção. Avaliar descarte ou exame clínico.'},
      ];

      if (animals.isNotEmpty) {
        individualInsights.value = animals.map((a) {
          final id = a['id'] as int? ?? 0;
          double score = 60.0 + (id % 35);
          return {
            'identifier': a['identifier'],
            'breed': a['breed'] ?? 'Mestiço',
            'score': score,
            'iep': 12.0 + (id % 4),
            'ipc': 1.0 + (id % 2) * 0.5,
            'status': score > 85 ? 'Elite' : (score > 70 ? 'Atenção' : 'Risco'),
            'comment': score > 85 ? 'Matriz com padrão de excelência reprodutiva.' : 'Monitorar ciclo estral nas próximas semanas.'
          };
        }).toList();
      } else {
        individualInsights.value = mockAnimals;
      }

      // REBANHOS (DADOS FALSOS COMPLETOS)
      herdMetrics.value = [
        {'name': 'Lote Elite 01', 'category': 'Bovino', 'success_rate': 91.2, 'avg_iep': 11.8, 'females': 18, 'score': 94.0},
        {'name': 'Rebanho Leiteiro', 'category': 'Caprino', 'success_rate': 78.5, 'avg_iep': 10.2, 'females': 32, 'score': 81.0},
        {'name': 'Lote de Cria B', 'category': 'Ovino', 'success_rate': 64.1, 'avg_iep': 14.5, 'females': 50, 'score': 68.5},
        {'name': 'Novilhas Reposição', 'category': 'Bovino', 'success_rate': 85.0, 'avg_iep': 12.4, 'females': 15, 'score': 88.5},
      ];

      overallFertilityScore.value = 84.7;
      avgIEPFarm.value = 12.4;
      avgIPCFarm.value = 1.4;

    } catch (e) {
      print("FERTILITY_CTRL_ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateSpecies(String val) {
    selectedSpecies.value = val;
    loadData();
  }
}
