import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../activities_history_controller.dart';
import '../../rebanho/perfil_animal/perfil_animal_controller.dart';
import '../../calendar/calendar_controller.dart';
import '../../../services/sync_service.dart';
import '../../../services/tecnico_config_service.dart';

class AddActivityController extends GetxController {
  final Map<String, dynamic>? preSelectedAnimal = Get.arguments?['animal'];

  final List<String> types = [
    "Abate",
    "Aborto / Perda Gestacional",
    "Casqueamento",
    "Compra de Animal",
    "Diagnóstico de Toque",
    "Inseminação Artificial",
    "Medicamento",
    "Nascimento",
    "Óbito",
    "Outro",
    "Pesagem e Escore",
    "Produção de Leite",
    "Tosquia",
    "Vacinação",
    "Venda de Animal",
  ];

  var selectedType = "".obs;
  var selectedAnimal = Rxn<Map<String, dynamic>>();
  var selectedHerd = Rxn<Map<String, dynamic>>();
  var allAnimals = <Map<String, dynamic>>[].obs;
  var allHerds = <Map<String, dynamic>>[].obs;

  // Data e Hora (Puxados do Calendário)
  var manualDate = DateTime.now().obs;
  var manualTime = TimeOfDay.now().obs;
  
  // Inseminação
  var inseminationType = "Inseminação Artificial".obs; // IA ou Monta
  var selectedReprodutor = Rxn<Map<String, dynamic>>();
  var potentialSires = <Map<String, dynamic>>[].obs;
  
  // Inputs dinâmicos
  final value1Ctrl = TextEditingController(); // Peso, Litros, Fertilidade, Nome Vacina/Remédio
  final value2Ctrl = TextEditingController(); // Valor Gasto

  final moneyMask = MaskTextInputFormatter(
    mask: 'R\$ #.###.###,##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final weightMask = MaskTextInputFormatter(
    mask: '###.#',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final semenMask = MaskTextInputFormatter(
    mask: '#.#',
    filter: {"#": RegExp(r'[0-9]')},
  );

  void validateSemenInput(String val) {
    if (val.isEmpty) return;
    double? d = double.tryParse(val.replaceAll(',', '.'));
    if (d != null && d > 1.0) {
      value1Ctrl.text = "1.0";
    }
  }
  final date2Ctrl = Rxn<DateTime>(); // Segunda Dose
  var eccValue = 3.0.obs; 
  final descriptionCtrl = TextEditingController();
  
  // Óbito e Aborto
  var deathCause = "Desconhecida".obs;
  var abortionCause = "Desconhecida".obs;
  
  // Diagnóstico e Nascimento
  var touchResult = "Positivo".obs; // Positivo / Negativo
  var birthType = "Parto Vaginal (Normal)".obs;
  var gestationalAge = "A Termo (no tempo certo)".obs;
  
  // Venda, Compra e Abate
  var registerNewOnPurchase = false.obs;

  final fertilityMask = MaskTextInputFormatter(
    mask: '#.#',
    filter: {"#": RegExp(r'[0-9]')},
  );

  var isLoading = false.obs;

  // Filtros de busca na BottomSheet
  var searchCategoryFilter = "Todos".obs; // Todos, Bovino, Ovino, Caprino
  var searchSexFilter = "Todos".obs; // Todos, Macho, Fêmea

  @override
  void onInit() {
    super.onInit();
    
    final dynamic args = Get.arguments;
    if (args != null && args['selectedDate'] != null) {
      manualDate.value = args['selectedDate'];
    }

    if (preSelectedAnimal != null) {
      selectedAnimal.value = preSelectedAnimal;
    }
    loadAnimals();
    loadHerds();
    
    // Filtros biológicos ao mudar o tipo
    ever(selectedType, (String type) {
      if (selectedAnimal.value != null) {
        final animal = selectedAnimal.value!;
        bool isCompatible = true;

        if (type == "Inseminação Artificial") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Vazia / Apta';
        } else if (type == "Nascimento") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Prenhe';
        } else if (type == "Aborto / Perda Gestacional") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Prenhe';
        } else if (type == "Produção de Leite") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Em Lactação';
        } else if (type == "Diagnóstico de Toque") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Inseminada';
        }

