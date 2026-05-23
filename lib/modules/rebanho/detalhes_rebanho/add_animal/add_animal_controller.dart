import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../detalhes_rebanho_controller.dart';
import '../../rebanho_controller.dart';
import '../../perfil_animal/perfil_animal_controller.dart';
import '../../../ia_analysis/ia_model.dart';

class AddAnimalController extends GetxController {
  final Map<String, dynamic> herd = Get.arguments['herd'];
  final bool isEdition = Get.arguments['isEdition'] ?? false;
  final Map<String, dynamic>? animalToEdit = Get.arguments['animal'];

  final idCtrl = TextEditingController();
  final nomeAnimalCtrl = TextEditingController();
  final racaNomeCtrl = TextEditingController();
  final pesoCtrl = TextEditingController();
  final idadeCtrl = TextEditingController();
  final linhagemCtrl = TextEditingController();
  final fertilidadeSemenCtrl = TextEditingController();
  
  var photoPath = "".obs;
  final ImagePicker _picker = ImagePicker();
  
  var sexoSelecionado = "".obs;
  var paridadeSelecionada = "".obs;
  var dppSelecionado = "".obs; 
  var statusAtualSelecionado = "".obs;
  var eccValue = 3.0.obs;
  var racaSelecionada = "".obs;
  var aptidaoSelecionada = "".obs;

  var idPaiSelecionado = "Desconhecido".obs;
  var idMaeSelecionada = "Desconhecido".obs;
  var potentialFathers = <Map<String, dynamic>>[].obs;
  var potentialMothers = <Map<String, dynamic>>[].obs;
  var existingLineages = <String>[].obs;

  var idError = Rxn<String>();
  var pesoError = Rxn<String>();
  var idadeError = Rxn<String>();
  var sexoError = Rxn<String>();
  var racaError = Rxn<String>();
  var semenFertilityError = Rxn<String>();

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
    _loadInitialData();
    if (isEdition && animalToEdit != null) {
      _fillData();
    }
  }

  void _loadInitialData() async {
    _loadPotentialParents();
    existingLineages.value = await DatabaseHelper.instance.getUniqueLineages();
  }

  void _fillData() {
    idCtrl.text = animalToEdit!['identifier'];
    nomeAnimalCtrl.text = animalToEdit!['name'] ?? "";
    racaNomeCtrl.text = animalToEdit!['breed_name'] ?? "";
    pesoCtrl.text = animalToEdit!['weight'].toString();
    idadeCtrl.text = animalToEdit!['age_months'].toString();
    linhagemCtrl.text = animalToEdit!['lineage'] ?? "";
    sexoSelecionado.value = animalToEdit!['sex'] ?? "";
    racaSelecionada.value = animalToEdit!['breed'] ?? "";
    eccValue.value = (animalToEdit!['ecc'] ?? 3.0).toDouble();
    paridadeSelecionada.value = animalToEdit!['parity'] ?? "";
    dppSelecionado.value = animalToEdit!['dpp_status'] ?? "";
    statusAtualSelecionado.value = animalToEdit!['reproductive_status'] ?? "";
    idPaiSelecionado.value = animalToEdit!['id_pai'] ?? "Desconhecido";
    idMaeSelecionada.value = animalToEdit!['id_mae'] ?? "Desconhecido";
    aptidaoSelecionada.value = animalToEdit!['aptitude'] ?? "";
    fertilidadeSemenCtrl.text = (animalToEdit!['semen_fertility'] ?? 0.0).toString();
    photoPath.value = animalToEdit!['photo_path'] ?? "";
  }

  void _loadPotentialParents() async {
    int? excludeId = isEdition ? animalToEdit!['id'] : null;
    potentialFathers.value = await DatabaseHelper.instance.getPotentialParents('Macho', herd['category'], excludeId: excludeId);
    potentialMothers.value = await DatabaseHelper.instance.getPotentialParents('Fêmea', herd['category'], excludeId: excludeId);
  }

  void setParidade(String? value) {
    paridadeSelecionada.value = value ?? "";
    if (value == "Nulípara") {
      statusAtualSelecionado.value = "🟡 Vazia / Apta";
      dppSelecionado.value = "";
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
      }
    }
  }

  void removePhoto() => photoPath.value = "";

  bool validarFormulario() {
    bool isValid = true;
    if (idCtrl.text.trim().isEmpty) {
      idError.value = "Obrigatório";
      isValid = false;
    } else idError.value = null;
    
    if (pesoCtrl.text.isEmpty) {
      pesoError.value = "Obrigatório";
      isValid = false;
    } else pesoError.value = null;

    if (idadeCtrl.text.isEmpty) {
      idadeError.value = "Obrigatório";
      isValid = false;
    } else idadeError.value = null;

    if (sexoSelecionado.value.isEmpty) {
      sexoError.value = "Obrigatório";
      isValid = false;
    } else sexoError.value = null;

    if (racaSelecionada.value.isEmpty) {
      racaError.value = "Obrigatório";
      isValid = false;
    } else racaError.value = null;

    if (sexoSelecionado.value == "Macho" && fertilidadeSemenCtrl.text.isNotEmpty) {
      double? val = double.tryParse(fertilidadeSemenCtrl.text);
      if (val == null || val < 0.0 || val > 1.0) {
        semenFertilityError.value = "Valor deve ser entre 0.0 e 1.0";
        isValid = false;
      } else {
        semenFertilityError.value = null;
      }
    } else {
      semenFertilityError.value = null;
    }

    return isValid;
  }

  Future<void> salvar() async {
    if (!validarFormulario()) return;

    final data = {
      'herd_id': herd['id'],
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
      'parity': paridadeSelecionada.value,
      'dpp_status': dppSelecionado.value,
      'reproductive_status': statusAtualSelecionado.value,
      'photo_path': photoPath.value,
    };

    if (isEdition) {
      final db = await DatabaseHelper.instance.database;
      await db.update('animals', data, where: 'id = ?', whereArgs: [animalToEdit!['id']]);
    } else {
      await DatabaseHelper.instance.insertAnimal(data);
    }

    if (Get.isRegistered<DetalhesRebanhoController>()) {
      Get.find<DetalhesRebanhoController>().carregarDados();
    }
    if (Get.isRegistered<RebanhoController>()) {
      Get.find<RebanhoController>().carregarRebanhos();
    }
    if (Get.isRegistered<PerfilAnimalController>()) {
      Get.find<PerfilAnimalController>().animal.value = Map<String, dynamic>.from(data)..addAll({'id': isEdition ? animalToEdit!['id'] : 0});
      Get.find<PerfilAnimalController>().photoPath.value = photoPath.value;
    }

    Get.back();
    AgroAlert.show(title: "Sucesso", message: isEdition ? "Animal atualizado!" : "Animal adicionado!", isSuccess: true);
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
