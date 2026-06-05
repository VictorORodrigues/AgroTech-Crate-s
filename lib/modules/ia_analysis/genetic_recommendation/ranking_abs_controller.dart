import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../database/database_helper.dart';
import 'genetic_engine.dart';

class RankingABSController extends GetxController with GetSingleTickerProviderStateMixin {
  final _storage = GetStorage();
  late TabController tabController;

  var selectedMatrix = Rxn<Map<String, dynamic>>();
  var animalsAptos = <Map<String, dynamic>>[].obs;
  
  var filteredBovinos = <Map<String, dynamic>>[].obs;
  var filteredOvinos = <Map<String, dynamic>>[].obs;
  var filteredCaprinos = <Map<String, dynamic>>[].obs;

  var reprodutores = <Map<String, dynamic>>[].obs;
  var ranking = <GeneticMatchResult>[].obs;
  var isLoading = false.obs;
  var searchText = "".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchInitialData();
    debounce(searchText, (_) => filterLists(), time: const Duration(milliseconds: 300));
  }

  Future<void> fetchInitialData() async {
    final db = await DatabaseHelper.instance.database;
    
    // Fêmeas aptas (Vazias/Aptas ou Inseminadas)
    final matrices = await db.rawQuery('''
      SELECT a.*, h.category, h.management_type 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = 'Fêmea' 
      AND (a.reproductive_status LIKE '%Vazia%' OR a.reproductive_status = 'Vazia' OR a.reproductive_status = 'Vazia / Apta')
      AND a.vital_status = 'Ativo'
    ''');
    animalsAptos.value = matrices;
    filterLists();

    // Machos disponíveis
    final males = await db.rawQuery('''
      SELECT a.*, h.category 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = 'Macho' AND a.vital_status = 'Ativo'
    ''');
    reprodutores.value = males;
  }

  void filterLists() {
    String query = searchText.value.toLowerCase();
    filteredBovinos.value = _filterByCategory(query, 'Bovino');
    filteredOvinos.value = _filterByCategory(query, 'Ovino');
    filteredCaprinos.value = _filterByCategory(query, 'Caprino');
  }

  List<Map<String, dynamic>> _filterByCategory(String query, String cat) {
    return animalsAptos.where((a) => 
      a['category'] == cat && 
      (a['identifier'].toString().toLowerCase().contains(query) || 
       (a['name'] ?? "").toString().toLowerCase().contains(query))
    ).toList();
  }

  void calculateRanking(Map<String, dynamic> matrix) {
    selectedMatrix.value = matrix;
    isLoading.value = true;

    // Calcula THI Atual para o motor
    double temp = double.tryParse(_storage.read('last_temp')?.replaceAll('°C', '') ?? "32.0") ?? 32.0;
    double ur = double.tryParse(_storage.read('last_umid')?.replaceAll('%', '') ?? "35.0") ?? 35.0;
    double thi = (1.8 * temp + 32) - ((0.55 - 0.0055 * ur) * (1.8 * temp - 26));

    final engineMatriz = AnimalMatriz(
      id: matrix['id'],
      identifier: matrix['identifier'],
      category: matrix['category'],
      breed: matrix['breed'] ?? 'SRD (Comum)',
      ecc: (matrix['ecc'] ?? 3.0).toDouble(),
      parity: matrix['parity'] ?? 'Nulípara',
      aptitude: matrix['aptitude'] ?? 'Rústica',
      lineage: matrix['lineage'] ?? 'Desconhecida',
      id_pai: matrix['id_pai'],
      id_mae: matrix['id_mae'],
    );

    // FILTRO CRÍTICO: Somente machos da MESMA ESPÉCIE (Bovino com Bovino, etc)
    final List<AnimalReprodutor> engineReprodutores = reprodutores
        .where((m) => m['category'] == matrix['category'])
        .map((m) => AnimalReprodutor(
      id: m['id'],
      identifier: m['identifier'],
      breed: m['breed'] ?? 'SRD (Comum)',
      category: m['category'],
      aptitude: m['aptitude'] ?? 'Rústico',
      semenFertility: (m['semen_fertility'] ?? 0.8).toDouble(),
      weight: (m['weight'] ?? 0.0).toDouble(),
      lineage: m['lineage'] ?? 'Desconhecida',
      id_pai: m['id_pai'],
      id_mae: m['id_mae'],
      photoPath: m['photo_path'],
    )).toList();

    ranking.value = GeneticEngine.rankMales(
      female: engineMatriz,
      availableMales: engineReprodutores,
      currentTHI: thi,
    );

    isLoading.value = false;
    Get.toNamed('/ranking-results');
  }
}
