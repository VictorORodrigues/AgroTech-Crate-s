import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../detalhes_rebanho/detalhes_rebanho_controller.dart';
import '../rebanho_controller.dart';
import '../../../services/sync_service.dart';

class PerfilAnimalController extends GetxController {
  late Map<String, dynamic> animalInicial;
  var animal = <String, dynamic>{}.obs;
  var photoPath = "".obs;
  var pdfPath = "".obs;
  final ImagePicker _picker = ImagePicker();

  var isEditing = false.obs;

  // Controllers para edição
  late TextEditingController idCtrl;
  late TextEditingController nomeAnimalCtrl;
  late TextEditingController racaNomeCtrl;
  late TextEditingController pesoCtrl;
  late TextEditingController idadeCtrl;
  late TextEditingController linhagemCtrl;
  late TextEditingController fertilidadeSemenCtrl;
  
  var sexoSelecionado = "".obs;
  var racaSelecionada = "".obs;
  var paritySelecionada = "".obs;
  var dppSelecionado = "".obs; 
  var statusSelecionado = "".obs;
  var eccValue = 3.0.obs;
  var aptidaoSelecionada = "".obs;

  // Pais
  var idPaiSelecionado = "Desconhecido".obs;
  var idMaeSelecionada = "Desconhecido".obs;
  var potentialFathers = <Map<String, dynamic>>[].obs;
  var potentialMothers = <Map<String, dynamic>>[].obs;

  // Histórico e Filtros
  var allEvents = <Map<String, dynamic>>[].obs;
  var selectedHistoryFilter = "Todos".obs; // Todos, Nutrição, Reprodução, Saúde
  var isLoadingHistory = false.obs;

  final List<String> racas = [
    "Nativa Pura",
    "Mestiço Sertanejo",
    "Mestiço Exótico",
    "Exótica Pura",
    "SRD (Comum)"
  ];
  final List<String> paridades = ["Nulípara", "Primípara", "Multípara"];
  final List<String> dppOpcoes = ["Parto Recente", "Parto Médio", "Parto Antigo"];
  final List<String> statusOpcoes = ["Prenhe", "Vazia / Apta", "Em Lactação", "Inseminada"];
  final List<String> aptidoes = ["Rústico", "Alta produção"];

  @override
  void onInit() {
    super.onInit();
    
    // Recuperação ultra-segura de argumentos
    final dynamic args = Get.arguments;
    if (args != null && args is Map) {
      animalInicial = Map<String, dynamic>.from(args);
    } else {
      animalInicial = {'id': 0, 'identifier': 'N/A', 'herd_id': 0, 'breed': 'SRD'};
    }

    animal.value = animalInicial;
    photoPath.value = animalInicial['photo_path'] ?? "";
    pdfPath.value = animalInicial['pdf_path'] ?? "";
    
    _initControllers();
    _fetchCategoryAndParents();
  }

  void _initControllers() {
    idCtrl = TextEditingController(text: animal['identifier']?.toString());
    nomeAnimalCtrl = TextEditingController(text: animal['name']?.toString() ?? "");
    racaNomeCtrl = TextEditingController(text: animal['breed_name']?.toString() ?? "");
    pesoCtrl = TextEditingController(text: animal['weight']?.toString() ?? "0.0");
    idadeCtrl = TextEditingController(text: animal['age_months']?.toString() ?? "0");
    linhagemCtrl = TextEditingController(text: animal['lineage']?.toString() ?? "");
    fertilidadeSemenCtrl = TextEditingController(text: (animal['semen_fertility'] ?? 0.0).toString());
    
    sexoSelecionado.value = animal['sex']?.toString() ?? "";
    racaSelecionada.value = animal['breed']?.toString() ?? "";
    paritySelecionada.value = animal['parity']?.toString() ?? "";
    dppSelecionado.value = animal['dpp_status']?.toString() ?? ""; 
    statusSelecionado.value = animal['reproductive_status']?.toString() ?? "";
    eccValue.value = double.tryParse(animal['ecc']?.toString() ?? "3.0") ?? 3.0;
    aptidaoSelecionada.value = animal['aptitude']?.toString() ?? "";
    idPaiSelecionado.value = animal['id_pai']?.toString() ?? "Desconhecido";
    idMaeSelecionada.value = animal['id_mae']?.toString() ?? "Desconhecido";
  }

