import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class DashboardController extends GetxController {
  var selectedSpecies = "Geral".obs;
  var selectedPeriod = "Últimos 6 meses".obs;

  var isLoading = false.obs;

  // KPIs Financeiros
  var totalRevenue = 0.0.obs;
  var totalExpenses = 0.0.obs;
  var idleCost = 0.0.obs;
  var geneticRoi = 0.0.obs;

  // KPIs Reprodutivos
  var pregnancyRate = 0.0.obs;
  var avgIEP = 0.0.obs; // Em meses
  var matrixStatusData = <String, double>{}.obs; 
  var conceptionRates = <String, double>{'IA': 0.0, 'Monta': 0.0}.obs;

  // Ranking Elite
  var eliteMatrix = <Map<String, dynamic>>[].obs;

  // Próximos Eventos
  var upcomingEvents = <Map<String, dynamic>>[].obs;

  // Dados para Gráficos
  var expensesTimeline = <double>[].obs;
  var revenueTimeline = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      // Simulando delay de processamento de IA
      await Future.delayed(const Duration(milliseconds: 600));

      String speciesFilter = "";
      if (selectedSpecies.value != "Geral") {
        speciesFilter = " AND h.category = '${selectedSpecies.value}'";
      }

      // 1. DADOS FINANCEIROS (Simulados de acordo com a espécie para realismo)
      if (selectedSpecies.value == 'Bovino') {
        totalRevenue.value = 125400.0;
        totalExpenses.value = 42300.0;
        idleCost.value = 8400.0;
        geneticRoi.value = 42.5;
        expensesTimeline.value = [12000, 15000, 11000, 18000, 14000, 16000];
        revenueTimeline.value = [25000, 30000, 28000, 45000, 52000, 60000];
        pregnancyRate.value = 78.2;
        avgIEP.value = 13.2;
        conceptionRates.value = {'IA': 72.4, 'Monta': 54.1};
      } else if (selectedSpecies.value == 'Ovino') {
        totalRevenue.value = 45200.0;
        totalExpenses.value = 12100.0;
        idleCost.value = 2100.0;
        geneticRoi.value = 28.3;
        expensesTimeline.value = [3000, 4500, 2800, 5000, 3200, 4100];
        revenueTimeline.value = [8000, 9500, 11000, 14000, 16500, 19000];
        pregnancyRate.value = 84.5;
        avgIEP.value = 7.8;
        conceptionRates.value = {'IA': 81.0, 'Monta': 68.2};
      } else {
        // Caprino ou Geral
        totalRevenue.value = 285400.0;
        totalExpenses.value = 86200.0;
        idleCost.value = 12450.0;
        geneticRoi.value = 35.8;
        expensesTimeline.value = [15000, 20000, 18000, 25000, 22000, 28000];
        revenueTimeline.value = [40000, 45000, 55000, 75000, 92000, 110000];
        pregnancyRate.value = 76.8;
        avgIEP.value = 11.5;
        conceptionRates.value = {'IA': 74.5, 'Monta': 52.3};
      }

      // 2. STATUS DE MATRIZES (Query Real com Fallback Mock)
      final statusList = await db.rawQuery('''
        SELECT a.reproductive_status, COUNT(*) as total
        FROM animals a
        INNER JOIN herds h ON a.herd_id = h.id
        WHERE a.sex = 'Fêmea' AND a.vital_status = 'Ativo' $speciesFilter
        GROUP BY a.reproductive_status
      ''');
      
      var statusMap = <String, double>{};
      if (statusList.isEmpty) {
        statusMap = {'Prenhe': 45, 'Vazia': 15, 'Lactação': 25, 'IA': 10};
      } else {
        for (var row in statusList) {
          statusMap[row['reproductive_status'].toString()] = (row['total'] as int).toDouble();
        }
      }
      matrixStatusData.value = statusMap;

      // 3. RANKING ELITE (Query Real)
      final elite = await db.rawQuery('''
        SELECT a.identifier, a.lineage, a.breed_name,
               (SELECT COUNT(*) FROM animal_events WHERE animal_id = a.id AND type = 'Nascimento') as crias,
               (SELECT AVG(value_1) FROM animal_events WHERE animal_id = a.id AND type = 'Pesagem e Escore') as gmd
        FROM animals a
        INNER JOIN herds h ON a.herd_id = h.id
        WHERE a.sex = 'Fêmea' AND a.vital_status = 'Ativo' $speciesFilter
        ORDER BY gmd DESC LIMIT 5
      ''');
      eliteMatrix.value = elite.isEmpty ? [
        {'identifier': 'MT-042', 'lineage': 'Sertão', 'crias': 4, 'gmd': 1.15},
        {'identifier': 'MT-089', 'lineage': 'Elite', 'crias': 3, 'gmd': 0.98},
        {'identifier': 'MT-012', 'lineage': 'Maranhão', 'crias': 5, 'gmd': 0.95},
      ] : elite;

      // 4. PRÓXIMOS EVENTOS (Query Real)
      final now = DateTime.now().toIso8601String();
      final nextWeek = DateTime.now().add(const Duration(days: 7)).toIso8601String();
      final events = await db.rawQuery('''
        SELECT e.*, a.identifier 
        FROM animal_events e
        INNER JOIN animals a ON e.animal_id = a.id
        WHERE e.is_task = 1 AND e.date >= ? AND e.date <= ?
        ORDER BY e.date ASC
      ''', [now, nextWeek]);
      upcomingEvents.value = events;

    } catch (e) {
      print("DASHBOARD_ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateSpecies(String val) {
    selectedSpecies.value = val;
    loadDashboardData();
  }

  void updatePeriod(String? val) {
    if (val != null) {
      selectedPeriod.value = val;
      loadDashboardData();
    }
  }
}
