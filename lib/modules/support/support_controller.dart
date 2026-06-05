import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportController extends GetxController {
  final String email = "suporte@agrotechcrateus.com.br";
  final String whatsapp = "5588998765432"; // Exemplo com DDI e DDD

  Future<void> openWhatsApp() async {
    final String message = "Olá! Gostaria de suporte com o AgroTech Crateús.";
    final Uri url = Uri.parse("https://wa.me/$whatsapp?text=${Uri.encodeComponent(message)}");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Erro", "Não foi possível abrir o WhatsApp");
    }
  }

  Future<void> openEmail() async {
    final Uri url = Uri.parse("mailto:$email?subject=Suporte%20AgroTech%20Crateús");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Erro", "Não foi possível abrir o aplicativo de e-mail");
    }
  }
}
