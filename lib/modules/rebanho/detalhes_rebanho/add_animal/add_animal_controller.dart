import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/agro_alerts.dart';
import '../detalhes_rebanho_controller.dart';
import '../../rebanho_controller.dart';
import '../../perfil_animal/perfil_animal_controller.dart';
import '../../../ia_analysis/ia_model.dart';

class AddAnimalController extends GetxController {
  // Dados passados por argumentos
  late Map<String, dynamic> herd;
  late bool isEdition;
  late Map<String, dynamic>? animalToEdit;

  // Controllers para os campos de texto
  final idCtrl = TextEditingController();
  final nomeAnimalCtrl = TextEditingController();
  final racaNomeCtrl = TextEditingController();
  final pesoCtrl = TextEditingController();
  final idadeCtrl = TextEditingController();
  final linhagemCtrl = TextEditingController();
  final fertilidadeSemenCtrl = TextEditingController();
  
  var photoPath = "".obs;
  var pdfPath = "".obs;
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
  var statusError = Rxn<String>();
  var paridadeError = Rxn<String>();
  var semenFertilityError = Rxn<String>();

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
    
    // Recuperação segura de argumentos para evitar o erro de 'Null subtype of Map'
    final dynamic args = Get.arguments;
    if (args != null && args is Map) {
      herd = args['herd'] ?? {'id': 0, 'category': 'Bovino'};
      isEdition = args['isEdition'] ?? false;
      animalToEdit = args['animal'];
    } else {
      // Fallback de segurança caso o Get.arguments falhe por algum motivo
      herd = {'id': 0, 'category': 'Bovino'};
      isEdition = false;
      animalToEdit = null;
    }

