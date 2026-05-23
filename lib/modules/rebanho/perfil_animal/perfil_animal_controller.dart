import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../detalhes_rebanho/detalhes_rebanho_controller.dart';
import '../rebanho_controller.dart';

class PerfilAnimalController extends GetxController {
  final Map<String, dynamic> animalInicial = Get.arguments;
  var animal = <String, dynamic>{}.obs;
  var photoPath = "".obs;
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

  final List<String> racas = [
    "Nativa Pura (Moxotó, Repartida, Cariri...)",
    "Mestiço Sertanejo (Cruzamento local resistente)",
    "Mestiço Exótico (Cruzamento focado em produção)",
    "Exótica Pura (Saanen, Anglo-Nubiana, Holandesa...)",
    "Sem Raça Definida (SRD / Comum)"
  ];
  final List<String> paridades = ["Nulípara", "Primípara", "Multípara"];
  final List<String> dppOpcoes = ["Parto Recente", "Parto Médio", "Parto Antigo"];
  final List<String> statusOpcoes = ["🟢 Prenhe", "🟡 Vazia / Apta", "🔵 Em Lactação"];
  final List<String> aptidoes = ["Rústico", "Alta produção"];

  @override
  void onInit() {
    super.onInit();
    animal.value = animalInicial;
    photoPath.value = animalInicial['photo_path'] ?? "";
    
    // Inicializa controllers com os dados atuais
    idCtrl = TextEditingController(text: animal['identifier']);
    nomeAnimalCtrl = TextEditingController(text: animal['name'] ?? "");
    racaNomeCtrl = TextEditingController(text: animal['breed_name'] ?? "");
    pesoCtrl = TextEditingController(text: animal['weight'].toString());
    idadeCtrl = TextEditingController(text: animal['age_months'].toString());
    linhagemCtrl = TextEditingController(text: animal['lineage'] ?? "");
    fertilidadeSemenCtrl = TextEditingController(text: (animal['semen_fertility'] ?? 0.0).toString());
    
    sexoSelecionado.value = animal['sex'] ?? "";
    racaSelecionada.value = animal['breed'] ?? "";
    paritySelecionada.value = animal['parity'] ?? "";
    dppSelecionado.value = animal['dpp_status'] ?? ""; 
    statusSelecionado.value = animal['reproductive_status'] ?? "";
    eccValue.value = (animal['ecc'] ?? 3.0).toDouble();
    aptidaoSelecionada.value = animal['aptitude'] ?? "";
    idPaiSelecionado.value = animal['id_pai'] ?? "Desconhecido";
    idMaeSelecionada.value = animal['id_mae'] ?? "Desconhecido";

    _fetchCategoryAndParents();
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

  Future<void> _updatePhotoInDatabase(String path) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('animals', {'photo_path': path}, where: 'id = ?', whereArgs: [animal['id']]);
    _syncWithLocalData();
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
    await db.update('animals', updatedData, where: 'id = ?', whereArgs: [animal['id']]);

    var novoAnimal = Map<String, dynamic>.from(animal.value);
    novoAnimal.addAll(updatedData);
    animal.value = novoAnimal;

    isEditing.value = false;
    _syncWithLocalData();
    AgroAlert.show(title: "Sucesso", message: "Dados do animal atualizados!", isSuccess: true);
  }

  void _syncWithLocalData() {
    if (Get.isRegistered<DetalhesRebanhoController>()) {
      Get.find<DetalhesRebanhoController>().carregarDados();
    }
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
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
