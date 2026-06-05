import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../services/sync_service.dart';

class OnboardingController extends GetxController {
  final _storage = GetStorage();
  final pageController = PageController();
  var currentPage = 0.obs;
  var isLoading = false.obs;

  // Passo 1: Dados Pessoais
  final nomeController = TextEditingController();
  final celularController = TextEditingController();
  var perfilAtuacao = "".obs; // Veterinário, Técnico ou Pecuarista
  var aceitouTermos = false.obs; // Aceite dos termos de dados pessoais
  var isPerfilPickerOpen = false.obs; 
  var nomeError = Rxn<String>();
  var celularError = Rxn<String>();
  var perfilError = Rxn<String>();
  var termosError = Rxn<String>();

  final celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Passo 2: Sua Propriedade
  final nomePropriedadeController = TextEditingController();
  final outroDistritoController = TextEditingController();
  var localidade = "".obs; 
  var isOutroDistrito = false.obs;
  var nomePropriedadeError = Rxn<String>();
  var localidadeError = Rxn<String>();
  var outroDistritoError = Rxn<String>();

  // Passo 3: Seu Rebanho
  var especiesSelecionadas = <String>{}.obs; // Bovinos, Ovinos, Caprinos
  var finalidadeProducao = <String>{}.obs; // Leite, Carne

  void setLocalidade(String val) {
    localidade.value = val;
    isOutroDistrito.value = (val == "Outro...");
    if (!isOutroDistrito.value) {
      outroDistritoController.clear();
      outroDistritoError.value = null;
    }
  }

  void nextStep() {
    if (currentPage.value == 0) {
      if (_validateStep1()) {
        currentPage.value++;
        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
    } else if (currentPage.value == 1) {
      if (_validateStep2()) {
        currentPage.value++;
        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
    } else {
      finishOnboarding();
    }
  }

  void previousStep() {
    if (currentPage.value > 0) {
      currentPage.value--;
      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      // Se estiver no passo 1, volta para a tela de login/cadastro
      Get.offAllNamed('/login');
    }
  }

  bool _validateStep1() {
    bool isValid = true;
    String fullName = nomeController.text.trim();
    if (fullName.isEmpty) {
      nomeError.value = "Nome completo é obrigatório";
      isValid = false;
    } else if (fullName.split(' ').length < 2) {
      nomeError.value = "Digite seu nome completo (nome e sobrenome)";
      isValid = false;
    } else {
      nomeError.value = null;
    }

    String phone = celularMask.getUnmaskedText();
    if (phone.length < 10) {
      celularError.value = "Número de celular inválido";
      isValid = false;
    } else {
      celularError.value = null;
    }

    if (perfilAtuacao.value.isEmpty) {
      perfilError.value = "Selecione um perfil";
      isValid = false;
    } else {
      perfilError.value = null;
    }

    if (!aceitouTermos.value) {
      termosError.value = "Você precisa aceitar os termos para continuar";
      isValid = false;
    } else {
      termosError.value = null;
    }

    return isValid;
  }

  bool _validateStep2() {
    bool isValid = true;
    if (nomePropriedadeController.text.trim().isEmpty) {
      nomePropriedadeError.value = "Nome da propriedade é obrigatório";
      isValid = false;
    } else {
      nomePropriedadeError.value = null;
    }

    if (localidade.value.isEmpty) {
      localidadeError.value = "Selecione a localidade";
      isValid = false;
    } else {
      localidadeError.value = null;
    }

    if (isOutroDistrito.value && outroDistritoController.text.trim().isEmpty) {
      outroDistritoError.value = "Informe o nome do distrito";
      isValid = false;
    } else {
      outroDistritoError.value = null;
    }

    return isValid;
  }

  void toggleEspecie(String especie) {
    if (especiesSelecionadas.contains(especie)) {
      especiesSelecionadas.remove(especie);
    } else {
      especiesSelecionadas.add(especie);
    }
  }

  void toggleFinalidade(String finalidade) {
    if (finalidadeProducao.contains(finalidade)) {
      finalidadeProducao.remove(finalidade);
    } else {
      finalidadeProducao.add(finalidade);
    }
  }

  Future<void> finishOnboarding() async {
    isLoading.value = true;
    try {
      String localFinal = isOutroDistrito.value 
          ? outroDistritoController.text.trim() 
          : localidade.value;

      // Salva os dados para exibição na Home
      _storage.write('userName', nomeController.text.trim());
      _storage.write('userPhone', celularController.text.trim());
      _storage.write('farmName', nomePropriedadeController.text.trim());
      _storage.write('location', localFinal);

      // Salva o perfil do usuário na nuvem também
      await SyncService.instance.saveUserProfileToCloud(
        userName: nomeController.text.trim(),
        userPhone: celularController.text.trim(),
        farmName: nomePropriedadeController.text.trim(),
        location: localFinal,
      );

      // Tenta baixar dados existentes da nuvem se for uma reinstalação
      await SyncService.instance.syncCloudToLocal();

      // Salva que o onboarding foi concluído
      _storage.write('onboardingCompleted', true);
      Get.offAllNamed('/navigation');
    } catch (e) {
      print("Erro na finalização/sincronia: $e");
      Get.offAllNamed('/navigation');
    } finally {
      isLoading.value = false;
    }
  }
}
