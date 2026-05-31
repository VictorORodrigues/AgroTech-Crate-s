import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../activities_history_controller.dart';
import '../../rebanho/perfil_animal/perfil_animal_controller.dart';

class ActivityDetailsController extends GetxController {
  late Map<String, dynamic> event;
  var animalData = Rxn<Map<String, dynamic>>();
  var breederData = Rxn<Map<String, dynamic>>();
  
  final descriptionCtrl = TextEditingController();
  
  // Controllers para edição de campos estruturados
  final value1Ctrl = TextEditingController(); // Peso, Litros, Fertilidade, Nome Vacina/Remédio
  final value2Ctrl = TextEditingController(); // ECC, Nome Atividade "Outro"
  var eccValue = 3.0.obs;
  var touchResult = "Positivo".obs;

  var isLoading = false.obs;
  var isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    event = Get.arguments;
    _initFields();
    _loadAnimalData();
    _loadBreederData();
  }

  void _initFields() {
    descriptionCtrl.text = event['description'] ?? "";
    
    final type = event['type']?.toString() ?? "";
    if (type == "Pesagem e Escore") {
      value1Ctrl.text = (event['value_1'] ?? "0.0").toString();
      eccValue.value = (event['value_2'] ?? 3.0).toDouble();
    } else if (type == "Produção de Leite") {
      value1Ctrl.text = (event['value_1'] ?? "0.0").toString();
    } else if (type == "Vacinação" || type == "Medicamento") {
      value1Ctrl.text = event['text_value_1'] ?? "";
    } else if (type == "Diagnóstico de Toque") {
      touchResult.value = event['text_value_1'] ?? "Positivo";
    } else if (type == "Inseminação Artificial") {
       if (event['text_value_1'] == "IA") {
         value1Ctrl.text = (event['value_1'] ?? "1.0").toString();
       }
    }
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      _initFields(); // Reset if cancel
    }
  }

  Future<void> _loadAnimalData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT a.*, h.category, h.name as herd_name 
        FROM animals a 
        INNER JOIN herds h ON a.herd_id = h.id
        WHERE a.id = ?
      ''', [event['animal_id']]);
      
      if (result.isNotEmpty) {
        animalData.value = result.first;
      }
    } catch (e) {
      print("Erro ao carregar animal do evento: $e");
    }
  }

  Future<void> _loadBreederData() async {
    String? breederIdentifier;

    if (event['type'] == 'Inseminação Artificial' && event['text_value_1'] == 'Monta') {
      breederIdentifier = event['text_value_2']?.toString();
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
          breederIdentifier = lastInsemination.first['text_value_2']?.toString();
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
        }
      } catch (e) {
        print("Erro ao carregar reprodutor do evento: $e");
      }
    }
  }

  Future<void> updateActivity() async {
    try {
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;
      
      final type = event['type']?.toString() ?? "";
      Map<String, dynamic> updates = {
        'description': descriptionCtrl.text.trim()
      };

      if (type == "Pesagem e Escore") {
        double newVal1 = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? (event['value_1'] ?? 0.0);
        updates['value_1'] = newVal1;
        updates['value_2'] = eccValue.value;
        // Atualiza no animal também
        await db.update('animals', {'weight': newVal1, 'ecc': eccValue.value}, where: 'id = ?', whereArgs: [event['animal_id']]);
      } else if (type == "Produção de Leite") {
        updates['value_1'] = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? (event['value_1'] ?? 0.0);
      } else if (type == "Vacinação" || type == "Medicamento") {
        updates['text_value_1'] = value1Ctrl.text.trim();
      } else if (type == "Diagnóstico de Toque") {
        updates['text_value_1'] = touchResult.value;
        String novoStatus = touchResult.value == "Positivo" ? "Prenhe" : "Vazia / Apta";
        await db.update('animals', {'reproductive_status': novoStatus}, where: 'id = ?', whereArgs: [event['animal_id']]);
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
        event = result.first;
      }

      _syncData();
      isEditing.value = false;
      AgroAlert.show(title: "Sucesso", message: "Registro atualizado!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao atualizar: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteActivity() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Lógica de Reversão Biológica
      final type = event['type']?.toString() ?? "";
      final animalId = event['animal_id'];

      if (type == "Pesagem e Escore") {
        // Restaura peso e ECC anteriores
        double prevWeight = double.tryParse(event['text_value_1']?.toString() ?? "0.0") ?? 0.0;
        double prevEcc = double.tryParse(event['text_value_2']?.toString() ?? "3.0") ?? 3.0;
        await db.update('animals', {'weight': prevWeight, 'ecc': prevEcc}, where: 'id = ?', whereArgs: [animalId]);
      } else if (type == "Inseminação Artificial" || type == "Diagnóstico de Toque" || type == "Aborto / Perda Gestacional") {
        // Restaura status anterior guardado no t2 (formato N/A#Status ou ID#Status)
        String t2 = event['text_value_2']?.toString() ?? "";
        if (t2.contains("#")) {
          String prevStatus = t2.split("#").last;
          await db.update('animals', {'reproductive_status': prevStatus}, where: 'id = ?', whereArgs: [animalId]);
        }
      } else if (type == "Nascimento") {
        // Restaura paridade (t1) e status (t2)
        String prevParity = event['text_value_1']?.toString() ?? "Nulípara";
        String prevStatus = event['text_value_2']?.toString() ?? "Prenhe";
        await db.update('animals', {'parity': prevParity, 'reproductive_status': prevStatus}, where: 'id = ?', whereArgs: [animalId]);
      }

      await db.delete('animal_events', where: 'id = ?', whereArgs: [event['id']]);
      
      _syncData();
      Get.back(); // Fecha tela detalhes
      AgroAlert.show(title: "Excluído", message: "Registro removido e alterações biológicas revertidas.");
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao excluir: $e", isError: true);
    }
  }

  void _syncData() {
    if (Get.isRegistered<ActivitiesHistoryController>()) {
      Get.find<ActivitiesHistoryController>().loadAllEvents();
    }
    if (Get.isRegistered<PerfilAnimalController>()) {
      Get.find<PerfilAnimalController>().carregarDadosDoBanco(event['animal_id']);
    }
  }
}
