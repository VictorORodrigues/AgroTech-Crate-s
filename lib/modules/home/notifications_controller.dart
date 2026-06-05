import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../database/database_helper.dart';

class NotificationsController extends GetxController {
  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    try {
      isLoading.value = true;
      // 1. Gera notificações mock para apresentação (se não existirem)
      await _generateMockPresentationNotifications();
      
      // 2. Verifica se há novas tarefas para hoje e gera notificações
      await _checkAndGenerateDueNotifications();
      
      // 3. Carrega todas as notificações do banco
      await loadNotifications();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _generateMockPresentationNotifications() async {
    final db = await DatabaseHelper.instance.database;
    
    // Lista de notificações mock para impressionar os jurados
    final mockData = [
      {
        'title': "🤖 Insight de IA: Cruzamento Ideal",
        'message': "Alta probabilidade de sucesso (88%) detectada para a matriz NEL-201 com o reprodutor Thor. O clima em Crateús está ideal hoje (THI 67).",
        'type': "ia",
        'date': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String()
      },
      {
        'title': "🏆 Padrão de Elite Identificado",
        'message': "Seu rebanho de Ovinos atingiu um marco de excelência genética. O ganho de peso médio dos borregos subiu 22% este mês.",
        'type': "repro",
        'date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()
      },
      {
        'title': "🌡️ Alerta de Estresse Térmico",
        'message': "Atenção: THI subindo para 82 em sua localização. Recomenda-se reforço hídrico e sombra para o lote de matrizes em lactação.",
        'type': "warning",
        'date': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()
      },
      {
        'title': "💉 Lembrete de Manejo",
        'message': "Amanhã é dia de vacinação contra Febre Aftosa. Certifique-se de que os insumos e o brete estejam preparados.",
        'type': "activity",
        'date': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()
      },
      {
        'title': "📉 Custo do Ócio Detectado",
        'message': "Você tem 12 fêmeas vazias há mais de 90 dias. Prejuízo projetado de R\$ 1.200,00 este mês. Considere iniciar protocolos hormonal.",
        'type': "warning",
        'date': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String()
      }
    ];

    for (var mock in mockData) {
      final existing = await db.query('app_notifications', where: 'message = ?', whereArgs: [mock['message']]);
      if (existing.isEmpty) {
        await db.insert('app_notifications', {
          'event_id': null,
          'title': mock['title'],
          'message': mock['message'],
          'date': mock['date'],
          'is_read': 0,
          'text_value_1': mock['type'],
        });
      }
    }
  }

  Future<void> loadNotifications() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_notifications',
      orderBy: 'date DESC',
    );
    notifications.value = results;
    
    // Calcula não lidas
    unreadCount.value = results.where((n) => n['is_read'] == 0).length;
  }

  Future<void> markAllAsRead() async {
    final db = await DatabaseHelper.instance.database;
    await db.update('app_notifications', {'is_read': 1});
    await loadNotifications();
  }

  Future<void> _checkAndGenerateDueNotifications() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    // Pega o fim do dia de hoje para garantir que pegamos tudo que venceu até agora
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    // Busca tarefas agendadas até hoje que ainda não foram convertidas em notificação
    final dueTasks = await db.rawQuery('''
      SELECT e.*, a.identifier as animal_identifier
      FROM animal_events e
      LEFT JOIN animals a ON e.animal_id = a.id
      WHERE e.is_task = 1 
      AND e.date <= ?
      AND e.id NOT IN (SELECT IFNULL(event_id, 0) FROM app_notifications)
    ''', [todayEnd]);

    for (var task in dueTasks) {
      String animalPart = task['animal_identifier'] != null ? " do animal ${task['animal_identifier']}" : "";
      await db.insert('app_notifications', {
        'event_id': task['id'],
        'title': "Manejo agendado",
        'message': "Você tem a tarefa '${task['type']}'$animalPart agendada para hoje.",
        'date': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
    }
  }

  Future<void> deleteNotification(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('app_notifications', where: 'id = ?', whereArgs: [id]);
    await loadNotifications();
  }
}
