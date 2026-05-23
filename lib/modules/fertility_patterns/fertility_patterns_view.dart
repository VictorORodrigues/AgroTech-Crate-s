import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

/// --- MÓDULO DE PADRÕES DE FERTILIDADE (CLUSTERING IA) ---
/// Esta tela materializa a descoberta de padrões ocultos no rebanho
/// usando lógica de agrupamento (K-Means) simulada para o Pitch.

class FertilityPatternsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agroDarkGreen = Colors.green[900]!;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Padrões de Fertilidade", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. O GARIMPO DA IA (LOTES INTELIGENTES)
            _buildSectionHeader("O Garimpo da IA", Icons.auto_awesome_mosaic_outlined),
            const SizedBox(height: 12),
            _buildLoteCard(
              title: "Grupo 'Super-Rústicas'",
              message: "A IA descobriu 14 matrizes que mantêm 88% de taxa de prenhez mesmo com THI > 78. Genética preciosa para o Sertão!",
              color: Colors.green,
              icon: Icons.star,
              count: 14,
            ),
            _buildLoteCard(
              title: "Alerta de Desgaste",
              message: "Padrão detectado: Primíparas sentindo o estresse energético da amamentação. Precisam de reforço no cocho.",
              color: Colors.orange,
              icon: Icons.warning_amber_rounded,
              count: 22,
            ),
            _buildLoteCard(
              title: "Zona de Baixa Eficiência",
              message: "Queda de 40% na fertilidade detectada. O peso deste lote caiu rápido no último mês, verifique a nutrição.",
              color: Colors.red,
              icon: Icons.trending_down,
              count: 9,
            ),

            const SizedBox(height: 32),

            // 2. GRÁFICO DE DISPERSÃO (SCATTER PLOT)
            _buildSectionHeader("Dispersão de Desempenho", Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            _buildScatterChart(isDark),
            
            const SizedBox(height: 32),

            // 3. ÍNDICE DE REPETIBILIDADE
            _buildSectionHeader("Índice de Repetibilidade", Icons.history_edu_outlined),
            const SizedBox(height: 16),
            _buildRepeatabilityMeters(agroDarkGreen),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[800], size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoteCard({
    required String title,
    required String message,
    required MaterialColor color,
    required IconData icon,
    required int count,
  }) {
    final context = Get.context!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50.withOpacity(context.isDarkMode ? 0.1 : 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.isDarkMode ? color.shade200 : color.shade900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                      child: Text("$count animais", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message, style: TextStyle(fontSize: 13, color: context.isDarkMode ? Colors.grey[400] : color.shade800, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScatterChart(bool isDark) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            // Elite (Verde)
            ScatterSpot(4.0, 1.1, dotPainter: FlDotCirclePainter(color: Colors.green, radius: 6)),
            ScatterSpot(4.2, 1.2, dotPainter: FlDotCirclePainter(color: Colors.green, radius: 6)),
            ScatterSpot(3.8, 1.0, dotPainter: FlDotCirclePainter(color: Colors.green, radius: 6)),
            // Alerta (Laranja)
            ScatterSpot(3.0, 2.2, dotPainter: FlDotCirclePainter(color: Colors.orange, radius: 5)),
            ScatterSpot(3.2, 2.5, dotPainter: FlDotCirclePainter(color: Colors.orange, radius: 5)),
            ScatterSpot(2.8, 2.0, dotPainter: FlDotCirclePainter(color: Colors.orange, radius: 5)),
            // Crítico (Vermelho)
            ScatterSpot(1.5, 4.0, dotPainter: FlDotCirclePainter(color: Colors.red, radius: 4)),
            ScatterSpot(2.0, 3.5, dotPainter: FlDotCirclePainter(color: Colors.red, radius: 4)),
            ScatterSpot(1.8, 4.2, dotPainter: FlDotCirclePainter(color: Colors.red, radius: 4)),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Escore Corporal (Nutrição)", style: TextStyle(fontSize: 10)),
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Insem. / Prenhez", style: TextStyle(fontSize: 10)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildRepeatabilityMeters(Color dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildMeterItem("Linhagem Sertão_A", 0.82),
          const SizedBox(height: 16),
          _buildMeterItem("Linhagem Vale_C", 0.65),
          const SizedBox(height: 16),
          _buildMeterItem("Linhagem PI_D", 0.45),
        ],
      ),
    );
  }

  Widget _buildMeterItem(String label, double value) {
    final color = value > 0.75 ? Colors.green : (value > 0.50 ? Colors.orange : Colors.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text("${(value * 100).toInt()}% constância", style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
