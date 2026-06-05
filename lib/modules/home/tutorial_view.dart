import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TutorialView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: textColor),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          "Central de Ajuda",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("🚀 GUIA RÁPIDO", Icons.auto_awesome_outlined),
            _buildStepCard(
              "1. Rebanhos", 
              "Organize seus animais por categorias lógicas no menu principal.",
              Icons.pets_outlined,
              Colors.blue
            ),
            _buildStepCard(
              "2. Animais", 
              "Cadastre individualmente com dados de ECC e linhagem para IA precisa.",
              Icons.add_circle_outline,
              Colors.green
            ),
            _buildStepCard(
              "4. Manejo Técnico", 
              "Registre pesagens, vacinas e partos para alimentar o histórico de cada animal.",
              Icons.assignment_turned_in_outlined,
              Colors.orange
            ),
            _buildStepCard(
              "5. Rastreabilidade Digital", 
              "Acesse o QR Code no perfil do animal para gerar um link público de rastreio.",
              Icons.qr_code_2_outlined,
              Colors.blueGrey
            ),
            _buildStepCard(
              "6. Mercado e Lucro", 
              "Acompanhe as cotações regionais e o ROI genético no seu Dashboard.",
              Icons.trending_up,
              Colors.teal
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader("❓ DÚVIDAS COMUNS", Icons.help_outline),
            _buildFAQ("Funciona sem internet?", "Sim! O AgroTech processa tudo localmente e sincroniza quando detectar sinal."),
            _buildFAQ("O que é o THI?", "É o índice de estresse térmico. Se estiver alto, a fertilidade do animal cai drasticamente."),
            _buildFAQ("Como fazer backup?", "Vá em Perfil > Configurações do Sistema > Sincronizar Agora."),
            _buildFAQ("Como a IA sugere o reprodutor?", "Analisamos o parentesco para evitar consanguinidade e pontuamos a aptidão do macho de acordo com o seu manejo."),
            _buildFAQ("O que fazer no THI alto?", "Priorize sombra, aspersão de água e evite manejos estressantes como vacinação ou transporte."),
            _buildFAQ("Como funciona o QR Code?", "Cada animal tem um link único na nuvem. Ao ler o QR Code, qualquer pessoa (como um comprador) pode ver a ficha técnica e o histórico de vacinas sem precisar baixar o app."),
            _buildFAQ("O que é o Custo do Ócio?", "É o dinheiro que você perde mantendo uma fêmea vazia. O app calcula isso baseado no custo diário de ração e dias sem produzir cria."),
            _buildFAQ("Como cadastrar um parto?", "Vá no perfil da fêmea e adicione uma nova atividade do tipo 'Nascimento'. O sistema criará o bezerro automaticamente para você."),
            _buildFAQ("A IA substitui o veterinário?", "Não! A IA AgroGen é uma ferramenta de suporte à decisão. Ela ajuda a identificar problemas e otimizar janelas de tempo, mas o diagnóstico clínico final deve ser feito por um profissional."),
            _buildFAQ("Como ver o gráfico de lucro?", "Acesse o menu lateral ou a Home e clique em 'Relatórios'. Lá você verá o fluxo de caixa projetado e o impacto financeiro das suas decisões reprodutivas."),
            _buildFAQ("O que é o Match Genético?", "É a nossa funcionalidade de recomendação que cruza dados de linhagem do macho e da fêmea para maximizar a heterose (choque de sangue) e evitar doenças genéticas por parentesco."),

            const SizedBox(height: 32),
            _buildSectionHeader("📖 CONCEITOS TÉCNICOS", Icons.menu_book_outlined),
            _buildGlossaryBox("ECC", "Escore de Condição Corporal (1 a 5). Mede as reservas energéticas do animal. Ideal para reprodução é entre 3.0 e 4.0."),
            _buildGlossaryBox("IEP", "Intervalo Entre Partos. O tempo decorrido entre dois nascimentos consecutivos de uma mesma matriz."),
            _buildGlossaryBox("IPC", "Índice de Inseminações por Concepção. Quantas doses de sêmen são necessárias, em média, para a fêmea emprenhar."),
            _buildGlossaryBox("THI", "Temperature Humidity Index. Medida técnica do nível de estresse calórico. Acima de 78 indica perigo para a fertilidade."),
            _buildGlossaryBox("IATF", "Inseminação Artificial em Tempo Fixo. Protocolo hormonal para sincronizar o cio e otimizar o manejo reprodutivo."),
            _buildGlossaryBox("Heterose", "Também chamado de 'Choque de Sangue'. É o ganho de desempenho obtido através do cruzamento de raças diferentes."),
            _buildGlossaryBox("GMD", "Ganho Médio Diário. Quantos quilos o animal ganha por dia de vida. Essencial para medir eficiência na engorda."),
            _buildGlossaryBox("PVE", "Período Voluntário de Espera. Tempo após o parto que o útero precisa para se recuperar antes de uma nova inseminação."),
            _buildGlossaryBox("Involução Uterina", "Processo natural onde o útero retorna ao tamanho e estado normal após o parto."),
            _buildGlossaryBox("Score IA", "Pontuação de 0 a 100 gerada pelo nosso algoritmo indicando a prontidão reprodutiva do animal."),
            _buildGlossaryBox("Linhagem", "Origem genética do animal, rastreando seus ascendentes diretos (Pai, Mãe, Avós)."),
            _buildGlossaryBox("Edge AI", "Tecnologia de Inteligência Artificial que processa dados pesados no próprio celular, garantindo velocidade e privacidade offline."),
            _buildGlossaryBox("ROI Genético", "Retorno sobre o Investimento Genético. Cálculo do lucro extra obtido ao usar reprodutores de alta performance."),
            _buildGlossaryBox("Rastreabilidade", "Capacidade de acompanhar o histórico de um animal desde o nascimento até a venda final via QR Code."),
            _buildGlossaryBox("Manejo Bioclimático", "Conjunto de ações (sombra, aspersão, horários) para mitigar o impacto do clima no desempenho animal."),

            const SizedBox(height: 80),
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
          Icon(icon, color: Colors.green[800], size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green[800], letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildStepCard(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Get.context!.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(String q, String r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Get.context!.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(r, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossaryBox(String term, String def) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[800]!.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green[800]!.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green[900], fontSize: 14, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(def, style: TextStyle(color: Get.context!.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

