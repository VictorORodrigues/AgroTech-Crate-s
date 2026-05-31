import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';
import '../rebanho_controller.dart';

class CadastroRebanhoController extends GetxController {
  // Rebanho
  final nomeRebanhoController = TextEditingController();
  final localizacaoController = TextEditingController();
  var categoriaSelecionada = "Bovino".obs; 
  var manejoSelecionado = "Extensivo".obs; // Extensivo, Semiextensivo, Intensivo
  
  // Erros Rebanho
  var nomeRebanhoError = Rxn<String>();
  var categoriaError = Rxn<String>();

  final List<String> categorias = ["Bovino", "Ovino", "Caprino"];
  final List<String> manejos = ["Extensivo", "Semiextensivo", "Intensivo"];

  void setCategoria(String value) {
    categoriaSelecionada.value = value;
    categoriaError.value = null;
  }

  void setManejo(String value) {
    manejoSelecionado.value = value;
  }

  bool _validarRebanho() {
    bool isValid = true;
    if (nomeRebanhoController.text.trim().isEmpty) {
      nomeRebanhoError.value = "O nome do rebanho é obrigatório";
      isValid = false;
    } else {
      nomeRebanhoError.value = null;
    }

    if (categoriaSelecionada.value.isEmpty) {
      categoriaError.value = "A categoria é obrigatória";
      isValid = false;
    } else {
      categoriaError.value = null;
    }
    return isValid;
  }

  Future<void> salvarRebanhoCompleto() async {
    if (!_validarRebanho()) return;

    try {
      // Verifica duplicidade no banco
      if (await DatabaseHelper.instance.herdNameExists(nomeRebanhoController.text.trim())) {
        nomeRebanhoError.value = "Já existe um rebanho com este nome";
        return;
      }

      await DatabaseHelper.instance.insertHerd(
        nomeRebanhoController.text.trim(),
        categoriaSelecionada.value,
        management: manejoSelecionado.value,
        location: localizacaoController.text.trim(),
      );

      if (Get.isRegistered<RebanhoController>()) {
        Get.find<RebanhoController>().carregarRebanhos();
      }

      Get.back();
      AgroAlert.show(title: "Sucesso", message: "Rebanho cadastrado com sucesso!", isSuccess: true);
    } catch (e) {
      AgroAlert.show(title: "Erro", message: "Falha ao salvar rebanho: $e", isError: true);
    }
  }

  @override
  void onClose() {
    nomeRebanhoController.dispose();
    localizacaoController.dispose();
    super.onClose();
  }
}
