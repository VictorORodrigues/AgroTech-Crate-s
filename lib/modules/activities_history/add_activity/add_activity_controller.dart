import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../activities_history_controller.dart';
import '../../rebanho/perfil_animal/perfil_animal_controller.dart';
import '../../calendar/calendar_controller.dart';

class AddActivityController extends GetxController {
  final Map<String, dynamic>? preSelectedAnimal = Get.arguments?['animal'];

  final List<String> types = [
    "Inseminação Artificial",
    "Pesagem e Escore",
    "Nascimento",
    "Vacinação",
    "Medicamento",
    "Diagnóstico de Toque",
    "Aborto / Perda Gestacional",
    "Produção de Leite",
    "Casqueamento",
    "Tosquia",
    "Outro"
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
  final value1Ctrl = TextEditingController(); // Peso, Litros, Fertilidade
  final value2Ctrl = TextEditingController(); // Usado apenas para compatibilidade legada se necessário
  var eccValue = 3.0.obs; // Escore de Condição Corporal Reativo
  final descriptionCtrl = TextEditingController();
  var touchResult = "Positivo".obs; // Positivo / Negativo
  
  var isLoading = false.obs;

  // Filtros de busca na BottomSheet
  var searchCategoryFilter = "Todos".obs; // Todos, Bovino, Ovino, Caprino
  var searchSexFilter = "Todos".obs; // Todos, Macho, Fêmea

  @override
  void onInit() {
    super.onInit();
    
    // Captura data vinda do calendário se existir
    final dynamic args = Get.arguments;
    if (args != null && args['selectedDate'] != null) {
      manualDate.value = args['selectedDate'];
    }

    if (preSelectedAnimal != null) {
      selectedAnimal.value = preSelectedAnimal;
    }
    loadAnimals();
    loadHerds();
    
    // Limpa o animal selecionado se o tipo de atividade mudar e ele não for mais compatível
    ever(selectedType, (String type) {
      if (selectedAnimal.value != null) {
        final animal = selectedAnimal.value!;
        bool isCompatible = true;

        if (type == "Inseminação Artificial") {
          isCompatible = animal['sex'] == 'Fêmea';
        } else if (type == "Nascimento") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Prenhe';
        } else if (type == "Aborto / Perda Gestacional") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Prenhe';
        } else if (type == "Produção de Leite") {
          isCompatible = animal['sex'] == 'Fêmea' && animal['reproductive_status'] == 'Em Lactação';
        } else if (type == "Diagnóstico de Toque") {
          isCompatible = animal['sex'] == 'Fêmea';
        }

        if (!isCompatible) {
          selectedAnimal.value = null;
        }
      }
    });
    
