import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    
    // Lista de dias da semana atual para o mini-calendário horizontal
    final List<DateTime> weekDays = List.generate(7, (index) => now.add(Duration(days: index - now.weekday + 1)));

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Calendário de Manejo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MINI-CALENDÁRIO HORIZONTAL ELEGANTE
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.green[800],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekDays.map((date) {
                  bool isToday = date.day == now.day;
                  return Column(
                    children: [
                      Text(
                        DateFormat('E', 'pt_BR').format(date)[0].toUpperCase(),
                        style: TextStyle(color: isToday ? Colors.white : Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white : Colors.white12,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.green[800] : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. PRÓXIMOS NASCIMENTOS (O BERÇÁRIO)
                  _buildSectionHeader("🍼 Próximos Nascimentos", Colors.blue),
                  _buildTaskCard(
                    title: "Ovelha 'Dolly'",
                    subtitle: "Previsão de 2 cordeiros (Daqui a 3 dias)",
                    date: "25/05",
                    icon: Icons.child_care,
                    color: Colors.blue,
                  ),
                  _buildTaskCard(
                    title: "Vaca 'Sertaneja'",
                    subtitle: "Parto Nelore previsto (Daqui a 10 dias)",
                    date: "01/06",
                    icon: Icons.pets,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  // 3. MANEJO SANITÁRIO AUTOMATIZADO
                  _buildSectionHeader("💉 Tarefas de Saúde para Hoje", Colors.red),
                  _buildTaskCard(
                    title: "Vacinação Clostridiose",
                    subtitle: "Cabra 'Mimosa' (Pré-parto 30 dias)",
                    date: "Hoje",
                    icon: Icons.vaccines,
                    color: Colors.red,
                  ),
                  _buildTaskCard(
                    title: "Vermifugação Lote B",
                    subtitle: "Preventivo por umidade acumulada",
                    date: "Hoje",
                    icon: Icons.medication,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 24),

                  // 4. EXAME DE TOQUE / DIAGNÓSTICO
                  _buildSectionHeader("🔍 Exames Requeridos", Colors.orange),
                  _buildTaskCard(
                    title: "Confirmação de Prenhez",
                    subtitle: "Cabra 'Estrela' (42 dias pós-monta com 'Chico')",
                    date: "Urgente",
                    icon: Icons.search,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 24),

                  // 5. ALERTAS DE CIO (DIAS DE OURO)
                  _buildSectionHeader("🔥 Alerta de Cio", Colors.amber),
                  _buildTaskCard(
                    title: "Novilha 'Pretinha'",
                    subtitle: "Ciclo de 21 dias se cumpre amanhã",
                    date: "Amanhã",
                    icon: Icons.wb_twilight,
                    color: Colors.amber,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            child: Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
