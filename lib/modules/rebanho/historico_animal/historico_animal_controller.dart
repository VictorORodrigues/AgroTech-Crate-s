import 'package:get/get.dart';
import '../../../database/database_helper.dart';

class HistoricoAnimalController extends GetxController {
  final Map<String, dynamic> animal = Get.arguments;
  var eventos = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    try {
      isLoading.value = true;
      eventos.value = await DatabaseHelper.instance.getEventsByAnimal(animal['id']);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> adicionarEvento(String tipo, String descricao) async {
    await DatabaseHelper.instance.insertEvent(animal['id'], tipo, descricao);
    carregarHistorico();
  }
}
