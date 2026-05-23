import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/agro_alerts.dart';
import '../../services/report_service.dart';

/// --- DASHBOARD ANALÍTICO AGROGEN ---
/// Esta tela representa o núcleo de inteligência de dados do aplicativo.
/// Ela consolida métricas reprodutivas e climáticas em uma interface moderna.

class ReportsView extends StatefulWidget {
  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  // Estado local para simular filtros (Mock de dados para o Hackathon)
  String selectedSpecies = "Consolidado";
  String selectedPeriod = "Últimos 6 meses";

  @override
  Widget build(BuildContext context) {
    final agroDarkGreen = Colors.green[900]!;
    final agroSoftGreen = Colors.green[50]!;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Dashboard Analítico", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SISTEMA DE FILTROS (Chips Interativos)
                _buildFiltersSection(agroSoftGreen, agroDarkGreen),
                
                const SizedBox(height: 24),
                
                // 2. GRID DE KPIs (Métricas de Desempenho)
                _buildKPIGrid(isDark),

                const SizedBox(height: 24),

                // 3. GRÁFICO DE EVOLUÇÃO (Prenhez vs THI)
                _buildEvolutionChart(isDark, agroDarkGreen),

                const SizedBox(height: 24),

                // 4. LISTA DE INSIGHTS RÁPIDOS
                _buildSmartInsights(isDark),

                const SizedBox(height: 80), // Espaço para barra inferior
              ],
            ),
          ),
        ),
      ),
      // 5. BARRA DE EXPORTAÇÃO (Ações do Produtor)
      bottomSheet: _buildExportBar(isDark),
    );
  }

  Widget _buildFiltersSection(Color soft, Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["Consolidado", "Bovinos", "Caprinos", "Ovinos"].map((s) {
              bool isSelected = selectedSpecies == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: isSelected,
                  selectedColor: Colors.green[800],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  onSelected: (val) => setState(() => selectedSpecies = s),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedPeriod,
          isExpanded: true,
          underline: Container(),
          icon: const Icon(Icons.calendar_month, size: 18),
          items: ["Últimos 30 dias", "Últimos 6 meses", "Safra Atual"].map((p) {
            return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (v) => setState(() => selectedPeriod = v!),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildKPICard(
          title: "Taxa de Prenhez",
          value: "78.4%",
          subtitle: "+2.1% vs anterior",
          icon: Icons.trending_up,
          color: Colors.green,
          isCircular: true,
        ),
        _buildKPICard(
          title: "Matrizes Ativas",
          value: "142 / 185",
          subtitle: "Confirmadas Prenhes",
          icon: Icons.female,
          color: Colors.blue,
        ),
        _buildKPICard(
          title: "Média ECC",
          value: "3.4",
          subtitle: "Escore Ideal",
          icon: Icons.health_and_safety_outlined,
          color: Colors.orange,
        ),
        _buildKPICard(
          title: "Sêmen Salvo",
          value: "22 doses",
          subtitle: "Evitado pela IA (Calor)",
          icon: Icons.savings_outlined,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isCircular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (isCircular)
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(value: 0.78, strokeWidth: 3, color: color, backgroundColor: color.withOpacity(0.1)),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
            ],
          ),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(bool isDark, Color darkGreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Taxa de Prenhez vs Calor (THI)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text("Análise de impacto climático semestral", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(["Jan", "Fev", "Mar", "Abr", "Mai", "Jun"][val.toInt() % 6], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 70), FlSpot(1, 75), FlSpot(2, 65), FlSpot(3, 80), FlSpot(4, 85), FlSpot(5, 78)],
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 80), FlSpot(1, 82), FlSpot(2, 85), FlSpot(3, 75), FlSpot(4, 70), FlSpot(5, 72)],
                    isCurved: true,
                    color: Colors.orange.withOpacity(0.5),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green, "Taxa Prenhez (%)"),
              const SizedBox(width: 20),
              _buildLegend(Colors.orange, "Índice THI (Calor)"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color c, String t) {
    return Row(children: [CircleAvatar(radius: 4, backgroundColor: c), const SizedBox(width: 6), Text(t, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
  }

  Widget _buildSmartInsights(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Insights da IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildInsightItem(
          "O THI médio de Crateús caiu 4 pontos este mês, aumentando a janela de inseminação em 3 horas diárias.",
          Icons.auto_awesome,
          Colors.amber,
        ),
        _buildInsightItem(
          "Lote B apresenta ECC abaixo do ideal (2.8). Suplementação recomendada para atingir meta de 80% de prenhez.",
          Icons.info_outline,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildExportBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ReportService.generateAndShareCSV();
                } catch (e) {
                  AgroAlert.show(title: "Erro", message: e.toString(), isError: true);
                }
              },
              icon: const Icon(Icons.table_view_outlined, size: 18),
              label: const Text("Planilha CSV", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ReportService.generateAndSharePDF();
                } catch (e) {
                  AgroAlert.show(title: "Erro", message: e.toString(), isError: true);
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
              label: const Text("Relatório PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
