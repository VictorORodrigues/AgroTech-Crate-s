import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ranking_abs_controller.dart';
import '../../../utils/agro_alerts.dart';

class RankingResultsView extends StatelessWidget {
  final RankingABSController controller = Get.find<RankingABSController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: const Text('Recomendações Genéticas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[900],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Matriz: ${controller.selectedMatrix.value?['identifier']} (${controller.selectedMatrix.value?['category']})",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.ranking.isEmpty) {
                return const Center(child: Text("Nenhum reprodutor compatível encontrado."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.ranking.length,
                itemBuilder: (context, index) {
                  final result = controller.ranking[index];
                  final isBlocked = result.score < 0;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isBlocked ? Colors.red.shade200 : (index == 0 ? Colors.green : Colors.transparent),
                        width: 2
                      )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${index + 1}º Lugar: ${result.reprodutor.identifier}",
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold,
                                        color: isBlocked ? Colors.red[800] : Colors.black87
                                      ),
                                    ),
                                    Text(
                                      "Raça: ${result.reprodutor.breed} | Linhagem: ${result.reprodutor.lineage}",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isBlocked 
                                    ? (context.theme.brightness == Brightness.dark ? Colors.red[900]!.withOpacity(0.3) : Colors.red[50])
                                    : (index == 0 
                                      ? (context.theme.brightness == Brightness.dark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50])
                                      : context.theme.cardColor),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Score: ${result.score.toStringAsFixed(1)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isBlocked ? Colors.red[800] : (index == 0 ? Colors.green[800] : Colors.grey[700])
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Text("Explicação da IA:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          ...result.justifications.map((j) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  j.contains("BLOQUEIO") ? Icons.block : (j.contains("+") ? Icons.check_circle : Icons.info),
                                  size: 14, 
                                  color: j.contains("BLOQUEIO") ? Colors.red : Colors.green[700]
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(j, style: const TextStyle(fontSize: 12, height: 1.4))),
                              ],
                            ),
                          )).toList(),
                          if (index == 0 && !isBlocked) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => AgroAlert.show(title: "Match!", message: "Reprodutor selecionado para o próximo ciclo.", isSuccess: true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                                child: const Text("⭐ RECOMENDADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