  Future<void> carregarDadosDoBanco(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('animals', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      var data = Map<String, dynamic>.from(result.first);
      
      // AUTO-CORREÇÃO DE DADOS CORROMPIDOS (Legacy fix)
      if (data['parity'] != null && (data['parity'].toString().contains('#') || data['parity'].toString().contains('|'))) {
        data['parity'] = data['parity'].toString().split('#').first.split('|').first.trim();
        // Se após o split o valor for inválido, assumimos um padrão seguro
        if (!paridades.contains(data['parity'])) data['parity'] = "Multípara";
      }
      if (data['reproductive_status'] != null && data['reproductive_status'].toString().contains('#')) {
        data['reproductive_status'] = data['reproductive_status'].toString().split('#').last.trim();
        if (!statusOpcoes.contains(data['reproductive_status'])) data['reproductive_status'] = "Em Lactação";
      }

      animal.value = data;
      photoPath.value = animal['photo_path'] ?? "";
      pdfPath.value = animal['pdf_path'] ?? "";
      _fetchCategoryAndParents();
    }
  }

  void _fetchCategoryAndParents() async {
    final db = await DatabaseHelper.instance.database;
    final herd = await db.query('herds', where: 'id = ?', whereArgs: [animal['herd_id']]);
    if (herd.isNotEmpty) {
      var novoAnimal = Map<String, dynamic>.from(animal.value);
      final String category = herd.first['category'] as String;
      novoAnimal['category'] = category;
      animal.value = novoAnimal;

      potentialFathers.value = await DatabaseHelper.instance.getPotentialParents('Macho', category);
      potentialMothers.value = await DatabaseHelper.instance.getPotentialParents('Fêmea', category);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), 
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: Colors.green[800],
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, 
          ),
        ],
      );

      if (croppedFile != null) {
        photoPath.value = croppedFile.path;
        await _updatePhotoInDatabase(croppedFile.path);
      }
    }
  }

  Future<void> removePhoto() async {
    photoPath.value = "";
    await _updatePhotoInDatabase("");
  }

  Future<void> pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        pdfPath.value = path;
        
        final db = await DatabaseHelper.instance.database;
        await db.update('animals', {'pdf_path': path}, where: 'id = ?', whereArgs: [animal['id']]);
        
        AgroAlert.show(title: "PDF Salvo", message: "Documento de rastreabilidade vinculado!", isSuccess: true);
        _syncWithLocalData();
      }
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao selecionar arquivo: $e", isError: true);
    }
  }

  Future<void> openPDF() async {
    if (pdfPath.value.isNotEmpty) {
      final result = await OpenFilex.open(pdfPath.value);
      if (result.type != ResultType.done) {
        AgroAlert.show(title: "Erro ao abrir", message: result.message, isError: true);
      }
    }
  }

  Future<void> removePDF() async {
    pdfPath.value = "";
    final db = await DatabaseHelper.instance.database;
    await db.update('animals', {'pdf_path': ""}, where: 'id = ?', whereArgs: [animal['id']]);
    _syncWithLocalData();
  }

  Future<void> _updatePhotoInDatabase(String path) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('animals', {'photo_path': path}, where: 'id = ?', whereArgs: [animal['id']]);
    _syncWithLocalData();
  }

  Future<void> loadAnimalHistory() async {
    try {
      isLoadingHistory.value = true;
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> results = await db.query(
        'animal_events',
        where: 'animal_id = ?',
        whereArgs: [animal['id']],
        orderBy: 'date DESC',
      );
      allEvents.value = results;
    } catch (e) {
      print("Erro ao carregar histórico: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredHistory {
    if (selectedHistoryFilter.value == "Todos") return allEvents;

    return allEvents.where((e) {
      final type = e['type']?.toString() ?? "";
      
      if (selectedHistoryFilter.value == "Nutrição") {
        return type == "Produção de Leite" || type == "Pesagem e Escore";
      }
      if (selectedHistoryFilter.value == "Reprodução") {
        return type == "Inseminação Artificial" || type == "Nascimento" || 
               type == "Diagnóstico de Toque" || type == "Aborto / Perda Gestacional";
      }
      if (selectedHistoryFilter.value == "Saúde") {
        return type == "Vacinação" || type == "Medicamento" || type == "Casqueamento" || type == "Tosquia";
      }
      return true;
    }).toList();
  }

  Future<void> saveChanges() async {
    if (idCtrl.text.isEmpty) {
      AgroAlert.show(title: "Erro", message: "O identificador não pode estar vazio", isError: true);
      return;
    }

    final updatedData = {
      'identifier': idCtrl.text.trim(),
      'name': nomeAnimalCtrl.text.trim(),
      'breed_name': racaNomeCtrl.text.trim(),
      'weight': double.tryParse(pesoCtrl.text) ?? 0.0,
      'age_months': int.tryParse(idadeCtrl.text) ?? 0,
      'sex': sexoSelecionado.value,
      'breed': racaSelecionada.value,
      'ecc': eccValue.value,
      'lineage': linhagemCtrl.text.trim(),
      'id_pai': idPaiSelecionado.value,
      'id_mae': idMaeSelecionada.value,
      'aptitude': aptidaoSelecionada.value,
      'semen_fertility': double.tryParse(fertilidadeSemenCtrl.text) ?? 0.0,
      'parity': paritySelecionada.value,
      'dpp_status': dppSelecionado.value, 
      'reproductive_status': statusSelecionado.value,
    };

    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.updateAnimal(animal['id'], updatedData);

    var novoAnimal = Map<String, dynamic>.from(animal.value);
    novoAnimal.addAll(updatedData);
    animal.value = novoAnimal;

    isEditing.value = false;
    _syncWithLocalData();
    AgroAlert.show(title: "Sucesso", message: "Dados do animal atualizados!", isSuccess: true);
  }

  Future<List<Map<String, dynamic>>> getAvailableHerds() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'herds',
      where: 'category = ? AND id != ?',
      whereArgs: [animal['category'], animal['herd_id']],
    );
  }

  Future<void> relocateAnimal(int targetHerdId, String targetHerdName) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'animals',
        {'herd_id': targetHerdId},
        where: 'id = ?',
        whereArgs: [animal['id']],
      );

      // Atualiza o objeto local
      var novoAnimal = Map<String, dynamic>.from(animal.value);
      novoAnimal['herd_id'] = targetHerdId;
      animal.value = novoAnimal;

      _syncWithLocalData();
      Get.back(); // Fecha o seletor
      AgroAlert.show(
        title: "Realocado!",
        message: "O animal foi movido para o rebanho $targetHerdName",
        isSuccess: true,
      );
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao realocar: $e", isError: true);
    }
  }

  void _syncWithLocalData() {
    if (Get.isRegistered<DetalhesRebanhoController>()) {
      Get.find<DetalhesRebanhoController>().carregarDados();
    }
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
    SyncService.instance.syncLocalToCloud();
  }

  @override
  void onClose() {
    idCtrl.dispose();
    nomeAnimalCtrl.dispose();
    racaNomeCtrl.dispose();
    pesoCtrl.dispose();
    idadeCtrl.dispose();
    linhagemCtrl.dispose();
    fertilidadeSemenCtrl.dispose();
    super.onClose();
  }
}
