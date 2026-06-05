import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dashboard_controller.dart';
import '../../services/report_service.dart';
import '../../utils/agro_alerts.dart';

class ReportsView extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());

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
          "Inteligência AgroGen",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadDashboardData(),
        color: Colors.green[800],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SELEÇÃO DE FILTROS GLOBAIS
              _buildGlobalFilterBar(isDark),
              
              const SizedBox(height: 24),

              // 2. KPIS FINANCEIROS (Impacto direto)
              _buildFinancialKPIs(cardColor, isDark),

              const SizedBox(height: 24),

              // 3. GRÁFICO DE EVOLUÇÃO (Receita vs Despesa)
              _buildMainEvolutionChart(cardColor, isDark),

              const SizedBox(height: 24),

              // 4. MÓDULO REPRODUTIVO (Eficiência)
              _buildReproductiveModule(cardColor, isDark),

              const SizedBox(height: 24),

              // 5. RANKING ELITE (Matrizes de Performance)
              _buildEliteRanking(cardColor, isDark),

              const SizedBox(height: 24),

              // 6. PRÓXIMOS MANEJOS (IA Preditiva)
              _buildPredictiveManejos(cardColor, isDark),

              const SizedBox(height: 40),
              
              // AÇÃO FINAL: EXPORTAÇÃO
              _buildExportButtons(),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFilterBar(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildFilterChip('Geral', 'Geral', Icons.dashboard_customize_outlined, isDark),
              const SizedBox(width: 12),
              _buildFilterChip('Bovino', 'Bovinos', Icons.pets, isDark),
              const SizedBox(width: 12),
              _buildFilterChip('Caprino', 'Caprinos', Icons.agriculture, isDark),
              const SizedBox(width: 12),
              _buildFilterChip('Ovino', 'Ovinos', Icons.set_meal, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedPeriod.value,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            prefixIcon: const Icon(Icons.calendar_month, size: 18),
          ),
          items: ["Últimos 30 dias", "Últimos 6 meses", "Este Ano", "Personalizado"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
          onChanged: controller.updatePeriod,
        )),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, bool isDark) {
    return Obx(() {
      final isSelected = controller.selectedSpecies.value == value;
      return GestureDetector(
        onTap: () => controller.updateSpecies(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[800] : (isDark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.green[800]! : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              if (isSelected) BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFinancialKPIs(Color cardColor, bool isDark) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("IMPACTO FINANCEIRO", Icons.account_balance_wallet_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildKPIBox(
                "Receita Bruta", 
                fmt.format(controller.totalRevenue.value), 
                "Ganhos do Período", 
                Colors.green,
                cardColor
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => _buildKPIBox(
                "Custo do Ócio", 
                fmt.format(controller.idleCost.value), 
                "Prejuízo com Vazias", 
                Colors.redAccent,
                cardColor
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainEvolutionChart(Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fluxo de Caixa IA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text("Gastos vs Receitas Projetadas", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot(Colors.green, "Receita"),
                  const SizedBox(width: 12),
                  _buildLegendDot(Colors.redAccent, "Gastos"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: Obx(() => LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.05))),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'][v.toInt() % 6], style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: controller.revenueTimeline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true, color: Colors.green, barWidth: 4, dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.05)),
                  ),
                  LineChartBarData(
                    spots: controller.expensesTimeline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true, color: Colors.redAccent, barWidth: 3, dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildReproductiveModule(Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("EFICIÊNCIA REPRODUTIVA", Icons.auto_graph_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: [
              const Text("Distribuição de Status de Matrizes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(height: 180, child: _buildStatusPieChart()),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Obx(() => _buildMiniStat("Taxa de Prenhez", "${controller.pregnancyRate.value}%", Colors.green))),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  Expanded(child: Obx(() => _buildMiniStat("IEP Médio", "${controller.avgIEP.value} meses", controller.avgIEP.value > 12.5 ? Colors.red : Colors.blue))),
                ],
              ),
              const Divider(height: 48),
              const Text("Taxa de Concepção por Método", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(height: 160, child: _buildMethodBarChart()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEliteRanking(Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("MATRIZES ELITE (TOP 5)", Icons.workspace_premium_outlined),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
          child: Obx(() => DataTable(
            horizontalMargin: 20,
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text('Identificador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Linhagem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Crias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('GMD Cria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
            rows: controller.eliteMatrix.map((m) => DataRow(cells: [
              DataCell(Text(m['identifier'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
              DataCell(Text(m['lineage'] ?? "S/L", style: const TextStyle(fontSize: 11))),
              DataCell(Text(m['crias'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text("${(m['gmd'] ?? 0.0).toStringAsFixed(2)}kg", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
            ])).toList(),
          )),
        ),
      ],
    );
  }

  Widget _buildPredictiveManejos(Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("IA PREDITIVA: PRÓXIMOS 7 DIAS", Icons.psychology_outlined),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.upcomingEvents.isEmpty) {
            return _buildEmptyTaskCard(cardColor);
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.upcomingEvents.length,
            itemBuilder: (context, index) {
              final e = controller.upcomingEvents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.bolt, color: Colors.orange, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Animal ${e['identifier']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(e['description'] ?? e['type'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(DateFormat('dd/MM').format(DateTime.parse(e['date'])), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[800]),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildKPIBox(String label, String value, String sub, Color color, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildStatusPieChart() {
    return Obx(() => PieChart(
      PieChartData(
        sectionsSpace: 6,
        centerSpaceRadius: 50,
        sections: controller.matrixStatusData.entries.map((e) {
          return PieChartSectionData(
            color: _getPieColor(e.key), 
            value: e.value, 
            title: '${e.value.toInt()}',
            radius: 40,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    ));
  }

  Color _getPieColor(String status) {
    if (status.contains("Prenhe")) return Colors.green;
    if (status.contains("Vazia")) return Colors.redAccent;
    if (status.contains("Lactação")) return Colors.blue;
    return Colors.orange;
  }

  Widget _buildMethodBarChart() {
    return Obx(() => BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(v == 0 ? "IA / IATF" : "Monta Natural", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: controller.conceptionRates['IA'] ?? 75.0, color: Colors.blue, width: 30, borderRadius: BorderRadius.circular(8))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: controller.conceptionRates['Monta'] ?? 55.0, color: Colors.orange, width: 30, borderRadius: BorderRadius.circular(8))]),
        ],
      ),
    ));
  }

  Widget _buildLegendDot(Color c, String t) {
    return Row(children: [CircleAvatar(radius: 4, backgroundColor: c), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))]);
  }

  Widget _buildEmptyTaskCard(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.withOpacity(0.3), size: 48),
          const SizedBox(height: 12),
          const Text("Agenda Livre", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("Nenhum manejo crítico para a próxima semana.", style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => ReportService.generateAndShareCSV(), icon: const Icon(Icons.table_chart_outlined), label: const Text("Exportar CSV", style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: () => ReportService.generateAndSharePDF(), icon: const Icon(Icons.picture_as_pdf, color: Colors.white), label: const Text("Gerar PDF Técnico", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]))),
      ],
    );
  }
}
