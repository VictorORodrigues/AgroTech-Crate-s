import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'fertility_patterns_controller.dart';

class FertilityPatternsView extends StatelessWidget {
  final FertilityPatternsController controller = Get.put(FertilityPatternsController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E08) : const Color(0xFFF5F5F7),
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
          "Padrões de Fertilidade IA",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Visão Individual"),
            Tab(text: "Visão por Rebanho"),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        }
        return TabBarView(
          controller: controller.tabController,
          children: [
            _buildIndividualTab(cardColor, textColor, isDark),
            _buildHerdTab(cardColor, textColor, isDark),
          ],
        );
      }),
    );
  }

  Widget _buildIndividualTab(Color cardColor, Color textColor, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      color: Colors.greenAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalStats(isDark),
            const SizedBox(height: 32),
            _buildSectionTitle("DISTRIBUIÇÃO POR PERFORMANCE", Icons.pie_chart_outline),
            const SizedBox(height: 16),
            _buildDonutChart(cardColor),
            const SizedBox(height: 32),
            _buildSectionTitle("ANÁLISE PREDITIVA INDIVIDUAL", Icons.psychology_outlined),
            const SizedBox(height: 16),
            ...controller.individualInsights.map((i) => _buildIndividualCard(i, cardColor, textColor)).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHerdTab(Color cardColor, Color textColor, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      color: Colors.greenAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("RANKING DE SUCESSO (IATF/MONTA)", Icons.leaderboard_outlined),
            const SizedBox(height: 16),
            _buildHerdSuccessChart(cardColor),
            const SizedBox(height: 32),
            _buildSectionTitle("MÉTRICAS POR LOTE", Icons.groups_outlined),
            const SizedBox(height: 16),
            ...controller.herdMetrics.map((h) => _buildHerdMetricCard(h, cardColor, textColor)).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.greenAccent.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.greenAccent.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("SCORE AGROGEN", "${controller.overallFertilityScore.value}%", Colors.greenAccent),
              _buildStatItem("IEP FAZENDA", "${controller.avgIEPFarm.value}m", Colors.white),
              _buildStatItem("TAXA IPC", "${controller.avgIPCFarm.value}", Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Módulo de IA: Detectamos uma melhora de 12% na taxa de concepção nas últimas 3 semanas.",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildIndividualCard(Map<String, dynamic> animal, Color cardColor, Color textColor) {
    final statusColor = _getStatusColor(animal['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.female, color: statusColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(animal['identifier'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(animal['breed'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(animal['status'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric("Score IA", "${animal['score'].toInt()}%", statusColor),
              _buildMiniMetric("IEP", "${animal['iep'].toStringAsFixed(1)}m", textColor),
              _buildMiniMetric("IPC", animal['ipc'].toStringAsFixed(1), textColor),
            ],
          ),
          const Divider(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  animal['comment'],
                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHerdMetricCard(Map<String, dynamic> herd, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: (herd['success_rate'] / 100),
            backgroundColor: Colors.grey.withOpacity(0.1),
            color: Colors.greenAccent,
            strokeWidth: 6,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(herd['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${herd['category']} • ${herd['females']} fêmeas", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${herd['success_rate'].toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.greenAccent)),
              const Text("SUCESSO", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDonutChart(Color cardColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(color: Colors.blueAccent, value: 30, title: 'Elite', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(color: Colors.orangeAccent, value: 50, title: 'Atenção', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(color: Colors.redAccent, value: 20, title: 'Risco', radius: 30, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildHerdSuccessChart(Color cardColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: controller.herdMetrics.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: e.value['success_rate'], color: Colors.greenAccent, width: 20, borderRadius: BorderRadius.circular(4))],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(controller.herdMetrics[v.toInt()]['name'].substring(0, 3), style: const TextStyle(fontSize: 9)))),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
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

  Widget _buildMiniMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      ],
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

  Color _getStatusColor(String status) {
    if (status == 'Elite') return Colors.blueAccent;
    if (status == 'Atenção') return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
