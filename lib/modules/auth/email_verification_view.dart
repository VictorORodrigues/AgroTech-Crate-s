import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class EmailVerificationView extends StatelessWidget {
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone centralizado de carta em tom verde vivo
            Icon(
              Icons.mark_email_read_outlined,
              size: 100,
              color: Colors.green[500],
            ),
            SizedBox(height: 32),
            // Título
            Text(
              'Verifique seu e-mail',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            // Subtítulo
            Text(
              'Enviamos um link de confirmação para o seu e-mail. Por favor, verifique sua caixa de entrada e spam para validar sua conta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 48),
            // Botão preto sólido
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.verifyEmailStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Já verifiquei meu e-mail',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              )),
            ),
            Obx(() => controller.verificationError.value != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      controller.verificationError.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[800], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  )
                : SizedBox.shrink()),
            SizedBox(height: 16),
            // Botão para reenviar
            Obx(() => TextButton(
              onPressed: controller.isLoading.value ? null : controller.resendEmail,
              child: controller.isLoading.value && !controller.emailController.text.isEmpty // Simples check para não mostrar loading em ambos se não necessário
                  ? Container() // O botão principal já mostra loading
                  : Text(
                      'Reenviar e-mail',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                    ),
            )),
          ],
        ),
      ),
    );
  }
}
