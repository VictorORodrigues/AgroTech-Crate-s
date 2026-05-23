import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Activity {
  final String type;
  final String animal;
  final String detail;
  final DateTime date;
  final IconData icon;
  final Color color;

  Activity({
    required this.type,
    required this.animal,
    required this.detail,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class ActivitiesHistoryView extends StatefulWidget {
  @override
  State<ActivitiesHistoryView> createState() => _ActivitiesHistoryViewState();
}

class _ActivitiesHistoryViewState extends State<ActivitiesHistoryView> {
  String selectedFilter = "Todos";
  final TextEditingController _searchController = TextEditingController();

  // Mock de dados realistas para o Hackathon
  final List<Activity> _allActivities = [
    Activity(
      type: "Inseminação Artificial",
      animal: "Vaca Sertaneja (ID 45)",
      detail: "Reprodutor: Touro Sertão Valente | IA previu 88% de chance.",
      date: DateTime.now(),
      icon: Icons.pets,
      color: Colors.green,
    ),
    Activity(
      type: "Pesagem e Escore",
      animal: "Cabra Mimosa (ID 12)",
      detail: "Resultado: 42 kg | ECC: 3.5 (Ideal)",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      icon: Icons.scale_outlined,
      color: Colors.blue,
    ),
    Activity(
      type: "Vacinação Preventiva",
      animal: "Lote: Ovinos Jovens (Lote B)",
      detail: "Medicamento: Vacina Clostridiose",
      date: DateTime.now().subtract(const Duration(days: 7)),
      icon: Icons.vaccines_outlined,
      color: Colors.red,
    ),
    Activity(
      type: "Diagnóstico de Toque",
      animal: "Cabra Estrela (ID 08)",
      detail: "Resultado: 🟢 Confirmada Prenhe (45 dias)",
      date: DateTime.now().subtract(const Duration(days: 12)),
      icon: Icons.search,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Atividades e Histórico", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. TOPO: BUSCA E FILTROS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[800],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Buscar animal...",
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Todos", "Reprodução", "Saúde", "Pesagem"].map((filter) {
                      bool isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter, style: TextStyle(color: isSelected ? Colors.green[800] : Colors.white70, fontSize: 12)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => selectedFilter = filter),
                          backgroundColor: Colors.white12,
                          selectedColor: Colors.white,
                          showCheckmark: false,
                          shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.white : Colors.white24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 2. LINHA DO TEMPO (TIMELINE)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _allActivities.length,
              itemBuilder: (context, index) {
                return _buildTimelineItem(_allActivities[index], index == _allActivities.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Activity activity, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Traço e Bolinha da Timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: activity.color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(activity.icon, color: activity.color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey[300]),
                  ),
              ],
            ),
          ),
          
          // Card de Conteúdo
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 16, bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(activity.date),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text(
                        DateFormat('HH:mm').format(activity.date),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.type,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Animal: ${activity.animal}",
                    style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.detail,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Get.snackbar("Ação", "Em breve você poderá editar este registro."),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text("Editar", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
