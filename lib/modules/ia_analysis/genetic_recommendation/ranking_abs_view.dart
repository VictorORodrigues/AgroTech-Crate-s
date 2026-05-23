import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ranking_abs_controller.dart';

class RankingABSView extends StatelessWidget {
  final RankingABSController controller = Get.put(RankingABSController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: const Text('Ranking ABS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: context.theme.brightness == Brightness.dark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50],
            child: const Text(
              "Selecione uma Matriz para encontrar o melhor Reprodutor compatível:",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.animalsAptos.isEmpty) {
                return const Center(child: Text("Nenhuma fêmea apta disponível para recomendação."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.animalsAptos.length,
                itemBuilder: (context, index) {
                  final m = controller.animalsAptos[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        backgroundImage: m['photo_path'] != null && m['photo_path'].isNotEmpty
                            ? FileImage(File(m['photo_path']))
                            : null,
                        child: (m['photo_path'] == null || m['photo_path'].isEmpty)
                            ? const Icon(Icons.female, color: Colors.green)
                            : null,
                      ),
                      title: Text(m['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${m['category']} | ${m['breed']}\nManejo: ${m['management_type']}"),
                      trailing: const Icon(Icons.auto_graph, color: Colors.green),
                      onTap: () => controller.calculateRanking(m),
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