    _loadInitialData();
    if (isEdition && animalToEdit != null) {
      _fillData();
    }
  }

  void _loadInitialData() async {
    _loadPotentialParents();
    existingLineages.value = await DatabaseHelper.instance.getUniqueLineages();
    
    // Pre-preenchimento vindo de Nascimento
    final dynamic args = Get.arguments;
    if (args != null) {
      if (args['mother_id'] != null) idMaeSelecionada.value = args['mother_id'];
      if (args['father_id'] != null) idPaiSelecionado.value = args['father_id'];
    }
  }

  void _fillData() {
    idCtrl.text = animalToEdit!['identifier'] ?? "";
    nomeAnimalCtrl.text = animalToEdit!['name'] ?? "";
    racaNomeCtrl.text = animalToEdit!['breed_name'] ?? "";
    pesoCtrl.text = animalToEdit!['weight']?.toString() ?? "";
    idadeCtrl.text = animalToEdit!['age_months']?.toString() ?? "";
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
    pdfPath.value = animalToEdit!['pdf_path'] ?? "";
  }

  void _loadPotentialParents() async {
    int? excludeId = isEdition && animalToEdit != null ? animalToEdit!['id'] : null;
    potentialFathers.value = await DatabaseHelper.instance.getPotentialParents('Macho', herd['category'], excludeId: excludeId);
    potentialMothers.value = await DatabaseHelper.instance.getPotentialParents('Fêmea', herd['category'], excludeId: excludeId);
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

  Future<void> pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        pdfPath.value = result.files.single.path!;
      }
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao selecionar arquivo: $e", isError: true);
    }
  }

  void removePDF() => pdfPath.value = "";

  bool hasChanges() {
    if (!isEdition || animalToEdit == null) {
      // Se for novo cadastro, verifica se algum campo foi preenchido
      return idCtrl.text.isNotEmpty || 
             nomeAnimalCtrl.text.isNotEmpty || 
             racaNomeCtrl.text.isNotEmpty ||
             pesoCtrl.text.isNotEmpty ||
             idadeCtrl.text.isNotEmpty ||
             sexoSelecionado.value.isNotEmpty ||
             photoPath.value.isNotEmpty;
    }

    // Se for edição, compara com os valores originais
    bool changed = idCtrl.text != (animalToEdit!['identifier'] ?? "") ||
        nomeAnimalCtrl.text != (animalToEdit!['name'] ?? "") ||
        racaNomeCtrl.text != (animalToEdit!['breed_name'] ?? "") ||
        pesoCtrl.text != (animalToEdit!['weight']?.toString() ?? "") ||
        idadeCtrl.text != (animalToEdit!['age_months']?.toString() ?? "") ||
        linhagemCtrl.text != (animalToEdit!['lineage'] ?? "") ||
        sexoSelecionado.value != (animalToEdit!['sex'] ?? "") ||
        racaSelecionada.value != (animalToEdit!['breed'] ?? "") ||
        eccValue.value != (animalToEdit!['ecc'] ?? 3.0) ||
        paridadeSelecionada.value != (animalToEdit!['parity'] ?? "") ||
        dppSelecionado.value != (animalToEdit!['dpp_status'] ?? "") ||
        statusAtualSelecionado.value != (animalToEdit!['reproductive_status'] ?? "") ||
        idPaiSelecionado.value != (animalToEdit!['id_pai'] ?? "Desconhecido") ||
        idMaeSelecionada.value != (animalToEdit!['id_mae'] ?? "Desconhecido") ||
        aptidaoSelecionada.value != (animalToEdit!['aptitude'] ?? "") ||
        fertilidadeSemenCtrl.text != (animalToEdit!['semen_fertility']?.toString() ?? "0.0") ||
        photoPath.value != (animalToEdit!['photo_path'] ?? "") ||
        pdfPath.value != (animalToEdit!['pdf_path'] ?? "");

    return changed;
  }

  bool validarFormulario() {
    bool isValid = true;
    if (idCtrl.text.trim().isEmpty) {
      idError.value = "Obrigatório";
      isValid = false;
    } else idError.value = null;
    
    double pesoMax = 2000;
    int idadeMax = 600;
    if (herd['category'] == 'Ovino' || herd['category'] == 'Caprino') {
      pesoMax = 200;
      idadeMax = (herd['category'] == 'Ovino') ? 250 : 200;
    }

    if (pesoCtrl.text.isEmpty) {
      pesoError.value = "Obrigatório";
      isValid = false;
    } else {
      double? p = double.tryParse(pesoCtrl.text.replaceAll(',', '.'));
      if (p == null || p <= 0 || p > pesoMax) {
        pesoError.value = "Máx: ${pesoMax}kg";
        isValid = false;
      } else pesoError.value = null;
    }

    if (idadeCtrl.text.isEmpty) {
      idadeError.value = "Obrigatório";
      isValid = false;
    } else {
      int? i = int.tryParse(idadeCtrl.text);
      if (i == null || i <= 0 || i > idadeMax) {
        idadeError.value = "Máx: ${idadeMax}m";
        isValid = false;
      } else idadeError.value = null;
    }

    if (sexoSelecionado.value.isEmpty) {
      sexoError.value = "Obrigatório";
      isValid = false;
    } else sexoError.value = null;

    if (racaSelecionada.value.isEmpty) {
      racaError.value = "Obrigatório";
      isValid = false;
    } else racaError.value = null;

    if (sexoSelecionado.value == "Fêmea") {
      if (paridadeSelecionada.value.isEmpty) {
        paridadeError.value = "Obrigatório";
        isValid = false;
      } else {
        paridadeError.value = null;
      }
      
      if (statusAtualSelecionado.value.isEmpty) {
        statusError.value = "Obrigatório";
        isValid = false;
      } else {
        statusError.value = null;
      }
    }

    if (sexoSelecionado.value == "Macho" && fertilidadeSemenCtrl.text.isNotEmpty) {
      double? val = double.tryParse(fertilidadeSemenCtrl.text.replaceAll(',', '.'));
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

  void incrementFertility() {
    double current = double.tryParse(fertilidadeSemenCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (current < 1.0) {
      double next = (current + 0.1);
      if (next > 1.0) next = 1.0;
      fertilidadeSemenCtrl.text = next.toStringAsFixed(1);
    }
  }

  void decrementFertility() {
    double current = double.tryParse(fertilidadeSemenCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (current > 0.0) {
      double next = (current - 0.1);
      if (next < 0.0) next = 0.0;
      fertilidadeSemenCtrl.text = next.toStringAsFixed(1);
    }
  }

  void setParidade(String? value) {
    paridadeSelecionada.value = value ?? "";
    if (value == "Nulípara") {
      statusAtualSelecionado.value = "Vazia / Apta";
    }
  }

  Future<void> salvar() async {
    if (!validarFormulario()) return;

    // Tratamento de números para evitar erros de localidade (vírgula vs ponto)
    double peso = double.tryParse(pesoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    int idade = int.tryParse(idadeCtrl.text) ?? 0;
    double fertilidade = double.tryParse(fertilidadeSemenCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final data = {
      'herd_id': herd['id'],
      'identifier': idCtrl.text.trim(),
      'name': nomeAnimalCtrl.text.trim(),
      'breed_name': racaNomeCtrl.text.trim(),
      'weight': peso,
      'age_months': idade,
      'sex': sexoSelecionado.value,
      'breed': racaSelecionada.value,
      'ecc': eccValue.value,
      'lineage': linhagemCtrl.text.trim(),
      'id_pai': idPaiSelecionado.value,
      'id_mae': idMaeSelecionada.value,
      'aptitude': aptidaoSelecionada.value,
      'semen_fertility': fertilidade,
      'parity': paridadeSelecionada.value,
      'dpp_status': dppSelecionado.value,
      'reproductive_status': statusAtualSelecionado.value,
      'photo_path': photoPath.value,
      'pdf_path': pdfPath.value,
    };

    int animalId;
    try {
      if (isEdition) {
        final db = await DatabaseHelper.instance.database;
        await db.update('animals', data, where: 'id = ?', whereArgs: [animalToEdit!['id']]);
        animalId = animalToEdit!['id'];
      } else {
        animalId = await DatabaseHelper.instance.insertAnimal(data);
      }

      // Atualiza os controladores de lista para refletir a mudança
      if (Get.isRegistered<DetalhesRebanhoController>()) {
        Get.find<DetalhesRebanhoController>().carregarDados();
      }
      if (Get.isRegistered<RebanhoController>()) {
        Get.find<RebanhoController>().carregarRebanhos();
      }

      // Busca o animal completo do banco para garantir que temos todos os campos atualizados
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> updatedAnimal = await db.query('animals', where: 'id = ?', whereArgs: [animalId]);
      
      if (updatedAnimal.isNotEmpty) {
        if (isEdition) {
          if (Get.isRegistered<PerfilAnimalController>()) {
            Get.find<PerfilAnimalController>().carregarDadosDoBanco(animalId);
          }
          Get.back();
        } else {
          Get.back();
          Get.toNamed('/perfil-animal', arguments: Map<String, dynamic>.from(updatedAnimal.first));
        }
      } else {
        Get.back();
      }

      AgroAlert.show(title: "Sucesso", message: isEdition ? "Animal atualizado!" : "Animal adicionado!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro ao Salvar", message: "Não foi possível salvar os dados: $e", isError: true);
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
