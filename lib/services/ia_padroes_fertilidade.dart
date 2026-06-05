import 'dart:math';
import '../database/database_helper.dart';

enum FertilityPattern { elite, attention, risk }

class FertilityInsight {
  final int animalId;
  final String identifier;
  final String species;
  final FertilityPattern pattern;
  final double score; // 0 a 100
  final Map<String, dynamic> metrics;
  final String technicalInsight;

  FertilityInsight({
    required this.animalId,
    required this.identifier,
    required this.species,
    required this.pattern,
    required this.score,
    required this.metrics,
    required this.technicalInsight,
  });
}

class FertilityEngine {
  /// Analisa o histórico de eventos de uma fêmea e gera o padrão de fertilidade
  static Future<FertilityInsight> analyzeAnimal(Map<String, dynamic> animal) async {
    final int animalId = animal['id'];
    final String species = animal['category'] ?? "Bovino";
    final db = DatabaseHelper.instance;
    final events = await db.getEventsByAnimal(animalId);

    // 1. Extração de Features
    int births = events.where((e) => e['type'] == 'Nascimento').length;
    int abortions = events.where((e) => e['type'] == 'Aborto / Perda Gestacional').length;
    int inseminations = events.where((e) => e['type'] == 'Inseminação Artificial').length;
    
    // Calcular IEP (Intervalo Entre Partos) em meses
    double avgIEP = 0;
    final birthDates = events
        .where((e) => e['type'] == 'Nascimento')
        .map((e) => DateTime.parse(e['date']))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (birthDates.length >= 2) {
      int totalDays = 0;
      for (int i = 0; i < birthDates.length - 1; i++) {
        totalDays += birthDates[i].difference(birthDates[i + 1]).inDays;
      }
      avgIEP = (totalDays / (birthDates.length - 1)) / 30.44;
    }

    // Calcular Inseminações por Concepção (IPC)
    double ipc = births > 0 ? (inseminations / births) : inseminations.toDouble();
    if (ipc == 0 && inseminations > 0) ipc = inseminations.toDouble();

    // 2. Score de Fertilidade (Lógica Heurística simulando Random Forest)
    double score = 70.0; // Base neutra

    // Penalidade por Abortos
    score -= (abortions * 25);
    
    // Ajuste por IPC (Inseminações por Concepção)
    if (ipc <= 1.5) score += 15;
    else if (ipc > 3.0) score -= 20;

    // Ajuste por IEP (Intervalo Entre Partos) - Diferente por espécie
    if (avgIEP > 0) {
      if (species == 'Bovino') {
        if (avgIEP <= 13) score += 15;
        else if (avgIEP > 16) score -= 20;
      } else { // Ovinos/Caprinos
        if (avgIEP <= 8) score += 15;
        else if (avgIEP > 10) score -= 20;
      }
    }

    // 3. Classificação em Clusters
    FertilityPattern pattern;
    String insight = "";

    if (score >= 75) {
      pattern = FertilityPattern.elite;
      insight = "Matriz de alta performance. IEP ideal e resposta rápida a protocolos. Recomendada para replicação genética.";
    } else if (score >= 45) {
      pattern = FertilityPattern.attention;
      insight = "Desempenho moderado. Sugere-se revisão do escore corporal (ECC) e suplementação mineral para reduzir o intervalo entre partos.";
    } else {
      pattern = FertilityPattern.risk;
      insight = "Ineficiência crônica detectada. Alto custo de manutenção para baixo retorno produtivo. Alerta de descarte econômico.";
    }

    return FertilityInsight(
      animalId: animalId,
      identifier: animal['identifier'],
      species: species,
      pattern: pattern,
      score: score.clamp(0, 100),
      metrics: {
        'nascimentos': births,
        'abortos': abortions,
        'iep': avgIEP,
        'ipc': ipc,
      },
      technicalInsight: insight,
    );
  }

  static Future<List<FertilityInsight>> analyzeHerd(int herdId) async {
    final db = await DatabaseHelper.instance.database;
    final animals = await db.query('animals', where: 'herd_id = ? AND sex = "Fêmea" AND vital_status = "Ativo"', whereArgs: [herdId]);
    
    List<FertilityInsight> insights = [];
    for (var a in animals) {
      insights.add(await analyzeAnimal(a));
    }
    return insights;
  }
}
