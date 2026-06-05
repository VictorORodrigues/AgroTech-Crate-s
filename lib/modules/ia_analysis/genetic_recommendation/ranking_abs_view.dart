import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ranking_abs_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RankingABSView extends StatelessWidget {
  final RankingABSController controller = Get.put(RankingABSController());

  @override
  Widget build(BuildContext context) {
    // Paleta Cyber-Dark focada em Verde Escuro
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
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  if (controller.animalsAptos.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildMatrixList();
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Get.back(),
              ),
              const Text(
                'GENETIC MATCH',
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
          const SizedBox(height: 10),
          _buildCustomTabBar(),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassSearchBar(),
          const SizedBox(height: 20),
          const Text(
            "Seleção de Matriz",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Selecione uma fêmea para encontrar o par reprodutivo ideal",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return ClipRRect(
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
              hintText: 'Buscar brinco ou apelido...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixList() {
    return TabBarView(
      controller: controller.tabController,
      children: [
        _buildFilteredList(controller.filteredBovinos),
        _buildFilteredList(controller.filteredOvinos),
        _buildFilteredList(controller.filteredCaprinos),
      ],
    );
  }

  Widget _buildFilteredList(RxList<Map<String, dynamic>> list) {
    return Obx(() {
      if (list.isEmpty) {
        String msg = controller.searchText.value.isNotEmpty 
            ? "Nenhuma matriz encontrada para esta busca." 
            : "Nenhuma matriz disponível nesta categoria.";
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, color: Colors.white.withOpacity(0.3), size: 48),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final a = list[index];
          return _buildGlassMatrixCard(a);
        },
      );
    });
  }

  Widget _buildGlassMatrixCard(Map<String, dynamic> a) {
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
                  border: Border.all(color: const Color(0xFF40C057).withOpacity(0.5), width: 2),
                ),
                child: ClipOval(
                  child: a['photo_path'] != null && a['photo_path'].isNotEmpty
                      ? Image.file(File(a['photo_path']), fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withOpacity(0.1),
                          child: const Center(
                            child: Icon(Icons.female, color: Colors.white70, size: 24),
                          ),
                        ),
                ),
              ),
              title: Text(
                a['identifier'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              subtitle: Text(
                "${a['breed']} • ${a['aptitude'] ?? 'Rústica'}",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              trailing: const Icon(Icons.auto_awesome, color: Color(0xFF40C057), size: 20),
              onTap: () => controller.calculateRanking(a),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Nenhuma fêmea apta disponível.",
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }
}