    // Sincroniza fertilidade se mudar o reprodutor
    ever(selectedReprodutor, (Map<String, dynamic>? sire) {
      if (sire != null) {
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
      WHERE a.sex = 'Macho' AND h.category = ?
    ''', [category]);
    potentialSires.value = result;
  }

  List<Map<String, dynamic>> getFilteredAnimalsList(String query) {
    List<Map<String, dynamic>> baseList = allAnimals;

    // 1. Filtros biológicos obrigatórios por tipo de atividade
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

    // 2. Filtros de Interface (Categoria e Sexo)
    return baseList.where((a) {
      final q = query.toLowerCase();
      final matchesQuery = 
          a['identifier'].toString().toLowerCase().contains(q) ||
          (a['name'] ?? "").toString().toLowerCase().contains(q) ||
          (a['breed_name'] ?? "").toString().toLowerCase().contains(q) ||
          (a['herd_name'] ?? "").toString().toLowerCase().contains(q);
      
      final matchesCategory = searchCategoryFilter.value == "Todos" || a['category'] == searchCategoryFilter.value;
      
      // O filtro de sexo da interface respeita o filtro biológico (se já estiver filtrado pra Fêmea, o filtro Macho não mostrará nada)
      final matchesSex = searchSexFilter.value == "Todos" || a['sex'] == searchSexFilter.value;

      return matchesQuery && matchesCategory && matchesSex;
    }).toList();
  }

  // Mantido para compatibilidade se usado em outro lugar, mas o ideal é usar o método acima na busca
  List<Map<String, dynamic>> get filteredAnimals => getFilteredAnimalsList("");

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
      isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      // Monta a data e hora final combinando os seletores manuais
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
        // Salva status anterior no t2 para reversão
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Vazia / Apta";
        t2 = "N/A#$prevStatus";
        
        String novoStatus = touchResult.value == "Positivo" ? "Prenhe" : "Vazia / Apta";
        await db.update('animals', {'reproductive_status': novoStatus}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      if (selectedType.value == "Inseminação Artificial") {
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Vazia / Apta";
        await db.update('animals', {'reproductive_status': "Inseminada"}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        t1 = inseminationType.value;
        
        if (inseminationType.value == "Monta") {
          t2 = "${selectedReprodutor.value?['identifier']}#$prevStatus";
          v1 = val1; // Fertilidade
        } else {
          t2 = "N/A#$prevStatus";
        }
      }

      if (selectedType.value == "Aborto / Perda Gestacional") {
        // Salva status anterior para reversão no t2
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Prenhe";
        t2 = "N/A#$prevStatus";
        await db.update('animals', {'reproductive_status': "Vazia / Apta"}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      if (selectedType.value == "Pesagem e Escore") {
        v1 = val1; // Peso Atual
        v2 = eccValue.value; // ECC Atual
        t1 = selectedAnimal.value!['weight']?.toString() ?? "0.0";
        t2 = selectedAnimal.value!['ecc']?.toString() ?? "3.0";

        if (val1 != null) await db.update('animals', {'weight': val1}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        await db.update('animals', {'ecc': eccValue.value}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
      }

      if (selectedType.value == "Vacinação") {
        t1 = value1Ctrl.text.trim();
      }

      if (selectedType.value == "Medicamento") {
        t1 = value1Ctrl.text.trim();
      }

      if (selectedType.value == "Produção de Leite") {
        v1 = val1;
      }

      if (selectedType.value == "Outro") {
        t1 = value1Ctrl.text.trim(); // Nome da atividade
      }

      if (selectedType.value != "Nascimento") {
        await DatabaseHelper.instance.insertEvent(
          selectedAnimal.value?['id'] ?? 0, // 0 ou null dependendo da sua regra de DB
          selectedType.value == "Outro" ? t1! : selectedType.value,
          description,
          v1: v1,
          v2: v2,
          t1: t1,
          t2: t2,
          manualDate: finalDateTime,
        );
      }

      if (selectedType.value == "Nascimento") {
        // Salva paridade e status anteriores
        String prevParity = selectedAnimal.value!['parity']?.toString() ?? "Nulípara";
        String prevStatus = selectedAnimal.value!['reproductive_status']?.toString() ?? "Prenhe";
        
        await db.update('animals', {'reproductive_status': 'Em Lactação'}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        
        String nextParity = prevParity;
        if (prevParity == "Nulípara") nextParity = "Primípara";
        else if (prevParity == "Primípara") nextParity = "Multípara";
        
        if (nextParity != prevParity) {
          await db.update('animals', {'parity': nextParity}, where: 'id = ?', whereArgs: [selectedAnimal.value!['id']]);
        }

        await DatabaseHelper.instance.insertEvent(
          selectedAnimal.value!['id'],
          selectedType.value,
          description,
          t1: prevParity,
          t2: prevStatus,
          manualDate: finalDateTime,
        );
        
        _showBirthFlow();
      } else {
        Get.back();
        AgroAlert.show(title: "Sucesso", message: "Atividade registrada!", isSuccess: true);
      }

      _syncData();
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao salvar: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _showBirthFlow() async {
    // 1. Pergunta se quer cadastrar a cria
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nascimento Registrado! 👶"),
        content: const Text("Deseja cadastrar o animal que acabou de nascer agora?"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Fecha diálogo
              Get.back(); // Volta para tela de atividades
            },
            child: const Text("NÃO", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Fecha diálogo
              _selectHerdForNewborn();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text("SIM, CADASTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _selectHerdForNewborn() async {
    final db = await DatabaseHelper.instance.database;
    // Busca rebanhos da mesma categoria da mãe
    final herds = await db.query('herds', where: 'category = ?', whereArgs: [selectedAnimal.value!['category']]);

    // Busca o pai da última inseminação/monta para preencher no novo cadastro
    final lastInsemination = await db.query(
      'animal_events',
      where: 'animal_id = ? AND type = ?',
      whereArgs: [selectedAnimal.value!['id'], 'Inseminação Artificial'],
      orderBy: 'date DESC',
      limit: 1,
    );

    String? lastFatherId;
    if (lastInsemination.isNotEmpty) {
      // Se foi monta, o ID do pai está no text_value_2
      if (lastInsemination.first['text_value_1'] == "Monta") {
        lastFatherId = lastInsemination.first['text_value_2']?.toString();
      }
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const Text("Selecione o Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Em qual rebanho a cria será cadastrada?", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: herds.length,
                itemBuilder: (context, index) {
                  final h = herds[index];
                  return ListTile(
                    leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                    title: Text(h['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${h['category']} | ${h['management_type']}"),
                    onTap: () {
                      Get.back(); // Fecha bottomsheet
                      Get.back(); // Volta para tela de atividades
                      Get.toNamed('/add-animal', arguments: {
                        'herd': h,
                        'isEdition': false,
                        'mother_id': selectedAnimal.value!['identifier'],
                        'father_id': lastFatherId, // Passa o pai detectado
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

  void _syncData() {
    if (Get.isRegistered<ActivitiesHistoryController>()) {
      Get.find<ActivitiesHistoryController>().loadAllEvents();
    }
    if (Get.isRegistered<PerfilAnimalController>()) {
      Get.find<PerfilAnimalController>().carregarDadosDoBanco(selectedAnimal.value!['id']);
    }
    if (Get.isRegistered<CalendarController>()) {
      Get.find<CalendarController>().loadEvents();
    }
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
