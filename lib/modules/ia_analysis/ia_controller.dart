import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../utils/agro_alerts.dart';
import '../../services/calculadora_prenhez_ia.dart';

enum AnalysisStep { selection, loading, result }

class IaController extends GetxController with GetSingleTickerProviderStateMixin {
  final _storage = GetStorage();
  late TabController tabController;
  
  var currentStep = AnalysisStep.selection.obs;
  var loadingText = "".obs;
  var selectedAnimal = Rxn<Map<String, dynamic>>();
  
  var allAnimalsAptos = <Map<String, dynamic>>[].obs;
  var filteredBovinos = <Map<String, dynamic>>[].obs;
  var filteredOvinos = <Map<String, dynamic>>[].obs;
  var filteredCaprinos = <Map<String, dynamic>>[].obs;

  var searchText = "".obs;
  
  // Resultados do Modelo XGBoost Nativo Recalibrado
  var chanceIA = 0.0.obs;
  var chanceMonta = 0.0.obs;
  var climaAlerta = false.obs;
  var statusIa = "".obs;
  var sucessos = <String>[].obs;
  var fracassos = <String>[].obs;
  var recomendacaoFinal = "".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchAptos();
    debounce(searchText, (_) => filterLists(), time: const Duration(milliseconds: 300));
  }

  Future<void> fetchAptos() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT a.*, h.name as herd_name, h.category as category 
      FROM animals a
      INNER JOIN herds h ON a.herd_id = h.id
      WHERE a.sex = 'Fêmea' 
      AND (a.reproductive_status LIKE '%Vazia%' OR a.reproductive_status = 'Vazia' OR a.reproductive_status = 'Vazia / Apta')
      AND a.vital_status = 'Ativo'
    ''');
    allAnimalsAptos.value = result;
    filterLists();
  }

  void filterLists() {
    String query = searchText.value.toLowerCase();
    filteredBovinos.value = _filterByCategory(query, 'Bovino');
    filteredOvinos.value = _filterByCategory(query, 'Ovino');
    filteredCaprinos.value = _filterByCategory(query, 'Caprino');
  }

  List<Map<String, dynamic>> _filterByCategory(String query, String cat) {
    return allAnimalsAptos.where((a) => 
      a['category'] == cat && 
      (a['identifier'].toString().toLowerCase().contains(query) || a['herd_name'].toString().toLowerCase().contains(query))
    ).toList();
  }

  void startAnalysis(Map<String, dynamic> animal) async {
    selectedAnimal.value = animal;
    currentStep.value = AnalysisStep.loading;
    
    List<String> texts = [
      "Consultando histórico vital no SQLite...",
      "Calculando THI Regional (Thom, 1959)...",
      "Processando na Arvore XGBoost Recalibrada..."
    ];

    for (var text in texts) {
      loadingText.value = text;
      await Future.delayed(const Duration(milliseconds: 700));
    }

    _runModelLocal();
  }

  Future<void> _runModelLocal() async {
    final a = selectedAnimal.value!;
    final db = await DatabaseHelper.instance.database;

    // 1. Coleta dados do Clima (GetStorage)
    double temp = double.tryParse(_storage.read('last_temp')?.replaceAll('°C', '') ?? "32.0") ?? 32.0;
    double ur = double.tryParse(_storage.read('last_umid')?.replaceAll('%', '') ?? "35.0") ?? 35.0;
    double thi = (1.8 * temp + 32) - ((0.55 - 0.0055 * ur) * (1.8 * temp - 26));

    // 2. Extrai dados do Histórico Reprodutivo Real
    final births = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM animal_events WHERE animal_id = ? AND type = 'Nascimento'", [a['id']]
    )) ?? 0;
    
    final abortions = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM animal_events WHERE animal_id = ? AND type = 'Aborto / Perda Gestacional'", [a['id']]
    )) ?? 0;

    // 3. Executa o Modelo Predictor Nativo (Nordeste Realista)
    final result = CalculadoraPrenhezIA.calcularPrenhez(
      especieStr: a['category'] ?? 'Bovino',
      idadeMeses: a['age_months'] ?? 24,
      pesoKg: (a['weight'] ?? 450.0).toDouble(),
      categoriaIaStr: a['breed'] ?? 'SRD (Comum)',
      ecc: (a['ecc'] ?? 3.0).toDouble(),
      paridadeStr: a['parity'] ?? 'Nulípara',
      dppStr: a['dpp_status'] ?? 'Não Se Aplica',
      nascimentosAnteriores: births,
      abortosAnteriores: abortions,
      fertilidadeSemen: 0.90, // Média de mercado
      thiAmbiente: thi,
    );

    // 4. Atualiza os Observáveis para a UI
    chanceIA.value = result.chanceInseminacao;
    chanceMonta.value = result.chanceMontaNatural;
    climaAlerta.value = result.alertaClimatico;
    statusIa.value = result.status;
    sucessos.value = result.motivosSucesso;
    fracassos.value = result.motivosFracasso;
    recomendacaoFinal.value = result.recomendacaoTecnica;
    
    currentStep.value = AnalysisStep.result;
  }

  Future<void> confirmAction() async {
    final db = await DatabaseHelper.instance.database;
    await db.update('animals', {'reproductive_status': 'Inseminada'}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
    await DatabaseHelper.instance.insertEvent(
      selectedAnimal.value!['id'], 
      "Inseminação Artificial", 
      "Análise IA: ${chanceIA.value.toStringAsFixed(1)}% de sucesso. THI: ${climaAlerta.value ? 'Crítico' : 'Normal'}.",
      v1: 0.92, // Fertilidade usada na predição
      t1: "IA",
    );
    Get.back();
    AgroAlert.show(title: "Manejo Registrado", message: "A fêmea agora consta como Inseminada.", isSuccess: true);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
