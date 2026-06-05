import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/tecnico_config_service.dart';

class BiologicConfigController extends GetxController {
  final config = TecnicoConfigService.instance;

  // Bovinos
  late TextEditingController bovToqueCtrl;
  late TextEditingController bovCioCtrl;
  late TextEditingController bovSecagemCtrl;
  late TextEditingController bovPartoCtrl;
  late TextEditingController bovPveCtrl;

  // Ovinos/Caprinos
  late TextEditingController oviToqueCtrl;
  late TextEditingController oviCioCtrl;
  late TextEditingController oviSecagemCtrl;
  late TextEditingController oviPartoCtrl;
  late TextEditingController oviPveCtrl;

  @override
  void onInit() {
    super.onInit();
    bovToqueCtrl = TextEditingController(text: config.getBovToque().toString());
    bovCioCtrl = TextEditingController(text: config.getBovCio().toString());
    bovSecagemCtrl = TextEditingController(text: config.getBovSecagem().toString());
    bovPartoCtrl = TextEditingController(text: config.getBovParto().toString());
    bovPveCtrl = TextEditingController(text: config.getBovPve().toString());

    oviToqueCtrl = TextEditingController(text: config.getOviToque().toString());
    oviCioCtrl = TextEditingController(text: config.getOviCio().toString());
    oviSecagemCtrl = TextEditingController(text: config.getOviSecagem().toString());
    oviPartoCtrl = TextEditingController(text: config.getOviParto().toString());
    oviPveCtrl = TextEditingController(text: config.getOviPve().toString());
  }

  void save() {
    config.setConfig(TecnicoConfigService.bovToque, int.tryParse(bovToqueCtrl.text) ?? 30);
    config.setConfig(TecnicoConfigService.bovCio, int.tryParse(bovCioCtrl.text) ?? 21);
    config.setConfig(TecnicoConfigService.bovSecagem, int.tryParse(bovSecagemCtrl.text) ?? 60);
    config.setConfig(TecnicoConfigService.bovParto, int.tryParse(bovPartoCtrl.text) ?? 15);
    config.setConfig(TecnicoConfigService.bovPve, int.tryParse(bovPveCtrl.text) ?? 45);

    config.setConfig(TecnicoConfigService.oviToque, int.tryParse(oviToqueCtrl.text) ?? 45);
    config.setConfig(TecnicoConfigService.oviCio, int.tryParse(oviCioCtrl.text) ?? 21);
    config.setConfig(TecnicoConfigService.oviSecagem, int.tryParse(oviSecagemCtrl.text) ?? 30);
    config.setConfig(TecnicoConfigService.oviParto, int.tryParse(oviPartoCtrl.text) ?? 15);
    config.setConfig(TecnicoConfigService.oviPve, int.tryParse(oviPveCtrl.text) ?? 50);

    Get.back();
    Get.snackbar("Sucesso", "Prazos biológicos atualizados!", backgroundColor: Colors.green, colorText: Colors.white);
  }
}

class BiologicConfigView extends StatelessWidget {
  final controller = Get.put(BiologicConfigController());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: textColor),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          "Prazos Biológicos (IA)",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCategorySection("BOVINOS", [
              _buildInput("Confirmação Toque (dias)", controller.bovToqueCtrl),
              _buildInput("Alerta Retorno ao Cio (dias)", controller.bovCioCtrl),
              _buildInput("Secagem Pré-Parto (dias)", controller.bovSecagemCtrl),
              _buildInput("Isolamento Maternidade (dias)", controller.bovPartoCtrl),
              _buildInput("Período Espera (PVE) (dias)", controller.bovPveCtrl),
            ]),
            const SizedBox(height: 24),
            _buildCategorySection("OVINOS / CAPRINOS", [
              _buildInput("Confirmação Toque (dias)", controller.oviToqueCtrl),
              _buildInput("Alerta Retorno ao Cio (dias)", controller.oviCioCtrl),
              _buildInput("Secagem Pré-Parto (dias)", controller.oviSecagemCtrl),
              _buildInput("Isolamento Maternidade (dias)", controller.oviPartoCtrl),
              _buildInput("Período Espera (PVE) (dias)", controller.oviPveCtrl),
            ]),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                child: const Text("SALVAR CONFIGURAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.2)),
        const Divider(),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
