class ModeloIaPrenhez {
  /// Executa a predição da probabilidade de prenhez baseada no RandomForest exportado.
  /// Inputs: [tipo_rebanho, tipo_raca, idade_meses, peso_kg, escore_corporal, num_partos, dias_pos_parto, thi]
  static double predizer(List<double> input) {
    return score(input);
  }

  // --- INÍCIO DO CÓDIGO GERADO PELO M2CGEN ---
  // Substitua este método pelo conteúdo do arquivo 'modelo_ia_prenhez.dart' gerado no Colab.
  // Esta versão manual reflete a lógica exata do seu script Python para funcionamento imediato.
  static double score(List<double> input) {
    double rebanho = input[0];
    double raca = input[1];
    double idade = input[2];
    double escore = input[4];
    double partos = input[5];
    double dpp = input[6];
    double thi = input[7];

    double chance = 0.80;

    // 1. Nutrição (Fator Dominante)
    if (escore <= 2) chance -= 0.30;
    else if (escore == 5) chance -= 0.15;
    else if (escore == 4) chance += 0.05;

    // 2. Histórico
    if (partos == 1) chance -= 0.08;
    if (partos > 0 && dpp < 50) chance -= 0.15;
    if (idade > 52) chance -= 0.10;

    // 3. Bioclimatologia
    double limiar = (rebanho == 2) ? 70.0 : (rebanho == 1 ? 74.0 : 78.0);
    if (thi > limiar) {
      if (raca == 2 || raca == 3) { // Exóticas
        chance -= (escore >= 4) ? 0.15 : 0.35;
      } else if (raca == 4) { // SRD
        chance -= 0.08;
      } else { // Nativas (0, 1)
        chance -= 0.02;
      }
    }

    return chance.clamp(0.15, 0.92);
  }
  // --- FIM DO CÓDIGO GERADO ---

  // Mapeadores de Categoria (Sincronizados com o Python)
  static double mapRebanho(String? cat) {
    switch (cat) {
      case 'Caprino': return 0.0;
      case 'Ovino': return 1.0;
      case 'Bovino': return 2.0;
      default: return 2.0;
    }
  }

  static double mapRaca(String? raca) {
    if (raca == null) return 4.0;
    if (raca.contains("Nativa Pura")) return 0.0;
    if (raca.contains("Mestiço Sertanejo")) return 1.0;
    if (raca.contains("Mestiço Exótico")) return 2.0;
    if (raca.contains("Exótica Pura")) return 3.0;
    return 4.0; // SRD / Comum
  }

  static double mapParidade(String? p) {
    switch (p) {
      case 'Nulípara': return 0.0;
      case 'Primípara': return 1.0;
      case 'Multípara': return 2.0;
      default: return 0.0;
    }
  }
}
