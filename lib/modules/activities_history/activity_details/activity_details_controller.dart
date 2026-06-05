import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../activities_history_controller.dart';
import '../../rebanho/perfil_animal/perfil_animal_controller.dart';
import '../../rebanho/detalhes_rebanho/detalhes_rebanho_controller.dart';
import '../../rebanho/rebanho_controller.dart';
import '../../calendar/calendar_controller.dart';

class ActivityDetailsController extends GetxController {
  var event = <String, dynamic>{}.obs;
  var animalData = Rxn<Map<String, dynamic>>();
  var breederData = Rxn<Map<String, dynamic>>();
  var offspringData = Rxn<Map<String, dynamic>>();
  
  final descriptionCtrl = TextEditingController();
  
  // Controllers para edição de campos estruturados
  final value1Ctrl = TextEditingController(); // Peso, Litros, Fertilidade, Nome Vacina/Remédio
  final value2Ctrl = TextEditingController(); // ECC, Nome Atividade "Outro"
  var eccValue = 3.0.obs;
  var touchResult = "Positivo".obs;

  var isLoading = false.obs;
  var isEditing = false.obs;

  // Data e Hora
  var manualDate = DateTime.now().obs;
  var manualTime = TimeOfDay.now().obs;

  // Campos extras para manejos específicos
  var birthType = "Parto Vaginal (Normal)".obs;
  var gestationalAge = "A Termo (no tempo certo)".obs;
  var deathCause = "Desconhecida".obs;
  var abortionCause = "Desconhecida".obs;
  var inseminationMethod = "IA".obs;

