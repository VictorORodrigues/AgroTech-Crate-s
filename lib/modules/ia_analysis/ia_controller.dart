import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'ia_model.dart';
import '../../database/database_helper.dart';
import '../../utils/agro_alerts.dart';

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
  var probability = 0.0.obs;
  var justification = "".obs;

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
      AND (a.reproductive_status LIKE '%Vazia%' OR a.reproductive_status = 'Vazia')
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
      "Calculando THI exato (Thom, 1959)...",
      "Sincronizando Resiliência Genética e Nutrição...",
      "Processando na Floresta Regressora Equilibrada..."
    ];

    for (var text in texts) {
      loadingText.value = text;
      await Future.delayed(const Duration(milliseconds: 900));
    }

    _runModelLocal();
  }

  void _runModelLocal() {
    final a = selectedAnimal.value!;
    
    double temp = double.tryParse(_storage.read('last_temp')?.replaceAll('°C', '') ?? "32.0") ?? 32.0;
    double ur = double.tryParse(_storage.read('last_umid')?.replaceAll('%', '') ?? "35.0") ?? 35.0;
    
    double thi = (1.8 * temp + 32) - ((0.55 - 0.0055 * ur) * (1.8 * temp - 26));
    
    double rebanhoIdx = ModeloIaPrenhez.mapRebanho(a['category']);
    double racaIdx = ModeloIaPrenhez.mapRaca(a['breed']);
    double paridadeIdx = ModeloIaPrenhez.mapParidade(a['parity']);
    
    double dppValue = 0.0;
    if (paridadeIdx > 0) {
      String dppStatus = a['dpp_status'] ?? "";
      if (dppStatus.contains("Recente")) dppValue = 30.0;
      else if (dppStatus.contains("Médio")) dppValue = 60.0;
      else if (dppStatus.contains("Antigo")) dppValue = 120.0;
      else dppValue = 90.0;
    }

    List<double> inputs = [rebanhoIdx, racaIdx, (a['age_months'] ?? 24).toDouble(), (a['weight'] ?? 40.0).toDouble(), (a['ecc'] ?? 3.0).toDouble(), paridadeIdx, dppValue, thi];

    probability.value = ModeloIaPrenhez.predizer(inputs);
    _gerarRelatorioZootecnico(inputs, a['identifier']);
    
    currentStep.value = AnalysisStep.result;
  }

  void _gerarRelatorioZootecnico(List<double> inputs, String id) {
    List<String> riscos = [];
    List<String> favores = [];
    
    double rebanho = inputs[0];
    double raca = inputs[1];
    double idade = inputs[2];
    double escore = inputs[4];
    double partos = inputs[5];
    double dpp = inputs[6];
    double thi = inputs[7];

    double limite = (rebanho == 2) ? 70.0 : (rebanho == 1 ? 74.0 : 78.0);
    bool emEstresse = thi > limite;
    bool ehAdaptado = (raca == 0 || raca == 1);

    if (emEstresse) {
      if (ehAdaptado) favores.add("A genética rústica/nativa protegeu a matriz contra o THI de ${thi.toStringAsFixed(1)}.");
      else riscos.add("O clima atual (THI ${thi.toStringAsFixed(1)}) superou o limite da espécie ($limite), castigando a raça sensível.");
    } else {
      favores.add("O clima no manejo está excelente (THI ${thi.toStringAsFixed(1)}), na zona de conforto térmico.");
    }

    if (escore <= 2) riscos.add("Escore Corporal baixo ($escore) indica desnutrição, inibindo a ovulação.");
    else if (escore == 5) riscos.add("O animal apresenta Obesidade (Escore 5), gerando distúrbios hormonais.");
    else favores.add("O Escore Corporal está perfeito ($escore), garantindo energia para a prenhez.");

    if (idade > 52) riscos.add("Idade avançada ($idade meses) reduz a viabilidade biológica.");
    if (partos == 1) riscos.add("Fêmea Primípara: divide energia entre crescimento e produção.");
    if (partos > 0 && dpp < 50) riscos.add("Pós-parto precoce ($dpp dias): o útero ainda está em involução.");

    String finalTxt = "";
    if (riscos.isNotEmpty) finalTxt += "🚨 FATORES DE RISCO DETECTADOS:\n• " + riscos.join("\n• ") + "\n\n";
    if (favores.isNotEmpty) finalTxt += "✨ FATORES FAVORÁVEIS AO MANEJO:\n• " + favores.join("\n• ") + "\n\n";

    String recomendacao = (probability.value >= 0.75) 
      ? "📊 🟢 EXCELENTE CENÁRIO! Os índices de saúde e adaptação anulam os riscos. Prossiga com a I.A.!"
      : (probability.value >= 0.50) 
        ? "📊 🟡 ATENÇÃO: Viável, mas com perda de eficiência. Melhore o escore ou espere esfriar."
        : "📊 🔴 RISCO ALTO: Condições desfavoráveis. ADIE o procedimento.";

    justification.value = finalTxt + recomendacao;
  }

  Future<void> confirmAction() async {
    final db = await DatabaseHelper.instance.database;
    await db.update('animals', {'reproductive_status': '🟢 Prenhe'}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
    await DatabaseHelper.instance.insertEvent(selectedAnimal.value!['id'], "Inseminação", "IA realizada com ${(probability.value * 100).toStringAsFixed(0)}% de chance.");
    Get.back();
    AgroAlert.show(title: "Sucesso", message: "Inseminação registrada no histórico!", isSuccess: true);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
