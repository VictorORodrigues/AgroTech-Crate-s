import 'package:get/get.dart';

class AnimalMatriz {
  final int id;
  final String identifier;
  final int typeRaca; // 0:Nativa, 1:Mestiço, 2:Leite, 3:Corte, 4:SRD
  final String lineage;
  final String? idPai;
  final int ecc;
  final int numPartos;
  final int dpp;
  final String category;

  AnimalMatriz({
    required this.id,
    required this.identifier,
    required this.typeRaca,
    required this.lineage,
    this.idPai,
    required this.ecc,
    required this.numPartos,
    required this.dpp,
    required this.category,
  });
}

class AnimalReprodutor {
  final int id;
  final String identifier;
  final String breed;
  final int typeRaca;
  final String lineage;
  final String? idPai;
  final double semenFertility;
  final String aptitude; // rústico, alta_producao
  final String category;
  final String? photoPath;

  AnimalReprodutor({
    required this.id,
    required this.identifier,
    required this.breed,
    required this.typeRaca,
    required this.lineage,
    this.idPai,
    required this.semenFertility,
    required this.aptitude,
    required this.category,
    this.photoPath,
  });
}

class RecommendationResult {
  final AnimalReprodutor reprodutor;
  final double score;
  final List<String> justifications;

  RecommendationResult({
    required this.reprodutor,
    required this.score,
    required this.justifications,
  });
}

class MotorRecomendacaoGenetica {
  static List<RecommendationResult> recomendar({
    required AnimalMatriz matriz,
    required List<AnimalReprodutor> reprodutores,
    required String manejoFazenda,
  }) {
    List<RecommendationResult> results = [];
    String manejo = manejoFazenda.toLowerCase();

    for (var macho in reprodutores) {
      if (macho.category != matriz.category) continue;

      double score = 0;
      List<String> motivos = [];

      // 1. CONSANGUINIDADE
      if (macho.lineage == matriz.lineage || (macho.idPai != null && macho.idPai == matriz.idPai)) {
        score = -100;
        motivos.add("BLOQUEIO: Risco de consanguinidade (Mesma linhagem/pai).");
      } else {
        motivos.add("Segurança Genética Aprovada.");

        // 2. APTIDÃO POR MANEJO
        if (manejo == 'extensivo') {
          if (macho.aptitude == 'Rústico' || macho.aptitude == 'rústico') {
            score += 40;
            motivos.add("+40 Pts: Reprodutor Rústico ideal para pasto/caatinga.");
          } else {
            score -= 10;
            motivos.add("-10 Pts: Baixa eficiência de reprodutor de elite em manejo a pasto.");
          }
        } else if (manejo == 'intensivo') {
          if (macho.aptitude == 'Alta produção' || macho.aptitude == 'alta_producao') {
            score += 40;
            motivos.add("+40 Pts: Alta Produção responde bem ao confinamento.");
          }
        } else {
          score += 20;
          motivos.add("+20 Pts: Adequação para regime semiextensivo.");
        }

        // 3. CRUZAMENTO INDUSTRIAL E DIRECIONAMENTO
        if (matriz.typeRaca <= 1 && manejo == 'intensivo' && macho.typeRaca >= 2 && macho.typeRaca <= 3) {
          score += 25;
          motivos.add("+25 Pts: Ganho por Cruzamento Industrial (Fêmea adaptada + Macho Elite).");
        }
        if (manejo == 'extensivo' && macho.typeRaca <= 1) {
          score += 20;
          motivos.add("+20 Pts: Manutenção de sangue adaptado para sobrevivência.");
        }

        // 4. COMPENSAÇÃO DE SAÚDE E PÓS-PARTO
        if (matriz.ecc <= 2) {
          if (macho.semenFertility >= 0.90) {
            score += 30;
            motivos.add("+30 Pts: Sêmen Premium compensa ECC baixo da matriz.");
          } else {
            score -= 15;
            motivos.add("-15 Pts: Matriz debilitada exige touro de fertilidade superior.");
          }
        }
        if (matriz.numPartos > 0 && matriz.dpp < 50 && macho.semenFertility >= 0.92) {
          score += 15;
          motivos.add("+15 Pts: Vigor do sêmen auxilia na involução uterina.");
        }

        // 5. PERFORMANCE INDIVIDUAL
        double pontosSemen = macho.semenFertility * 30;
        score += pontosSemen;
        motivos.add("+${pontosSemen.toStringAsFixed(1)} Pts: Fertilidade Intrínseca (${(macho.semenFertility * 100).toInt()}%).");
      }

      results.add(RecommendationResult(
        reprodutor: macho,
        score: score,
        justifications: motivos,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