  final fertilityMask = MaskTextInputFormatter(
    mask: '#.#',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void onInit() {
    super.onInit();
    event.value = Get.arguments;
    _initFields();
    _loadAnimalData();
    _loadBreederData();
  }

  void _initFields() {
    descriptionCtrl.text = event['description'] ?? "";
    
    final dateStr = event['date']?.toString() ?? DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr);
    manualDate.value = date;
    manualTime.value = TimeOfDay(hour: date.hour, minute: date.minute);

    final type = event['type']?.toString() ?? "";
    final isTask = event['is_task'] == 1;

    if (isTask) {
      value1Ctrl.text = type; // Título da tarefa
    } else if (type == "Pesagem e Escore") {
      value1Ctrl.text = (event['value_1'] ?? "0.0").toString();
      eccValue.value = (event['value_2'] ?? 3.0).toDouble();
    } else if (type == "Produção de Leite") {
      value1Ctrl.text = (event['value_1'] ?? "0.0").toString();
    } else if (type == "Vacinação" || type == "Medicamento") {
      value1Ctrl.text = event['text_value_1'] ?? "";
      double expense = (event['value_2'] ?? 0.0).toDouble();
      if (expense > 0) {
        final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        value2Ctrl.text = formatter.format(expense);
      } else {
        value2Ctrl.text = "";
      }
    } else if (type == "Diagnóstico de Toque") {
      touchResult.value = event['text_value_1'] ?? "Positivo";
    } else if (type == "Inseminação Artificial") {
      inseminationMethod.value = event['text_value_1'] ?? "IA";
      value1Ctrl.text = (event['value_1'] ?? "1.0").toString();
      // Inicializa valor gasto para edição, formatando como moeda se necessário
      double expense = (event['value_2'] ?? 0.0).toDouble();
      if (expense > 0) {
        final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        value2Ctrl.text = formatter.format(expense);
      } else {
        value2Ctrl.text = "";
      }
    } else if (type == "Nascimento") {
      final t1 = event['text_value_1']?.toString() ?? "";
      if (t1.contains("|")) {
        birthType.value = t1.split("|").first.trim();
        gestationalAge.value = t1.split("|").last.trim();
      }
    } else if (type == "Óbito") {
      deathCause.value = event['text_value_1'] ?? "Desconhecida";
    } else if (type == "Aborto / Perda Gestacional") {
      abortionCause.value = event['text_value_1'] ?? "Desconhecida";
    }
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      _initFields(); // Reset if cancel
    }
  }

  bool hasChanges() {
    final type = event['type']?.toString() ?? "";
    final isTask = event['is_task'] == 1;

    DateTime currentFullDate = DateTime(
      manualDate.value.year, manualDate.value.month, manualDate.value.day,
      manualTime.value.hour, manualTime.value.minute
    );
    bool dateChanged = !currentFullDate.isAtSameMomentAs(DateTime.parse(event['date']));
    bool descriptionChanged = descriptionCtrl.text.trim() != (event['description'] ?? "");
    
    if (isTask) {
      return dateChanged || descriptionChanged || value1Ctrl.text.trim() != type;
    }

    bool fieldsChanged = false;
    if (type == "Pesagem e Escore") {
      double currentWeight = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? 0.0;
      fieldsChanged = currentWeight != (event['value_1'] ?? 0.0) || eccValue.value != (event['value_2'] ?? 3.0);
    } else if (type == "Produção de Leite") {
      double currentVolume = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? 0.0;
      fieldsChanged = currentVolume != (event['value_1'] ?? 0.0);
    } else if (type == "Vacinação" || type == "Medicamento") {
      String cleanValue2 = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
      double currentExpense = double.tryParse(cleanValue2) ?? 0.0;
      fieldsChanged = value1Ctrl.text.trim() != (event['text_value_1'] ?? "") ||
                      currentExpense != (event['value_2'] ?? 0.0);
    } else if (type == "Diagnóstico de Toque") {
      fieldsChanged = touchResult.value != (event['text_value_1'] ?? "Positivo");
    } else if (type == "Inseminação Artificial") {
      double currentFert = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? 0.0;
      String cleanValue2 = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
      double currentExpense = double.tryParse(cleanValue2) ?? 0.0;
      fieldsChanged = currentFert != (event['value_1'] ?? 0.0) || 
                      inseminationMethod.value != (event['text_value_1'] ?? "IA") ||
                      currentExpense != (event['value_2'] ?? 0.0);
    } else if (type == "Nascimento") {
      fieldsChanged = "$birthType | $gestationalAge" != (event['text_value_1'] ?? "");
    } else if (type == "Óbito") {
      fieldsChanged = deathCause.value != (event['text_value_1'] ?? "Desconhecida");
    } else if (type == "Aborto / Perda Gestacional") {
      fieldsChanged = abortionCause.value != (event['text_value_1'] ?? "Desconhecida");
    }

    return dateChanged || descriptionChanged || fieldsChanged;
  }

  Future<void> _loadAnimalData() async {
    final db = await DatabaseHelper.instance.database;

    // Se tiver animal_id, carrega dados do animal (e o rebanho dele via JOIN)
    if (event['animal_id'] != null) {
      try {
        final result = await db.rawQuery('''
          SELECT a.*, h.category, h.name as herd_name 
          FROM animals a 
          INNER JOIN herds h ON a.herd_id = h.id
          WHERE a.id = ?
        ''', [event['animal_id']]);
        
        if (result.isNotEmpty) {
          animalData.value = result.first;
          _loadOffspringData(); // Carrega o filhote após carregar a mãe
        }
      } catch (e) {
        print("Erro ao carregar animal do evento: $e");
      }
    } 
    // Se NÃO tiver animal_id mas tiver herd_id (Atividade "Outro" vinculada a rebanho)
    else if (event['herd_id'] != null) {
      try {
        final result = await db.query('herds', where: 'id = ?', whereArgs: [event['herd_id']]);
        if (result.isNotEmpty) {
          // Criamos um mapa fake para satisfazer a UI que espera herd_name no evento
          var updatedEvent = Map<String, dynamic>.from(event.value);
          updatedEvent['herd_name'] = result.first['name'];
          event.value = updatedEvent;
          update();
        }
      } catch (e) {
        print("Erro ao carregar rebanho do evento: $e");
      }
    }
  }

  Future<void> _loadOffspringData() async {
    if (event['type'] == 'Nascimento' && animalData.value != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final motherIdentifier = animalData.value!['identifier'];
        final eventDate = event['date'].split('T').first; // Apenas a data YYYY-MM-DD

        // Busca por um animal que tenha o ID desta mãe e tenha nascido na mesma data
        final result = await db.rawQuery('''
          SELECT a.*, h.name as herd_name 
          FROM animals a 
          INNER JOIN herds h ON a.herd_id = h.id
          WHERE a.id_mae = ? AND a.birth_date LIKE ?
        ''', [motherIdentifier, '$eventDate%']);

        if (result.isNotEmpty) {
          offspringData.value = result.first;
        }
      } catch (e) {
        print("Erro ao carregar filhote do evento: $e");
      }
    }
  }

  Future<void> toggleTaskCompletion() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final newStatus = (event['text_value_1'] == 'Concluída') ? 'Pendente' : 'Concluída';
      
      await db.update(
        'animal_events',
        {'text_value_1': newStatus},
        where: 'id = ?',
        whereArgs: [event['id']]
      );

      // Recarrega o evento localmente
      final result = await db.query('animal_events', where: 'id = ?', whereArgs: [event['id']]);
      if (result.isNotEmpty) {
        event.value = result.first;
      }
      
      // Sincronização global imediata
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().loadEvents();
      }
      _syncData();
      update();
    } catch (e) {
      print("Erro ao alternar status da tarefa: $e");
    }
  }

  Future<void> _loadBreederData() async {
    String? breederIdentifier;

    if (event['type'] == 'Inseminação Artificial' && event['text_value_1'] == 'Monta') {
      // Pega o ID do reprodutor que está antes do # no text_value_2
      breederIdentifier = event['text_value_2']?.toString().split('#').first;
    } else if (event['type'] == 'Diagnóstico de Toque' || 
               event['type'] == 'Nascimento' || 
               event['type'] == 'Aborto / Perda Gestacional') {
      try {
        final db = await DatabaseHelper.instance.database;
        // Busca a última inseminação/monta que ocorreu antes ou na mesma data deste evento
        final lastInsemination = await db.query(
          'animal_events',
          where: 'animal_id = ? AND type = ? AND text_value_1 = ? AND date <= ?',
          whereArgs: [event['animal_id'], 'Inseminação Artificial', 'Monta', event['date']],
          orderBy: 'date DESC',
          limit: 1,
        );
        if (lastInsemination.isNotEmpty) {
          final t2 = lastInsemination.first['text_value_2']?.toString() ?? "";
          breederIdentifier = t2.contains("#") ? t2.split('#').first : t2;
        }
      } catch (e) {
        print("Erro ao buscar histórico de monta para o evento: $e");
      }
    }

    if (breederIdentifier != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final result = await db.rawQuery('''
          SELECT a.*, h.category, h.name as herd_name 
          FROM animals a 
          INNER JOIN herds h ON a.herd_id = h.id
          WHERE a.identifier = ? AND a.sex = 'Macho'
        ''', [breederIdentifier]);
        
        if (result.isNotEmpty) {
          breederData.value = result.first;
        } else {
          breederData.value = null; // Garante que limpa se não achar
        }
      } catch (e) {
        print("Erro ao carregar reprodutor do evento: $e");
      }
    } else {
      breederData.value = null;
    }
  }

  Future<void> updateActivity() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      
      final type = event['type']?.toString() ?? "";
      final isTask = event['is_task'] == 1;

      DateTime finalDateTime = DateTime(
        manualDate.value.year,
        manualDate.value.month,
        manualDate.value.day,
        manualTime.value.hour,
        manualTime.value.minute,
      );

      Map<String, dynamic> updates = {
        'description': descriptionCtrl.text.trim(),
        'date': finalDateTime.toIso8601String()
      };

      if (isTask) {
        updates['type'] = value1Ctrl.text.trim();
      } else if (type == "Pesagem e Escore") {
        double newVal1 = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? (event['value_1'] ?? 0.0);
        updates['value_1'] = newVal1;
        updates['value_2'] = eccValue.value;
        await db.update('animals', {'weight': newVal1, 'ecc': eccValue.value}, where: 'id = ?', whereArgs: [event['animal_id']]);
      } else if (type == "Produção de Leite") {
        updates['value_1'] = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? (event['value_1'] ?? 0.0);
      } else if (type == "Vacinação" || type == "Medicamento") {
        updates['text_value_1'] = value1Ctrl.text.trim();
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        updates['value_2'] = double.tryParse(cleanVal) ?? 0.0;
      } else if (type == "Diagnóstico de Toque") {
        updates['text_value_1'] = touchResult.value;
        String novoStatus = touchResult.value == "Positivo" ? "Prenhe" : "Vazia / Apta";
        await db.update('animals', {'reproductive_status': novoStatus}, where: 'id = ?', whereArgs: [event['animal_id']]);
      } else if (type == "Inseminação Artificial") {
        updates['text_value_1'] = inseminationMethod.value;
        
        // Validação de Fertilidade
        double fertility = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? (event['value_1'] ?? 1.0);
        if (fertility < 0.0 || fertility > 1.0) {
          AgroAlert.show(title: "Erro", message: "A fertilidade do sêmen deve estar entre 0.0 e 1.0", isError: true);
          isLoading.value = false;
          return;
        }
        updates['value_1'] = fertility;
        
        // Salva o valor gasto (removendo máscara R$)
        String cleanValue2 = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        updates['value_2'] = double.tryParse(cleanValue2) ?? 0.0;
      } else if (type == "Nascimento") {
        updates['text_value_1'] = "${birthType.value} | ${gestationalAge.value}";
      } else if (type == "Óbito") {
        updates['text_value_1'] = deathCause.value;
      } else if (type == "Aborto / Perda Gestacional") {
        updates['text_value_1'] = abortionCause.value;
      } else if (type == "Venda de Animal" || type == "Compra de Animal") {
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        updates['value_2'] = double.tryParse(cleanVal) ?? 0.0;
      }

      await db.update(
        'animal_events',
        updates,
        where: 'id = ?',
        whereArgs: [event['id']]
      );

      // Recarrega o evento localmente
      final result = await db.query('animal_events', where: 'id = ?', whereArgs: [event['id']]);
      if (result.isNotEmpty) {
        event.value = result.first;
        _loadBreederData(); // RECARREGA O REPRODUTOR SE TIVER MUDADO MÉTODO
      }

      // Sincronização global imediata
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().loadEvents();
      }

      _syncData();
      isEditing.value = false;
      update(); // Notifica GetBuilder na View
      AgroAlert.show(title: "Sucesso", message: "Registro atualizado!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao atualizar: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteActivity() async {
    try {
      isLoading.value = true;
      
      // Utiliza a nova lógica de exclusão em cascata (árvore reprodutiva)
      await DatabaseHelper.instance.deleteActivityChain(event['id']);
      
      // Sincronização global imediata ao excluir
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().loadEvents();
      }
      
      _syncData();
      Get.back(); // Fecha tela detalhes
      AgroAlert.show(title: "Excluído", message: "O registro e seus desdobramentos técnicos foram removidos.");
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao excluir: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _syncData() {
    if (Get.isRegistered<ActivitiesHistoryController>()) {
      Get.find<ActivitiesHistoryController>().loadAllEvents();
    }
    if (Get.isRegistered<PerfilAnimalController>()) {
      Get.find<PerfilAnimalController>().carregarDadosDoBanco(event['animal_id']);
    }
    // Sincroniza a lista de animais se estiver aberta
    if (Get.isRegistered<DetalhesRebanhoController>()) {
      Get.find<DetalhesRebanhoController>().carregarDados();
    }
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
  }
}
