import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_controller.dart';

class RegisterView extends StatelessWidget {
  final AuthController controller = Get.find<AuthController>();

  // TEXTOS DOS MODELOS - ARMAZENADOS LOCALMENTE PARA USO OFFLINE
  static const String TEXTO_TERMOS = """
Termos de Serviço - AgroTech Crateús
Bem-vindo ao AgroTech Crateús. Ao utilizar nossa plataforma de gerenciamento genético e reprodutivo de bovinos, ovinos e caprinos, você concorda com as seguintes condições:
1. Escopo do Serviço: O AgroTech é uma ferramenta de suporte técnico para otimização de inseminação artificial e controle de linhagens genéticas. As decisões de manejo e as aplicações de campo são de responsabilidade exclusiva do produtor ou técnico responsável.
2. Uso Offline: O aplicativo realiza o processamento e armazenamento local dos dados reprodutivos para garantir o funcionamento em áreas sem conectividade. É de responsabilidade do usuário manter o aplicativo atualizado para sincronização de dados quando houver rede disponível.
3. Propriedade Intelectual: Todo o design, algoritmos de recomendação locais e lógica de interface pertencem à equipe de desenvolvimento do AgroTech.
4. Modificações: Estes termos podem ser atualizados a qualquer momento para refletir melhorias no sistema ou mudanças na legislação agropecuária.
""";

  static const String TEXTO_PRIVACIDADE = """
Política de Privacidade - AgroTech Crateús
A sua privacidade e a segurança dos dados da sua propriedade são nossa prioridade. Esta política explica como lidamos com as suas informações:
1. Coleta de Dados: Coletamos os dados informados no seu cadastro inicial (Nome, CPF, Perfil) e os dados do seu rebanho (espécies, raças, linhagens e histórico reprodutivo).
2. Armazenamento Offline-First: Em conformidade com a LGPD (Lei Geral de Proteção de Dados), todos os dados de manejo do seu rebanho e localização da propriedade são armazenados de forma criptografada localmente no banco de dados do seu dispositivo.
3. Uso das Informações: Os dados coletados servem exclusivamente para que os algoritmos locais calculem os índices de eficiência reprodutiva e gerem os relatórios exigidos pelo edital. Nós não vendemos e não compartilhamos os dados da sua fazenda com terceiros.
4. Segurança: Utilizamos práticas recomendadas de criptografia mobile para impedir acessos não autorizados ao banco de dados local do seu smartphone.
""";

  void _showBottomSheet(String title, String content) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.8, // Garante que o modal não cubra a tela toda
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                // Logo com fundo transparente do topo
                Image.asset(
                  'assets/images/logo_fundo_transparente.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green[500],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 50),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'AgroTech Crateús',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Criar uma conta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Insira seu e-mail e senha para se cadastrar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                // Campo de E-mail
                Obx(() => TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    errorText: controller.emailError.value,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                )),
                SizedBox(height: 16),
                // Campo de Senha
                Obx(() => TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    errorText: controller.passwordError.value,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => controller.isPasswordVisible.toggle(),
                    ),
                  ),
                )),
                SizedBox(height: 24),
                // Botão Continuar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('ou', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
                  ],
                ),
                SizedBox(height: 24),
                _SocialButton(
                  imageAsset: 'assets/images/google_logo.png',
                  label: 'Continuar com o Google',
                  onPressed: () => controller.signInWithGoogle(),
                ),
                SizedBox(height: 12),
                _SocialButton(
                  icon: FontAwesomeIcons.apple,
                  label: 'Continuar com a Apple',
                  onPressed: () {},
                  iconColor: Colors.black,
                ),
                SizedBox(height: 24),
                // Link para Login
                GestureDetector(
                  key: const Key('btn_ir_login'),
                  onTap: () => Get.back(),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(text: 'Já possui uma conta? '),
                        TextSpan(
                          text: 'Entrar',
                          style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Rodapé
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.5),
                      children: [
                        TextSpan(text: 'Ao clicar em continuar, você concorda com os nossos '),
                        TextSpan(
                          text: 'Termos de Serviço',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showBottomSheet('Termos de Serviço', TEXTO_TERMOS),
                        ),
                        TextSpan(text: ' e com a '),
                        TextSpan(
                          text: 'Política de Privacidade',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showBottomSheet('Política de Privacidade', TEXTO_PRIVACIDADE),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final dynamic icon;
  final String? imageAsset;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _SocialButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[200]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.grey[50],
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, color: Colors.blue, size: 30),
              )
            else
              FaIcon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
