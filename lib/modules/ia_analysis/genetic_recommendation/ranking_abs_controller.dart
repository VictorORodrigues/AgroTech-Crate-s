import 'package:get/get.dart';
import '../../../database/database_helper.dart';
import 'genetic_engine.dart';
import '../ia_model.dart';

class RankingABSController extends GetxController {
  var selectedMatrix = Rxn<Map<String, dynamic>>();
  var animalsAptos = <Map<String, dynamic>>[].obs;
  var reprodutores = <Map<String, dynamic>>[].obs;
  var ranking = <RecommendationResult>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    final db = await DatabaseHelper.instance.database;
    final matrices = await db.rawQuery('''
      SELECT a.*, h.category, h.management_type 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = 'Fêmea' 
      AND (a.reproductive_status LIKE '%Vazia%' OR a.reproductive_status = 'Vazia')
    ''');
    animalsAptos.value = matrices;

    final males = await db.rawQuery('''
      SELECT a.*, h.category 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = 'Macho'
    ''');
    reprodutores.value = males;
  }

  void calculateRanking(Map<String, dynamic> matrix) {
    selectedMatrix.value = matrix;
    isLoading.value = true;

    final engineMatriz = AnimalMatriz(
      id: matrix['id'],
      identifier: matrix['identifier'],
      typeRaca: ModeloIaPrenhez.mapRaca(matrix['breed']).toInt(),
      lineage: matrix['lineage'] ?? "Desconhecida",
      idPai: matrix['id_pai'],
      ecc: (matrix['ecc'] ?? 3.0).toInt(),
      numPartos: ModeloIaPrenhez.mapParidade(matrix['parity']).toInt(),
      dpp: int.tryParse(matrix['dpp_status']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0,
      category: matrix['category'],
    );

    final List<AnimalReprodutor> engineReprodutores = reprodutores.map((m) => AnimalReprodutor(
      id: m['id'],
      identifier: m['identifier'],
      breed: m['breed'] ?? "",
      typeRaca: ModeloIaPrenhez.mapRaca(m['breed']).toInt(),
      lineage: m['lineage'] ?? "Desconhecida",
      idPai: m['id_pai'],
      semenFertility: (m['semen_fertility'] ?? 0.8),
      aptitude: m['aptitude'] ?? "rústico",
      category: m['category'],
      photoPath: m['photo_path'],
    )).toList().cast<AnimalReprodutor>();

    ranking.value = MotorRecomendacaoGenetica.recomendar(
      matriz: engineMatriz,
      reprodutores: engineReprodutores,
      manejoFazenda: matrix['management_type'] ?? "Extensivo",
    );

    isLoading.value = false;
    Get.toNamed('/ranking-results');
  }
}
