import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import '../../../database/database_helper.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../utils/agro_alerts.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final _storage = GetStorage();
  
  // Controladores para ler o que o utilizador digita
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isResetEmailSent = false.obs; // Nova variável de estado

  // Variáveis para mensagens de erro nos campos
  var emailError = Rxn<String>();
  var passwordError = Rxn<String>();
  var verificationError = Rxn<String>(); // Nova variável para status de verificação na tela

  // Validação de E-mail
  bool _validateEmail(String email) {
    if (email.isEmpty) {
      emailError.value = 'O e-mail não pode estar vazio.';
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emailError.value = 'Digite um formato de e-mail válido.';
      return false;
    }
    emailError.value = null;
    return true;
  }

  // Validação de Senha
  bool _validatePassword(String password) {
    if (password.isEmpty) {
      passwordError.value = 'A senha não pode estar vazia.';
      return false;
    }
    if (password.length < 6) {
      passwordError.value = 'A senha deve ter pelo menos 6 caracteres.';
      return false;
    }
    passwordError.value = null;
    return true;
  }

  // Função de Registro (Atualizada para fluxo Firebase + Verificação)
  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    
    // Limpa erros anteriores
    emailError.value = null;
    passwordError.value = null;

    bool isEmailValid = _validateEmail(email);
    bool isPasswordValid = _validatePassword(password);

    if (!isEmailValid || !isPasswordValid) return;

    try {
      isLoading.value = true;
      
      // 1. Registro no Firebase (Aqui ele já dispara o e-mail de verificação)
      await _authService.signUp(email, password);
      
      // 2. Sincronização com DB Local (Lógica Anti-Crash)
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      
      if (existingUser == null) {
        // Se não existir localmente, registra para uso offline
        await DatabaseHelper.instance.registerUser(email, password); 
      }

      // 3. Navega para tela de verificação
      Get.toNamed('/email-verification');
      
    } catch (e) {
      // Se o erro vier do Firebase (ex: e-mail já existe), mostramos no campo ou snackbar
      String errorMsg = e.toString();
      if (errorMsg.contains('e-mail já está cadastrado')) {
        emailError.value = 'Este e-mail já está em uso por outro produtor.';
      } else if (errorMsg.contains('DatabaseException')) {
        AgroAlert.show(
          title: 'Erro no Banco de Dados', 
          message: 'Houve um problema ao salvar seus dados offline. Por favor, desinstale e reinstale o app para limpar o armazenamento.', 
          isError: true,
        );
      } else {
        AgroAlert.show(
          title: 'Falha no Cadastro', 
          message: 'Não conseguimos completar seu registro agora. Verifique sua conexão e tente novamente.',
          isError: true,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Verifica se o e-mail foi validado
  Future<void> verifyEmailStatus() async {
    try {
      isLoading.value = true;
      verificationError.value = null; // Limpa erro anterior
      
      bool isVerified = await _authService.checkEmailVerified();
      
      if (isVerified) {
        _storage.write('isLoggedIn', true);
        Get.offAllNamed('/onboarding'); // Direciona para o fluxo de perfil
      } else {
        verificationError.value = 'Aguardando Verificação: Você ainda não clicou no link enviado para o seu e-mail. Verifique sua caixa de entrada ou spam.';
      }
    } catch (e) {
      verificationError.value = 'Erro na Verificação: Não conseguimos atualizar o status agora. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      
      // 1. Inicia o fluxo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Usuário cancelou

      // 2. Obtém os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Cria uma credencial para o Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Autentica no Firebase com a credencial
      await _authService.signInWithGoogle(credential);

      // 5. Sincronização Imediata (Recuperar dados e status de onboarding ao logar)
      await SyncService.instance.syncCloudToLocal();

      // 6. Sincronização com DB Local (Lógica Anti-Crash)
      final existingUser = await DatabaseHelper.instance.getUserByEmail(googleUser.email);
      
      if (existingUser == null) {
        await DatabaseHelper.instance.registerUser(googleUser.email, "google_auth");
      }
      
      _storage.write('isLoggedIn', true);
      
      // RECARREGA O STATUS DE ONBOARDING QUE PODE TER SIDO BAIXADO DA NUVEM
      bool onboardingCompleted = _storage.read('onboardingCompleted') ?? false;
      if (onboardingCompleted) {
        Get.offAllNamed('/navigation');
      } else {
        Get.offAllNamed('/onboarding');
      }
      
    } catch (error) {
      print("ERRO GOOGLE DETALHADO: $error");
      Get.snackbar(
        'Erro no Google', 
        'Detalhes: $error', 
        snackPosition: SnackPosition.TOP, 
        backgroundColor: Colors.red[800], 
        colorText: Colors.white,
        icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 40),
        duration: const Duration(seconds: 8),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Função de Login (Atualizada para Firebase)
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Limpa erros anteriores
    emailError.value = null;
    passwordError.value = null;

    bool isEmailValid = _validateEmail(email);
    bool isPasswordValid = _validatePassword(password);

    if (!isEmailValid || !isPasswordValid) return;

    try {
      isLoading.value = true;
      
      // 1. Login no Firebase
      UserCredential userCredential = await _authService.signIn(email, password);
      
      // 2. Verifica se o e-mail está verificado
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        Get.toNamed('/email-verification');
        return;
      }

      // 3. Sincroniza com DB Local e Nuvem
      await SyncService.instance.syncCloudToLocal();
      await DatabaseHelper.instance.loginUser(email, password);
      
      _storage.write('isLoggedIn', true);
      
      // Verifica se o download da nuvem confirmou o onboarding
      bool onboardingCompleted = _storage.read('onboardingCompleted') ?? false;
      if (onboardingCompleted) {
        Get.offAllNamed('/navigation');
      } else {
        Get.offAllNamed('/onboarding');
      }
      
      emailController.clear();
      
    } catch (e) {
      String errorMsg = e.toString();
      // Erros de autenticação geralmente invalidam ambos ou o e-mail
      if (errorMsg.contains('incorretos')) {
        emailError.value = 'E-mail ou senha inválidos.';
        passwordError.value = 'E-mail ou senha inválidos.';
      } else {
        Get.snackbar(
          'Falha no Acesso', 
          errorMsg, 
          backgroundColor: Colors.red[800], 
          colorText: Colors.white, 
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Reenviar e-mail de verificação
  Future<void> resendEmail() async {
    try {
      isLoading.value = true;
      await _authService.sendVerificationEmail();
      Get.snackbar(
        'E-mail Enviado', 
        'Um novo link de confirmação foi para sua caixa de entrada.', 
        backgroundColor: Colors.green[700], 
        colorText: Colors.white,
        icon: const Icon(Icons.send_outlined, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Aguarde um pouco', 
        'Muitas tentativas. Por favor, aguarde alguns minutos para reenviar.', 
        backgroundColor: Colors.orange[800], 
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Redefinição de Senha
  Future<void> forgotPassword({bool fromNewScreen = false}) async {
    final email = emailController.text.trim();
    
    if (!_validateEmail(email)) {
      if (!fromNewScreen) {
        // Se clicar no link da login_view e o email estiver vazio, apenas navegamos
        isResetEmailSent.value = false; // Garante que a tela comece no modo formulário
        Get.toNamed('/forgot-password');
        return;
      }
      // Se já estiver na tela de recuperação e o email for inválido, o _validateEmail já mostra o erro no campo
      return;
    }

    try {
      isLoading.value = true;
      await _authService.sendPasswordResetEmail(email);
      
      // Em vez de snackbar, mudamos o estado para exibir na tela
      isResetEmailSent.value = true;
      
    } catch (e) {
      Get.snackbar(
        'Erro', 
        e.toString(), 
        backgroundColor: Colors.red[800], 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Realiza o logout
  Future<void> logout() async {
    try {
      await _authService.signOut();
      await _googleSignIn.signOut();
      _storage.write('isLoggedIn', false);
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao sair: $e');
    }
  }
}
