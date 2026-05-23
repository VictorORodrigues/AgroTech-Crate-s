import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/agro_alerts.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;

  var userName = "".obs;
  var farmName = "".obs;
  var location = "".obs;
  var email = "".obs;
  var photoUrl = "".obs;

  var isEditing = false.obs;
  
  // Controllers para edição
  late TextEditingController nameCtrl;
  late TextEditingController farmCtrl;
  late TextEditingController locationCtrl;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    
    nameCtrl = TextEditingController(text: userName.value);
    farmCtrl = TextEditingController(text: farmName.value);
    locationCtrl = TextEditingController(text: location.value);
  }

  void _loadUserData() {
    final User? user = _auth.currentUser;
    userName.value = _storage.read('userName') ?? user?.displayName ?? "Produtor";
    farmName.value = _storage.read('farmName') ?? "Minha Fazenda";
    location.value = _storage.read('location') ?? "Crateús, CE";
    email.value = user?.email ?? "Não informado";
    photoUrl.value = user?.photoURL ?? "";
  }

  void toggleEdit() {
    if (isEditing.value) {
      // Se estava editando e cancelou, restaura valores
      nameCtrl.text = userName.value;
      farmCtrl.text = farmName.value;
      locationCtrl.text = location.value;
    }
    isEditing.value = !isEditing.value;
  }

  Future<void> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty || farmCtrl.text.trim().isEmpty) {
      AgroAlert.show(title: "Campos obrigatórios", message: "Nome e Fazenda não podem ficar vazios.", isError: true);
      return;
    }

    try {
      userName.value = nameCtrl.text.trim();
      farmName.value = farmCtrl.text.trim();
      location.value = locationCtrl.text.trim();

      _storage.write('userName', userName.value);
      _storage.write('farmName', farmName.value);
      _storage.write('location', location.value);

      // Opcional: Atualizar no Firebase DisplayName
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(userName.value);
      }

      isEditing.value = false;
      AgroAlert.show(title: "Sucesso", message: "Perfil atualizado com sucesso!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao salvar perfil: $e", isError: true);
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

  Future<void> _deleteAccount() async {
    try {
      // 1. Limpar Storage
      await _storage.erase();
      
      // 2. Tentar excluir do Firebase (Pode exigir re-autenticação recente)
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }

      Get.offAllNamed('/login');
      AgroAlert.show(title: "Conta Excluída", message: "Sentiremos sua falta, produtor. Seus dados foram removidos.");
    } catch (e) {
      // Se falhar por segurança (re-autenticação), apenas deslogamos e limpamos local
      await _auth.signOut();
      Get.offAllNamed('/login');
      AgroAlert.show(title: "Aviso", message: "Para sua segurança, a exclusão total exige login recente. Sua sessão foi encerrada e dados locais limpos.");
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    farmCtrl.dispose();
    locationCtrl.dispose();
    super.onClose();
  }
}
