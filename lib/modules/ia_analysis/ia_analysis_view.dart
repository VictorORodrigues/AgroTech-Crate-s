import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ia_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IaAnalysisView extends StatelessWidget {
  final IaController controller = Get.put(IaController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Cores base dinâmicas - Paleta focada em Verde Escuro "AgroTech" (Futurista)
      List<Color> gradientColors = [
        const Color(0xFF0A1F12), // Deep Forest Green
        const Color(0xFF132E1D), // Dark Moss
        const Color(0xFF1B4332), // Emerald Depth
      ]; 
      Color accentColor = const Color(0xFF40C057); // Mint Green Neon

      if (controller.currentStep.value == AnalysisStep.result) {
        final prob = controller.chanceIA.value / 100;
        if (prob >= 0.70) {
          gradientColors = [const Color(0xFF081C15), const Color(0xFF2D6A4F)]; // Success Green High Depth
          accentColor = Colors.white;
        } else if (prob >= 0.45) {
          gradientColors = [const Color(0xFF1F1D0A), const Color(0xFF433E13)]; // Dark Gold/Olive
          accentColor = Colors.white;
        } else {
          gradientColors = [const Color(0xFF1F0A0A), const Color(0xFF431313)]; // Dark Maroon/Blood
          accentColor = Colors.white;
        }
      }

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(context),
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildBody(context, accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildModernAppBar(BuildContext context) {
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
            'IA PREDICTOR',
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

  Widget _buildBody(BuildContext context, Color accentColor) {
    switch (controller.currentStep.value) {
      case AnalysisStep.selection:
        return _buildSelection(context);
      case AnalysisStep.loading:
        return _buildLoading();
      case AnalysisStep.result:
        return _buildResult(context, accentColor);
    }
  }

  Widget _buildSelection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Análise Genética",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                "Selecione uma fêmea apta para iniciar o processamento",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildGlassSearchBar(context),
        const SizedBox(height: 20),
        _buildCustomTabBar(context),
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

  Widget _buildGlassSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              onChanged: (v) => controller.searchText.value = v,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar brinco ou lote...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TabBar(
        controller: controller.tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withOpacity(0.2),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Bovinos'),
          Tab(text: 'Ovinos'),
          Tab(text: 'Caprinos'),
        ],
      ),
    );
  }

  Widget _buildAnimalList(RxList<Map<String, dynamic>> list, dynamic icon) {
    return Obx(() {
      if (list.isEmpty) {
        return Center(
          child: Text(
            "Nenhuma matriz disponível.",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final a = list[index];
          return _buildGlassAnimalCard(context, a, icon);
        },
      );
    });
  }

  Widget _buildGlassAnimalCard(BuildContext context, Map<String, dynamic> a, dynamic icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                ),
                child: ClipOval(
                  child: a['photo_path'] != null && a['photo_path'].isNotEmpty
                      ? Image.file(File(a['photo_path']), fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: icon is IconData
                                ? Icon(icon, color: Colors.white70, size: 20)
                                : FaIcon(icon, color: Colors.white70, size: 20),
                          ),
                        ),
                ),
              ),
              title: Text(
                a['identifier'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              subtitle: Text(
                "${a['breed']} • ECC ${a['ecc']}",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              onTap: () => controller.startAnalysis(a),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Colors.greenAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Obx(() => Text(
          controller.loadingText.value.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2,
          ),
        )),
      ],
    );
  }

  Widget _buildResult(BuildContext context, Color accentColor) {
    final probIA = controller.chanceIA.value;
    final probMonta = controller.chanceMonta.value;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          _buildResultHeader(accentColor),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernScore(probIA, "INSEMINAÇÃO", accentColor),
              _buildModernScore(probMonta, "MONTA NATURAL", accentColor),
            ],
          ),
          const SizedBox(height: 40),
          
          if (controller.sucessos.isNotEmpty)
            _buildGlassInfoSection("PONTOS FAVORÁVEIS", controller.sucessos, Icons.auto_awesome),
          
          const SizedBox(height: 16),
          
          if (controller.fracassos.isNotEmpty)
            _buildGlassInfoSection("PONTOS DE ATENÇÃO", controller.fracassos, Icons.warning_amber_rounded),

          const SizedBox(height: 16),

          _buildGlassRecommendationSection(),

          const SizedBox(height: 40),
          _buildActionButtons(accentColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultHeader(Color accentColor) {
    return Column(
      children: [
        Text(
          "VEREDITO DA IA",
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.statusIa.value.replaceAll("STATUS: ", ""),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildModernScore(double value, String label, Color accentColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: Colors.white,
              ),
            ),
            Text(
              "${value.toStringAsFixed(0)}%",
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildGlassInfoSection(String title, List<String> items, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassRecommendationSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text("CONDUTA RECOMENDADA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                controller.recomendacaoFinal.value,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              controller.currentStep.value = AnalysisStep.selection;
              controller.fetchAptos();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("NOVA ANÁLISE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.confirmAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text("REGISTRAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ),
      ],
    );
  }
}
