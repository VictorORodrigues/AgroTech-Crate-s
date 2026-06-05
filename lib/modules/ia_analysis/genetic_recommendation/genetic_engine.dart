import 'dart:math';

class GeneticMatchResult {
  final AnimalReprodutor male;
  final double score;
  final List<String> justifications;
  final bool isBlocked;

  GeneticMatchResult({
    required this.male,
    required this.score,
    required this.justifications,
    this.isBlocked = false,
  });
}

class AnimalMatriz {
  final int id;
  final String identifier;
  final String category;
  final String breed;
  final double ecc;
  final String parity;
  final String aptitude;
  final String? id_pai;
  final String? id_mae;
  final String lineage; // Adicionado para rastreio de avós/bisavôs

  AnimalMatriz({
    required this.id,
    required this.identifier,
    required this.category,
    required this.breed,
    required this.ecc,
    required this.parity,
    required this.aptitude,
    required this.lineage,
    this.id_pai,
    this.id_mae,
  });
}

class AnimalReprodutor {
  final int id;
  final String identifier;
  final String breed;
  final String category; // Adicionado para garantir a espécie correta
  final String aptitude;
  final double semenFertility;
  final double weight;
  final String? id_pai;
  final String? id_mae;
  final String? photoPath;
  final String lineage;

  AnimalReprodutor({
    required this.id,
    required this.identifier,
    required this.breed,
    required this.category,
    required this.aptitude,
    required this.semenFertility,
    required this.weight,
    required this.lineage,
    this.id_pai,
    this.id_mae,
    this.photoPath,
  });
}

class GeneticEngine {
  /// Motor de Recomendação e Ranking de Acasalamento Direcionado
  /// Implementa regras zootécnicas avançadas para o semiárido.
  static List<GeneticMatchResult> rankMales({
    required AnimalMatriz female,
    required List<AnimalReprodutor> availableMales,
    required double currentTHI,
  }) {
    List<GeneticMatchResult> results = [];

    for (var male in availableMales) {
      double score = 60.0; // Score Base
      List<String> justifications = [];
      bool blocked = false;

      // 1. PILAR: BLOQUEIO DE CONSANGUINIDADE (Risco Máximo - Avós e Bisavós)
      final fId = female.identifier.toLowerCase().trim();
      final fPai = female.id_pai?.toString().trim().toLowerCase() ?? "";
      final fMae = female.id_mae?.toString().trim().toLowerCase() ?? "";
      final fLinhagem = female.lineage.toLowerCase();

      final mId = male.identifier.toLowerCase().trim();
      final mPai = male.id_pai?.toString().trim().toLowerCase() ?? "";
      final mMae = male.id_mae?.toString().trim().toLowerCase() ?? "";
      final mLinhagem = male.lineage.toLowerCase();

      // Checagem Direta (Pai/Mãe/Irmão)
      bool sameFather = (fPai.isNotEmpty && fPai != "desconhecido" && fPai == mPai);
      bool sameMother = (fMae.isNotEmpty && fMae != "desconhecido" && fMae == mMae);
      bool isFather = (fPai.isNotEmpty && fPai == mId);
      
      // Checagem Profunda (Avós/Bisavós através do campo lineage)
      // Verifica se o ID do macho ou de seus pais aparece na linhagem da fêmea
      bool ancestorMatch = false;
      if (mId.length > 2 && fLinhagem.contains(mId)) ancestorMatch = true;
      if (mPai.length > 2 && fLinhagem.contains(mPai)) ancestorMatch = true;
      if (fId.length > 2 && mLinhagem.contains(fId)) ancestorMatch = true;

      if (sameFather || sameMother || isFather || ancestorMatch) {
        score = 0.0;
        blocked = true;
        justifications.add("BLOQUEIO: Risco de consanguinidade (Ancestral comum detectado).");
      }

      if (!blocked) {
        // 2. PILAR: COMPLEMENTARIDADE DE APTIDÃO
        if (female.aptitude != male.aptitude) {
          score += 20.0;
          justifications.add("Complementaridade: Equilíbrio entre Rusticidade e Produção.");
        } else {
          score -= 10.0;
          justifications.add("Homogeneidade: Ambos possuem o mesmo foco de aptidão.");
        }

        // 3. PILAR: FERTILIDADE DO SÊMEN (Multiplicador de Vigor)
        score *= male.semenFertility;
        justifications.add("Vigor Seminal: Reprodutor com ${(male.semenFertility * 100).toInt()}% de fertilidade.");

        // 4. PILAR: CORREÇÃO DE BIOTIPO (Segurança no Parto)
        if (female.parity == "Nulípara" && male.weight > 500) {
          score -= 25.0;
          justifications.add("Risco de Parto: Reprodutor pesado para matriz jovem (Nulípara).");
        }

        // 5. REGRAS DE MERCADO (CATEGORIA E LINHAGEM)
        final femaleCat = female.breed; // 'Nativa Pura', 'Mestico Sertanejo', etc.
        final maleCat = male.breed;

        // REGRA 1: CHOQUE DE SANGUE (HETEROSE)
        bool femaleIsMestica = femaleCat.contains("Mestiço") || femaleCat.contains("SRD");
        bool maleIsPuro = maleCat.contains("Pura");
        if (femaleIsMestica && maleIsPuro) {
          score += 30.0;
          justifications.add("Choque de Sangue: Potencial máximo de ganho produtivo (Heterose).");
        }

        // REGRA 2: PRESERVAÇÃO DE ELITE (FÊMEA PURA)
        bool femaleIsPura = femaleCat.contains("Pura");
        if (femaleIsPura) {
          if (maleIsPuro) {
            // Se clima for ameno, bonifica muito. Se quente, bonifica menos.
            if (currentTHI < 75.0) {
              score += 40.0;
              justifications.add("Preservação de Elite: Acasalamento ideal para linhagem PO.");
            } else {
              score += 20.0;
              justifications.add("Elite: Mantém linhagem pura (Atenção ao estresse térmico).");
            }
          } else if (maleCat.contains("SRD")) {
            score -= 50.0;
            justifications.add("Proteção Genética: Não recomendado degradar genética pura com SRD.");
          }
        }

        // REGRA 3: FILTRO DE SOBREVIVÊNCIA (EXÓTICA PURA NO CALOR)
        if (femaleCat == "Exótica Pura" && maleCat == "Exótica Pura" && currentTHI >= 79.0) {
          score -= 40.0;
          justifications.add("Bloqueio de Fragilidade: Risco de mortalidade do filhote por calor extremo.");
        }
      }

      results.add(GeneticMatchResult(
        male: male,
        score: score.clamp(0.0, 100.0),
        justifications: justifications,
        isBlocked: blocked,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
