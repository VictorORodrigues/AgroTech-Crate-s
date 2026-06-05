import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../utils/agro_alerts.dart';
import '../../services/sync_service.dart';
import '../home/home_controller.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Dados Pessoais
  var userName = "".obs;
  var email = "".obs;
  var phone = "".obs;
  var photoUrl = "".obs;
  var localPhotoPath = "".obs;

  // Dados da Propriedade
  var farmName = "".obs;
  var carCode = "".obs;
  var location = "".obs;
  var selectedDistrict = "".obs;
  var isOtherDistrict = false.obs;

  final List<String> districts = [
    "Assis", "Crateús (distrito-sede)", "Curral Velho", "Ibiapaba",
    "Irapuã", "Lagoa das Pedras", "Montenebo", "Oiticica",
    "Poti", "Realejo", "Santana", "Santo Antônio", "Tucuns", "Outro..."
  ];

  var isEditing = false.obs;
  var isGoogleAccount = false.obs;
  var isSaving = false.obs;
  
  // Controllers e Máscaras
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController farmCtrl;
  late TextEditingController carCodeCtrl;
  late TextEditingController locationCtrl;

  final phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _initControllers();
  }

  void _loadUserData() {
    final User? user = _auth.currentUser;
    isGoogleAccount.value = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    userName.value = _storage.read('userName') ?? user?.displayName ?? "Produtor";
    email.value = _storage.read('userEmail') ?? user?.email ?? "";
    phone.value = _storage.read('userPhone') ?? "";
    photoUrl.value = user?.photoURL ?? "";
    localPhotoPath.value = _storage.read('userPhotoPath') ?? "";

    farmName.value = _storage.read('farmName') ?? "Minha Fazenda";
    carCode.value = _storage.read('carCode') ?? "";
    location.value = _storage.read('location') ?? "Crateús, CE";

    if (districts.contains(location.value)) {
      selectedDistrict.value = location.value;
      isOtherDistrict.value = false;
    } else {
      selectedDistrict.value = "Outro...";
      isOtherDistrict.value = true;
    }
  }

  void _initControllers() {
    nameCtrl = TextEditingController(text: userName.value);
    emailCtrl = TextEditingController(text: email.value);
    phoneCtrl = TextEditingController(text: phone.value);
    farmCtrl = TextEditingController(text: farmName.value);
    carCodeCtrl = TextEditingController(text: carCode.value);
    locationCtrl = TextEditingController(text: isOtherDistrict.value ? location.value : "");
  }

  void resetFields() {
    _loadUserData();
    _initControllers();
  }

  void setDistrict(String val) {
    selectedDistrict.value = val;
    isOtherDistrict.value = (val == "Outro...");
    if (!isOtherDistrict.value) {
      locationCtrl.clear();
    }
  }

  void toggleEdit() {
    if (isEditing.value) {
      // Se estava editando e cancelou (clicou no X ou voltou), restaura valores originais
      _initControllers();
      // Restaura a foto original se mudou mas não salvou
      localPhotoPath.value = _storage.read('userPhotoPath') ?? "";
    }
    isEditing.value = !isEditing.value;
  }

  bool hasChanges() {
    if (!isEditing.value) return false;
    
    String finalLocation = isOtherDistrict.value ? locationCtrl.text.trim() : selectedDistrict.value;
    String savedPhotoPath = _storage.read('userPhotoPath') ?? "";

    return nameCtrl.text.trim() != userName.value ||
           emailCtrl.text.trim() != email.value ||
           phoneCtrl.text != phone.value ||
           farmCtrl.text.trim() != farmName.value ||
           carCodeCtrl.text.trim() != carCode.value ||
           finalLocation != location.value ||
           localPhotoPath.value != savedPhotoPath;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
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
          // Apenas atualiza a UI, não salva no storage ainda (será salvo no saveProfile)
          localPhotoPath.value = croppedFile.path;
        }
      }
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao selecionar imagem.", isError: true);
    }
  }

  Future<void> removePhoto() async {
    localPhotoPath.value = "";
    // Se quiser que a remoção seja instantânea mesmo sem clicar em salvar, descomente abaixo:
    // _storage.write('userPhotoPath', "");
  }

  Future<void> saveProfile() async {
    String fullName = nameCtrl.text.trim();
    String farm = farmCtrl.text.trim();

    if (fullName.isEmpty || farm.isEmpty) {
      AgroAlert.show(title: "Campos obrigatórios", message: "Nome e Fazenda não podem ficar vazios.", isError: true);
      return;
    }

    try {
      isSaving.value = true;
      String finalLocation = isOtherDistrict.value ? locationCtrl.text.trim() : selectedDistrict.value;
      if (finalLocation.isEmpty) finalLocation = "Crateús, CE";

      // 1. Persistência Local Imediata (Offline First)
      _storage.write('userName', fullName);
      _storage.write('userEmail', emailCtrl.text.trim());
      _storage.write('userPhone', phoneCtrl.text);
      _storage.write('farmName', farm);
      _storage.write('carCode', carCodeCtrl.text.trim());
      _storage.write('location', finalLocation);
      _storage.write('userPhotoPath', localPhotoPath.value);

      // 2. Atualiza Variáveis Reativas do App
      userName.value = fullName;
      email.value = emailCtrl.text.trim();
      phone.value = phoneCtrl.text;
      farmName.value = farm;
      carCode.value = carCodeCtrl.text.trim();
      location.value = finalLocation;

      // 3. Atualiza Firebase em Background (Não trava a UI)
      SyncService.instance.saveUserProfileToCloud(
        userName: fullName,
        userPhone: phoneCtrl.text,
        farmName: farm,
        location: finalLocation,
        userPhotoPath: localPhotoPath.value,
      ).catchError((e) => print("Erro ao subir perfil: $e"));

      if (_auth.currentUser != null) {
        _auth.currentUser!.updateDisplayName(fullName);
      }

      // 4. Notifica Home
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadUserProfile();
      }

      isEditing.value = false;
      isSaving.value = false;
      
      // 5. Sucesso
      Get.back(); // Fecha a tela de edição
      AgroAlert.show(title: "Perfil Salvo", message: "Suas informações foram atualizadas com sucesso!", isSuccess: true);
      
    } catch (e) {
      isSaving.value = false;
      AgroAlert.show(title: "Erro ao Salvar", message: "Ocorreu um erro técnico: $e", isError: true);
    }
  }

  void confirmDeleteAccount() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Excluir Conta?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Esta ação é IRREVERSÍVEL. Todos os seus rebanhos, animais e dados de IA serão apagados permanentemente."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => _deleteAccount(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("EXCLUIR TUDO", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await _storage.erase();
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }
      Get.offAllNamed('/login');
    } catch (e) {
      await _auth.signOut();
      Get.offAllNamed('/login');
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    farmCtrl.dispose();
    carCodeCtrl.dispose();
    locationCtrl.dispose();
    super.onClose();
  }
}

