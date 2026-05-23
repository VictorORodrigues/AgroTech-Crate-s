import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ia_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IaAnalysisView extends StatelessWidget {
  final IaController controller = Get.put(IaController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Cores dinâmicas baseadas no resultado
      Color scaffoldBg = context.theme.scaffoldBackgroundColor;
      Color appBarBg = Colors.green[800]!;
      Color contentColor = context.theme.textTheme.bodyLarge?.color ?? Colors.black87;
      
      if (controller.currentStep.value == AnalysisStep.result) {
        final prob = controller.probability.value;
        if (prob >= 0.75) {
          scaffoldBg = Colors.green[700]!;
          appBarBg = Colors.green[900]!;
        } else if (prob >= 0.51) {
          scaffoldBg = Colors.orange[700]!;
          appBarBg = Colors.orange[900]!;
        } else {
          scaffoldBg = Colors.red[700]!;
          appBarBg = Colors.red[900]!;
        }
        contentColor = Colors.white;
      }

      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          title: Text('Análise Genética IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back()),
          bottom: controller.currentStep.value == AnalysisStep.selection 
            ? TabBar(
                controller: controller.tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Bovinos'),
                  Tab(text: 'Ovinos'),
                  Tab(text: 'Caprinos'),
                ],
              )
            : null,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildBody(contentColor),
          ),
        ),
      );
    });
  }

  Widget _buildBody(Color contentColor) {
    switch (controller.currentStep.value) {
      case AnalysisStep.selection: return _buildSelection();
      case AnalysisStep.loading: return _buildLoading();
      case AnalysisStep.result: return _buildResult(contentColor);
    }
  }

  Widget _buildSelection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          color: Colors.white,
          child: TextField(
            onChanged: (v) => controller.searchText.value = v,
            decoration: InputDecoration(
              hintText: 'Buscar brinco ou rebanho...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller.tabController,
            children: [
              _buildAnimalList(controller.filteredBovinos, FontAwesomeIcons.cow),
              _buildAnimalList(controller.filteredOvinos, Icons.pets),
              _buildAnimalList(controller.filteredCaprinos, Icons.agriculture),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalList(RxList<Map<String, dynamic>> list, dynamic icon) {
    return Obx(() {
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text("Nenhuma fêmea apta encontrada.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final a = list[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            color: context.theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[50],
                backgroundImage: a['photo_path'] != null && a['photo_path'].isNotEmpty
                    ? FileImage(File(a['photo_path']))
                    : null,
                child: (a['photo_path'] == null || a['photo_path'].isEmpty)
                    ? (icon is IconData 
                        ? Icon(icon, color: Colors.green[800], size: 18)
                        : FaIcon(icon, color: Colors.green[800], size: 18))
                    : null,
              ),
              title: Text(a['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rebanho: ${a['herd_name']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 12)),
                  Text("${a['breed']} | ECC: ${a['ecc']}", style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.analytics_outlined, color: Colors.green),
              onTap: () => controller.startAnalysis(a),
            ),
          );
        },
      );
    });
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 8, color: Colors.green)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(controller.loadingText.value, 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.green[900], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Color contentColor) {
    final prob = controller.probability.value;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text("Resultado do Processamento", style: TextStyle(fontSize: 14, color: contentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CircularProgressIndicator(
                  value: prob,
                  strokeWidth: 15,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              Column(
                children: [
                  Text("${(prob * 100).toStringAsFixed(0)}%", 
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: contentColor)),
                  Text("Chance de Prenhez", style: TextStyle(fontSize: 12, color: contentColor.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text("Justificativa Zootécnica", style: TextStyle(fontWeight: FontWeight.bold, color: contentColor)),
                  ],
                ),
                Divider(height: 24, color: contentColor.withOpacity(0.3)),
                Text(controller.justification.value, 
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500, color: contentColor)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.currentStep.value = AnalysisStep.selection;
                    controller.fetchAptos();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: contentColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: contentColor,
                  ),
                  child: const Text("Nova Análise", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.confirmAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Inseminar", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
