import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'notifications_controller.dart';

class NotificationsView extends StatelessWidget {
  final NotificationsController controller = Get.put(NotificationsController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
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
              icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          "Notificações",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: isDark ? Colors.white70 : Colors.green[800], size: 20),
            tooltip: "Marcar todas como lidas",
            onPressed: () => controller.markAllAsRead(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                ),
                const SizedBox(height: 24),
                Text(
                  "Sua central está vazia", 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 8),
                const Text("Nenhum alerta pendente no momento.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          displacement: 20,
          color: Colors.green[800],
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final n = controller.notifications[index];
              return _buildNotificationCard(n, isDark);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, bool isDark) {
    final bool isRead = n['is_read'] == 1;
    final date = DateTime.parse(n['date']);
    final type = n['text_value_1'] ?? 'default';
    
    IconData icon;
    Color iconColor;
    
    switch(type) {
      case 'ia':
        icon = Icons.psychology_outlined;
        iconColor = Colors.purpleAccent;
        break;
      case 'repro':
        icon = Icons.workspace_premium_outlined;
        iconColor = Colors.amber;
        break;
      case 'warning':
        icon = Icons.report_problem_outlined;
        iconColor = Colors.redAccent;
        break;
      case 'activity':
        icon = Icons.assignment_turned_in_outlined;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications_active_outlined;
        iconColor = Colors.green[800]!;
    }
    
    return Dismissible(
      key: Key(n['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteNotification(n['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRead 
              ? (isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50])
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRead ? Colors.transparent : iconColor.withOpacity(0.2),
            width: 1.5
          ),
          boxShadow: [
            if (!isRead) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n['title'] ?? "Alerta",
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                            fontSize: 14,
                            color: isRead ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                            letterSpacing: -0.3
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(date),
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n['message'] ?? "",
                    style: TextStyle(
                      color: isRead ? Colors.grey : (isDark ? Colors.white70 : Colors.grey[800]),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

