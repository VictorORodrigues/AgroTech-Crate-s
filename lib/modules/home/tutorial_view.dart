import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TutorialView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Central de Ajuda AgroGen", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("🚀 GUIA RÁPIDO DE USO", Icons.auto_awesome_outlined),
            _buildStep("1. Organize seus Rebanhos", "Crie categorias lógicas. Ex: 'Lote de Cria Bovino' ou 'Matrizes Caprinas Crateús'."),
            _buildStep("2. Cadastro de Animais", "Acesse o rebanho e adicione os animais. Informe dados técnicos como Escore Corporal (ECC) e Linhagem para melhores resultados na IA."),
            _buildStep("3. IA de Prenhez", "Clique no botão verde na Home para prever o sucesso da inseminação. A IA lerá o clima (THI) de Crateús automaticamente."),
            _buildStep("4. Melhoramento Genético", "Use o 'Ranking de Reprodutores' para encontrar o macho ideal para sua matriz, evitando consanguinidade."),
            
            const Divider(height: 40),
            
            _buildSectionHeader("❓ PERGUNTAS FREQUENTES (FAQ)", Icons.help_outline),
            _buildFAQ("O aplicativo realmente funciona sem internet?", "Sim! Fomos projetados para o produtor rural. Todo o processamento de Machine Learning e o banco de dados rodam localmente no chip do seu celular."),
            _buildFAQ("O que é o THI e por que ele importa?", "O THI (Índice de Temperatura e Umidade) mede o estresse térmico. Em Crateús, o THI alto pode reduzir a taxa de prenhez em até 40%. Nossa IA avisa o momento exato de adiar o manejo."),
            _buildFAQ("Como é feito o cálculo do match genético?", "Analisamos o parentesco (linhagem e pai) para bloquear consanguinidade e pontuamos a aptidão do macho (Rústico vs Alta Produção) de acordo com o seu tipo de manejo."),
            _buildFAQ("Como sincronizo meus dados?", "Sempre que tiver internet, use a opção de 'Backup em Nuvem' nas configurações ou no menu lateral para salvar seus dados nos servidores seguros do AgroGen."),

            const Divider(height: 40),

            _buildSectionHeader("📖 GLOSSÁRIO TÉCNICO", Icons.menu_book_outlined),
            _buildGlossaryItem("ECC (Escore Corporal)", "Nota de 1 a 5 que mede a reserva de gordura. Animal magro (1-2) não ovula corretamente."),
            _buildGlossaryItem("Involução Uterina", "Tempo necessário para o útero da fêmea voltar ao normal após o parto."),
            _buildGlossaryItem("Edge AI", "Inteligência Artificial que processa dados na borda (no dispositivo), sem depender de servidores remotos."),

            const Divider(height: 40),

            _buildSectionHeader("📞 FALE CONOSCO", Icons.support_agent_outlined),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("Dúvidas ou problemas no campo?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildContactCard(Icons.email_outlined, "E-mail:", "suporte@agrogen.com.br"),
                  _buildContactCard(Icons.phone_android, "WhatsApp Suporte:", "(88) 99876-5432"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.snackbar("Suporte", "Abrindo chamado técnico..."),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("FALAR COM UM VETERINÁRIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[800], size: 24),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green[900], letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFAQ(String q, String r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(r, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: "$term: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            TextSpan(text: definition, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.green[800]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
