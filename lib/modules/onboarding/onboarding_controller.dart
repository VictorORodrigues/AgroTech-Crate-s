import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class OnboardingController extends GetxController {
  final _storage = GetStorage();
  final pageController = PageController();
  var currentPage = 0.obs;

  // Passo 1: Dados Pessoais
  final nomeController = TextEditingController();
  final cpfController = TextEditingController();
  var perfilAtuacao = "".obs; // Veterinário, Técnico ou Pecuarista
  var aceitouTermos = false.obs; // Aceite dos termos de dados pessoais
  var isPerfilPickerOpen = false.obs; 
  var nomeError = Rxn<String>();
  var cpfError = Rxn<String>();
  var perfilError = Rxn<String>();
  var termosError = Rxn<String>();

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
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

  bool _isValidCPF(String cpf) {
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false; // Bloqueia 111.111.111-11, etc.

    List<int> digits = cpf.split('').map(int.parse).toList();
    
    // Primeiro dígito
    int sum = 0;
    for (int i = 0; i < 9; i++) sum += digits[i] * (10 - i);
    int res = (sum * 10) % 11;
    if (res == 10) res = 0;
    if (res != digits[9]) return false;

    // Segundo dígito
    sum = 0;
    for (int i = 0; i < 10; i++) sum += digits[i] * (11 - i);
    res = (sum * 10) % 11;
    if (res == 10) res = 0;
    if (res != digits[10]) return false;

    return true;
  }

  bool _validateStep1() {
    bool isValid = true;
    if (nomeController.text.trim().isEmpty) {
      nomeError.value = "Nome completo é obrigatório";
      isValid = false;
    } else {
      nomeError.value = null;
    }

    String cpf = cpfMask.getUnmaskedText();
    if (!_isValidCPF(cpf)) {
      cpfError.value = "CPF inválido. Verifique os números.";
      isValid = false;
    } else {
      cpfError.value = null;
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

  void finishOnboarding() {
    String localFinal = isOutroDistrito.value 
        ? outroDistritoController.text.trim() 
        : localidade.value;

    // Salva os dados para exibição na Home
    _storage.write('userName', nomeController.text.trim());
    _storage.write('farmName', nomePropriedadeController.text.trim());
    _storage.write('location', localFinal);

    // Salva que o onboarding foi concluído
    _storage.write('onboardingCompleted', true);
    Get.offAllNamed('/home');
  }
}
