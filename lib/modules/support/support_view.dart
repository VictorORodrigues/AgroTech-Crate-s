import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'support_controller.dart';

class SupportView extends StatelessWidget {
  final SupportController controller = Get.put(SupportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Suporte Técnico", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded, size: 80, color: Colors.green[800]),
            ),
            const SizedBox(height: 24),
            const Text(
              "Como podemos ajudar?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Nossa equipe técnica está pronta para auxiliar você com dúvidas ou problemas na sua propriedade.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            
            _buildContactCard(
              title: "Conversar via WhatsApp",
              subtitle: "Atendimento ágil e direto",
              icon: Icons.chat_bubble_outline,
              color: Colors.green[600]!,
              onTap: controller.openWhatsApp,
            ),
            
            const SizedBox(height: 20),
            
            _buildContactCard(
              title: "Enviar um E-mail",
              subtitle: "Relatos detalhados e documentos",
              icon: Icons.email_outlined,
              color: Colors.blue[600]!,
              onTap: controller.openEmail,
            ),
            
            const SizedBox(height: 60),
            Text(
              "Horário de Atendimento: Seg a Sex, 08h às 18h",
              style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
