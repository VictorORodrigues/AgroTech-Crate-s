import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Central de Notificações", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryHeader("Alertas Bioclimáticos", Icons.wb_sunny_outlined),
          _buildNotificationCard(
            title: "Calor Crítico no Confinamento!",
            message: "O índice THI atingiu 78 nesta tarde. Evite inseminar as vacas exóticas (como a Holandesa 'Majestosa') nas próximas 4 horas. A chance de sucesso caiu para 22% devido ao estresse térmico.",
            type: "warning",
            icon: Icons.warning_amber_rounded,
          ),
          _buildNotificationCard(
            title: "Janela de Inseminação Liberada",
            message: "O clima esfriou e o THI caiu para 68. Momento ideal para realizar o procedimento nas matrizes agendadas e garantir máxima eficiência do sêmen.",
            type: "success",
            icon: Icons.check_circle_outline,
          ),
          
          const SizedBox(height: 24),
          _buildCategoryHeader("Casamento Genético e Manejo", Icons.account_tree_outlined),
          _buildNotificationCard(
            title: "Aviso de Segurança Genética",
            message: "Identificamos que o touro 'Chubby_Bull' entrou no seu catálogo local. Atenção: ele possui parentesco direto com 5 novilhas do seu lote A. O aplicativo já bloqueou esse cruzamento para evitar bezerros fracos.",
            type: "warning",
            icon: Icons.block_flipped,
          ),
          _buildNotificationCard(
            title: "Match Perfeito Disponível",
            message: "A vaca 'Sertaneja' atingiu o Escore Corporal ideal (Nota 4) hoje. Como o seu manejo é Intensivo, o sistema recomenda o sêmen do touro 'Majestoso' para gerar bezerros pesados de corte.",
            type: "info",
            icon: Icons.star_outline,
          ),

          const SizedBox(height: 24),
          _buildCategoryHeader("Insights Inteligentes do Rebanho", Icons.psychology_outlined),
          _buildNotificationCard(
            title: "Novas Matrizes de Elite Detectadas",
            message: "Nossa IA analisou o histórico e identificou um grupo de 8 cabras (lote de cria) que mantiveram a fertilidade acima de 85% mesmo no pico da seca. Guarde a genética dessas fêmeas!",
            type: "success",
            icon: Icons.auto_awesome_outlined,
          ),
          _buildNotificationCard(
            title: "Alerta de Alinhamento Reprodutivo",
            message: "O grupo de ovelhas jovens (Linhagem PI_D) está precisando de 3 tentativas a mais de monta para emprenhar em comparação com o resto do rebanho. Sugerimos revisar a nutrição desse lote.",
            type: "error",
            icon: Icons.analytics_outlined,
          ),

          const SizedBox(height: 24),
          _buildCategoryHeader("Manejo Reprodutivo e Rotina", Icons.calendar_today_outlined),
          _buildNotificationCard(
            title: "'Mimosa' está pronta",
            message: "A fêmea completou 60 dias pós-parto e apresenta escore de saúde excelente. A IA liberou a recomendação de reprodutores para ela.",
            type: "info",
            icon: Icons.check_circle_outline,
          ),
          _buildNotificationCard(
            title: "Confirmação de Prenhez",
            message: "Já se passaram 45 dias desde a cobertura da cabra 'Cabrita_01'. Hora de fazer o exame de toque ou ultrassom para confirmar a prenhez e atualizar o app.",
            type: "info",
            icon: Icons.hourglass_bottom,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[800]),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String type,
    required IconData icon,
  }) {
    Color color;
    Color bgColor;

    switch (type) {
      case "warning":
        color = Colors.orange[800]!;
        bgColor = Colors.orange[50]!;
        break;
      case "success":
        color = Colors.green[800]!;
        bgColor = Colors.green[50]!;
        break;
      case "error":
        color = Colors.red[800]!;
        bgColor = Colors.red[50]!;
        break;
      case "info":
      default:
        color = Colors.blue[800]!;
        bgColor = Colors.blue[50]!;
        break;
    }

    final isDark = Get.context!.theme.brightness == Brightness.dark;
    if (isDark) {
      bgColor = color.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Get.context!.theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