        if (!isCompatible) {
          selectedAnimal.value = null;
        }
      }
    });
    
    // Sincroniza fertilidade se mudar o reprodutor
    ever(selectedReprodutor, (Map<String, dynamic>? sire) {
      if (sire != null && sire['id'] != -1) {
        value1Ctrl.text = (sire['semen_fertility'] ?? 1.0).toString();
      }
    });

    // Filtra reprodutores se mudar o animal (mãe)
    ever(selectedAnimal, (Map<String, dynamic>? dam) {
      if (dam != null) {
        _loadPotentialSires(dam['category']);
      }
    });
  }

  Future<void> loadAnimals() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT a.*, h.category, h.name as herd_name 
        FROM animals a 
        INNER JOIN herds h ON a.herd_id = h.id
      ''');
      allAnimals.value = result;
    } catch (e) {
      print("Erro ao carregar animais: $e");
    }
  }

  Future<void> loadHerds() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('herds');
      allHerds.value = result;
    } catch (e) {
      print("Erro ao carregar rebanhos: $e");
    }
  }

  Future<void> _loadPotentialSires(String category) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT a.*, h.name as herd_name 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id
      WHERE a.sex = 'Macho' AND h.category = ? AND a.vital_status = 'Ativo'
    ''', [category]);
    potentialSires.value = result;
  }

  List<Map<String, dynamic>> getFilteredAnimalsList(String query) {
    // Filtramos para exibir apenas animais ATIVOS nos inputs de novos manejos
    List<Map<String, dynamic>> baseList = allAnimals.where((a) => a['vital_status'] == 'Ativo').toList();

    if (selectedType.value == "Inseminação Artificial") {
      baseList = baseList.where((a) => a['sex'] == 'Fêmea' && a['reproductive_status'] == 'Vazia / Apta').toList();
    } else if (selectedType.value == "Nascimento") {
      baseList = baseList.where((a) => a['sex'] == 'Fêmea' && a['reproductive_status'] == 'Prenhe').toList();
    } else if (selectedType.value == "Aborto / Perda Gestacional") {
      baseList = baseList.where((a) => a['sex'] == 'Fêmea' && a['reproductive_status'] == 'Prenhe').toList();
    } else if (selectedType.value == "Produção de Leite") {
      baseList = baseList.where((a) => a['sex'] == 'Fêmea' && a['reproductive_status'] == 'Em Lactação').toList();
    } else if (selectedType.value == "Diagnóstico de Toque") {
      baseList = baseList.where((a) => a['sex'] == 'Fêmea' && a['reproductive_status'] == 'Inseminada').toList();
    }

    final filtered = baseList.where((a) {
      final q = query.toLowerCase();
      final matchesQuery = 
          a['identifier'].toString().toLowerCase().contains(q) ||
          (a['name'] ?? "").toString().toLowerCase().contains(q) ||
          (a['breed_name'] ?? "").toString().toLowerCase().contains(q) ||
          (a['lineage'] ?? "").toString().toLowerCase().contains(q) ||
          (a['herd_name'] ?? "").toString().toLowerCase().contains(q);
      
      final matchesCategory = searchCategoryFilter.value == "Todos" || a['category'] == searchCategoryFilter.value;
      final matchesSex = searchSexFilter.value == "Todos" || a['sex'] == searchSexFilter.value;

      return matchesQuery && matchesCategory && matchesSex;
    }).toList();

    filtered.sort((a, b) {
      final statusA = a['vital_status'] ?? "Ativo";
      final statusB = b['vital_status'] ?? "Ativo";
      if (statusA != statusB) return statusA == "Ativo" ? -1 : 1;
      return a['identifier'].toString().compareTo(b['identifier'].toString());
    });

    return filtered;
  }

  Future<void> saveActivity() async {
    if (selectedType.value.isEmpty) {
      AgroAlert.show(title: "Erro", message: "Selecione o tipo de manejo.", isError: true);
      return;
    }

    if (selectedType.value != "Outro" && selectedAnimal.value == null) {
      AgroAlert.show(title: "Erro", message: "Selecione o animal.", isError: true);
      return;
    }

    if (selectedType.value == "Outro" && value1Ctrl.text.trim().isEmpty) {
      AgroAlert.show(title: "Erro", message: "Digite o nome da atividade.", isError: true);
      return;
    }

    try {
      if (isLoading.value) return; // Proteção extra contra cliques duplos
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      DateTime finalDateTime = DateTime(
        manualDate.value.year,
        manualDate.value.month,
        manualDate.value.day,
        manualTime.value.hour,
        manualTime.value.minute,
      );
      
      String description = descriptionCtrl.text.trim();
      double? val1 = double.tryParse(value1Ctrl.text.replaceAll(',', '.'));
      double? val2 = double.tryParse(value2Ctrl.text.replaceAll(',', '.'));

      String? t1, t2;
      double? v1, v2;

      if (selectedType.value == "Diagnóstico de Toque") {
        t1 = touchResult.value;
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Inseminada";
        t2 = "N/A#$prevStatus";
        String novoStatus = touchResult.value == "Positivo" ? "Prenhe" : "Vazia / Apta";
        await db.update('animals', {'reproductive_status': novoStatus}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Inseminação Artificial") {
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Vazia / Apta";
        
        // Validação de Fertilidade
        double fertility = val1 ?? 0.0;
        if (fertility < 0.0 || fertility > 1.0) {
          AgroAlert.show(title: "Erro", message: "A fertilidade do sêmen deve estar entre 0.0 e 1.0", isError: true);
          isLoading.value = false;
          return;
        }

        await db.update('animals', {'reproductive_status': "Inseminada"}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        t1 = inseminationType.value == "Inseminação Artificial" ? "IA" : "Monta";
        v1 = fertility; 
        
        // Tratamento do valor gasto (removendo máscara R$)
        String cleanValue2 = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        v2 = double.tryParse(cleanValue2);

        if (inseminationType.value == "Monta") {
          t2 = "${selectedReprodutor.value?['identifier']}#$prevStatus";
        } else {
          t2 = "N/A#$prevStatus";
        }
      }

      else if (selectedType.value == "Aborto / Perda Gestacional") {
        t1 = abortionCause.value;
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Prenhe";
        t2 = "N/A#$prevStatus";
        await db.update('animals', {'reproductive_status': "Vazia / Apta"}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Pesagem e Escore") {
        v1 = val1; // Peso Atual
        v2 = eccValue.value; // ECC Atual
        t1 = selectedAnimal.value!['weight']?.toString() ?? "0.0";
        t2 = selectedAnimal.value!['ecc']?.toString() ?? "3.0";
        if (val1 != null) await db.update('animals', {'weight': val1}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        await db.update('animals', {'ecc': eccValue.value}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Vacinação") {
        t1 = value1Ctrl.text.trim(); // Nome da vacina
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        v2 = double.tryParse(cleanVal);
        if (date2Ctrl.value != null) {
          t2 = date2Ctrl.value!.toIso8601String(); // Data 2a dose
        }
      }

      else if (selectedType.value == "Medicamento") {
        t1 = value1Ctrl.text.trim();
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        v2 = double.tryParse(cleanVal);
      }

      else if (selectedType.value == "Produção de Leite") {
        v1 = val1;
      }

      else if (selectedType.value == "Óbito") {
        t1 = deathCause.value;
        await db.update('animals', {
          'reproductive_status': 'Óbito',
          'vital_status': 'Óbito',
          'death_date': finalDateTime.toIso8601String()
        }, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Outro") {
        t1 = value1Ctrl.text.trim();
      }

      else if (selectedType.value == "Venda de Animal") {
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        v2 = double.tryParse(cleanVal);
        await db.update('animals', {
          'reproductive_status': 'Vendido',
          'vital_status': 'Vendido',
          'death_date': finalDateTime.toIso8601String()
        }, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Abate") {
        await db.update('animals', {
          'reproductive_status': 'Abatido',
          'vital_status': 'Abatido',
          'death_date': finalDateTime.toIso8601String()
        }, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      else if (selectedType.value == "Compra de Animal") {
        String cleanVal = value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
        v2 = double.tryParse(cleanVal);
      }

      if (selectedType.value != "Nascimento") {
        double? v1parsed = double.tryParse(value1Ctrl.text.replaceAll(',', '.'));
        double? v2parsed = double.tryParse(value2Ctrl.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.'));

        await DatabaseHelper.instance.insertEvent(
          selectedAnimal.value?['id'], 
          selectedType.value == "Outro" ? t1! : selectedType.value,
          description,
          v1: v1parsed ?? v1,
          v2: v2parsed ?? v2,
          t1: t1,
          t2: t2,
          manualDate: finalDateTime,
          herdId: selectedHerd.value?['id'] ?? selectedAnimal.value?['herd_id'],
        );
        Get.back();
        AgroAlert.show(title: "Sucesso", message: "Atividade registrada!", isSuccess: true);
      } else {
        // Nascimento
        String prevParity = (selectedAnimal.value!['parity']?.toString() ?? "Nulípara").split('#').first.split('|').first.trim();
        String prevStatus = (selectedAnimal.value!['reproductive_status']?.toString() ?? "Prenhe").split('#').first.split('|').first.trim();
        
        // Atualiza a fêmea
        await db.update('animals', {'reproductive_status': 'Em Lactação'}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        
        String nextParity = prevParity;
        if (prevParity == "Nulípara") nextParity = "Primípara";
        else if (prevParity == "Primípara") nextParity = "Multípara";
        
        if (nextParity != prevParity) {
          await db.update('animals', {'parity': nextParity}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        }

        // Registra o evento de nascimento
        await DatabaseHelper.instance.insertEvent(
          selectedAnimal.value!['id'],
          selectedType.value,
          description,
          t1: "$birthType | $gestationalAge",
          t2: "$prevParity#$prevStatus",
          manualDate: finalDateTime,
          herdId: selectedAnimal.value!['herd_id'],
        );
      }

      // Sincroniza os dados ANTES de mostrar o fluxo de nascimento ou fechar a tela
      _syncData();
      _handleBiologicalTriggers(finalDateTime);

      if (selectedType.value == "Nascimento") {
        isLoading.value = false;
        _showBirthFlow(finalDateTime);
      } else {
        Get.back();
        AgroAlert.show(title: "Sucesso", message: "Atividade registrada!", isSuccess: true);
      }
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao salvar: $e", isError: true);
      isLoading.value = false;
    } finally {
      if (selectedType.value != "Nascimento") {
        isLoading.value = false;
      }
    }
  }

  void _showBirthFlow(DateTime birthDate) async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                child: Icon(Icons.child_care, color: Colors.green[800], size: 40),
              ),
              const SizedBox(height: 20),
              const Text("Nascimento Registrado!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                "A mãe agora está em lactação. Deseja cadastrar o novo filhote no sistema agora?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () { Get.back(); Get.back(); },
                      child: const Text("MAIS TARDE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _selectHerdForNewborn(birthDate);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("SIM, CADASTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _selectHerdForNewborn(DateTime birthDate) async {
    final db = await DatabaseHelper.instance.database;
    final herds = await db.query('herds', where: 'category = ?', whereArgs: [selectedAnimal.value!['category']]);

    final lastInsemination = await db.query(
      'animal_events',
      where: 'animal_id = ? AND type = ?',
      whereArgs: [selectedAnimal.value!['id'], 'Inseminação Artificial'],
      orderBy: 'date DESC',
      limit: 1,
    );

    String? lastFatherId;
    if (lastInsemination.isNotEmpty && lastInsemination.first['text_value_1'] == "Monta") {
      lastFatherId = lastInsemination.first['text_value_2']?.toString().split('#').first;
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const Text("Selecione o Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Onde o filhote será alocado?", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: herds.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final h = herds[index];
                  return ListTile(
                    leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                    title: Text(h['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${h['category']} | ${h['management_type']}"),
                    onTap: () {
                      Get.back();
                      Get.back();
                      Get.toNamed('/add-animal', arguments: {
                        'herd': h,
                        'isEdition': false,
                        'mother_id': selectedAnimal.value!['identifier'],
                        'father_id': lastFatherId,
                        'birth_date': birthDate.toIso8601String(), // Passa a data do nascimento
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _handleBiologicalTriggers(DateTime baseDate) async {
    if (selectedAnimal.value == null) return;
    final animal = selectedAnimal.value!;
    final category = animal['category'] ?? "Bovino";
    final config = TecnicoConfigService.instance;

    // --- 1. GATILHO: APÓS INSEMINAÇÃO / MONTA ---
    if (selectedType.value == "Inseminação Artificial") {
      // Alerta de Toque
      int diasToque = (category == "Bovino") ? config.getBovToque() : config.getOviToque();
      await DatabaseHelper.instance.insertEvent(
        animal['id'], "Diagnóstico de Toque", "🔍 Agendado via IA: Confirmar gestação da matriz ${animal['identifier']}",
        manualDate: baseDate.add(Duration(days: diasToque)),
        isTask: 1, color_hex: "FF2196F3", // Azul Task
        herdId: animal['herd_id']
      );

      // Alerta de Retorno ao Cio (20 dias depois - véspera dos 21)
      int diasCio = (category == "Bovino") ? config.getBovCio() : config.getOviCio();
      await DatabaseHelper.instance.insertEvent(
        animal['id'], "Observação de Cio", "⚠️ Atenção ao Curral: Matriz ${animal['identifier']} pode retornar ao cio amanhã.",
        manualDate: baseDate.add(Duration(days: diasCio - 1)),
        isTask: 1, color_hex: "FFF44336", // Vermelho Alerta
        herdId: animal['herd_id']
      );
    }

    // --- 2. GATILHO: APÓS CONFIRMAÇÃO DE PRENHEZ (TOQUE POSITIVO) ---
    if (selectedType.value == "Diagnóstico de Toque" && touchResult.value == "Positivo") {
      // Cálculo do Parto Previsto (Gestações Médias: Bov 284 dias, Ovi/Cap 150 dias)
      int gestacaoMedia = (category == "Bovino") ? 284 : 150;
      DateTime dataPrevistaParto = baseDate.add(Duration(days: gestacaoMedia - 30)); // Aproximado do toque

      // Alerta de Secagem (Ex: 60 dias antes do parto)
      int diasSecagem = (category == "Bovino") ? config.getBovSecagem() : config.getOviSecagem();
      await DatabaseHelper.instance.insertEvent(
        animal['id'], "Manejo de Secagem", "🥛 Secagem: Interromper ordenha da matriz ${animal['identifier']} para descanso pré-parto.",
        manualDate: dataPrevistaParto.subtract(Duration(days: diasSecagem)),
        isTask: 1, color_hex: "FF9C27B0", // Roxo
        herdId: animal['herd_id']
      );

      // Alerta de Pré-Natal (Ex: 15 dias antes do parto)
      int diasNatal = (category == "Bovino") ? config.getBovParto() : config.getOviParto();
      await DatabaseHelper.instance.insertEvent(
        animal['id'], "Pré-Natal e Maternidade", "🍼 Preparação: Matriz ${animal['identifier']} próxima ao parto. Vacinar e isolar.",
        manualDate: dataPrevistaParto.subtract(Duration(days: diasNatal)),
        isTask: 1, color_hex: "FFFF9800", // Laranja
        herdId: animal['herd_id']
      );
    }

    // --- 3. GATILHO: APÓS NASCIMENTO (PVE) ---
    if (selectedType.value == "Nascimento") {
      int diasPve = (category == "Bovino") ? config.getBovPve() : config.getOviPve();
      await DatabaseHelper.instance.insertEvent(
        animal['id'], "Fim do PVE", "🔄 Matriz Apta: Recuperação pós-parto de ${animal['identifier']} concluída. Liberada para reprodução.",
        manualDate: baseDate.add(Duration(days: diasPve)),
        isTask: 1, color_hex: "FF4CAF50", // Verde
        herdId: animal['herd_id']
      );
    }

    if (Get.isRegistered<CalendarController>()) Get.find<CalendarController>().loadEvents();
  }

  void _syncData() {
    if (Get.isRegistered<ActivitiesHistoryController>()) Get.find<ActivitiesHistoryController>().loadAllEvents();
    if (Get.isRegistered<PerfilAnimalController>()) Get.find<PerfilAnimalController>().carregarDadosDoBanco(selectedAnimal.value!['id']);
    if (Get.isRegistered<CalendarController>()) Get.find<CalendarController>().loadEvents();
    
    // Dispara sincronização com a nuvem em background
    SyncService.instance.syncLocalToCloud();
  }

  void incrementFertility() {
    double current = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? 0.0;
    if (current < 1.0) {
      double next = (current + 0.1);
      if (next > 1.0) next = 1.0;
      value1Ctrl.text = next.toStringAsFixed(1);
    }
  }

  void decrementFertility() {
    double current = double.tryParse(value1Ctrl.text.replaceAll(',', '.')) ?? 0.0;
    if (current > 0.0) {
      double next = (current - 0.1);
      if (next < 0.0) next = 0.0;
      value1Ctrl.text = next.toStringAsFixed(1);
    }
  }

  @override
  void onClose() {
    value1Ctrl.dispose();
    value2Ctrl.dispose();
    descriptionCtrl.dispose();
    super.onClose();
  }
}
