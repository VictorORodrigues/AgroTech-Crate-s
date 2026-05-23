import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para monitorar o estado da autenticação
  Stream<User?> get user => _auth.authStateChanges();

  // Registro com E-mail e Senha + Envio de Verificação
  Future<UserCredential> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Envia o e-mail de verificação logo após o registro
      await userCredential.user?.sendEmailVerification();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  // Reenviar e-mail de verificação
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else if (user == null) {
      throw 'Nenhum usuário logado.';
    } else {
      throw 'E-mail já verificado.';
    }
  }

  // Login com Firebase
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Checa se o e-mail do usuário logado já foi verificado
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Atualiza os dados do usuário do Firebase
      return user.emailVerified;
    }
    return false;
  }

  // Login com Google (Firebase)
  Future<UserCredential> signInWithGoogle(AuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Tratamento de erros amigável em Português
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Tente fazer login ou recupere sua senha.';
      case 'invalid-email':
        return 'O formato do e-mail digitado não é válido. Verifique se há erros de digitação.';
      case 'weak-password':
        return 'Sua senha deve ter pelo menos 6 caracteres para ser segura.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Verifique seus dados e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique seu Wi-Fi ou dados móveis.';
      case 'operation-not-allowed':
        return 'Este método de login não está habilitado no servidor.';
      default:
        return 'Ops! Ocorreu um erro inesperado: ${e.message}';
    }
  }
}
