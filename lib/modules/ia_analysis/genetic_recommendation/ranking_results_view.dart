import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ranking_abs_controller.dart';
import '../../../utils/agro_alerts.dart';

class RankingResultsView extends StatelessWidget {
  final RankingABSController controller = Get.find<RankingABSController>();

  @override
  Widget build(BuildContext context) {
    const List<Color> gradientColors = [
      Color(0xFF0A1F12), // Deep Forest Green
      Color(0xFF132E1D), // Dark Moss
      Color(0xFF1B4332), // Emerald Depth
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              _buildMatrixHeader(),
              Expanded(
                child: Obx(() {
                  if (controller.ranking.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: controller.ranking.length,
                    itemBuilder: (context, index) {
                      return _buildFuturisticRankCard(index);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
          const Text(
            'RECOMENDAÇÃO IA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontSize: 14,
            ),
          ),
          const Opacity(opacity: 0, child: IconButton(icon: Icon(Icons.close), onPressed: null)),
        ],
      ),
    );
  }

  Widget _buildMatrixHeader() {
    final matrix = controller.selectedMatrix.value;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF40C057).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.female, color: Color(0xFF40C057), size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MATRIZ: ${matrix?['identifier']}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
              ),
              Text(
                "${matrix?['breed']} • ${matrix?['aptitude'] ?? 'Rústica'}",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticRankCard(int index) {
    final result = controller.ranking[index];
    final isBlocked = result.isBlocked;
    final isTop = index == 0 && !isBlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isTop 
                  ? const Color(0xFF40C057).withOpacity(0.08) 
                  : (isBlocked ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isTop 
                    ? const Color(0xFF40C057).withOpacity(0.3) 
                    : (isBlocked ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
                width: isTop ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isTop ? const Color(0xFF40C057) : (isBlocked ? Colors.redAccent : Colors.white24),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isTop || isBlocked ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.male.identifier,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${result.male.breed} • ${result.male.lineage}",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildScoreBadge(result.score, isBlocked, isTop),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      "JUSTIFICATIVA TÉCNICA",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...result.justifications.map((j) => _buildJustificationLine(j, isBlocked)),
                if (isTop) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => AgroAlert.show(title: "Excelente Escolha!", message: "Reprodutor recomendado para este acasalamento estratégico.", isSuccess: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40C057),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("SELECIONAR PARA MONTA", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score, bool isBlocked, bool isTop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isBlocked ? "BLOQUEADO" : "${score.toStringAsFixed(1)}% MATCH",
        style: TextStyle(
          color: isBlocked ? Colors.redAccent : (isTop ? const Color(0xFF40C057) : Colors.white),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildJustificationLine(String text, bool isBlocked) {
    bool isWarning = text.contains("BLOQUEIO") || text.contains("Risco") || text.contains("penalizado");
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
            size: 14,
            color: isWarning ? Colors.redAccent : const Color(0xFF40C057),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.white.withOpacity(0.2), size: 64),
          const SizedBox(height: 16),
          Text(
            "Nenhum reprodutor disponível para análise.",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
