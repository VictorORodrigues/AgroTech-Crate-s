import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'onboarding_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OnboardingView extends StatelessWidget {
  final OnboardingController controller = Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo e Nome do App
            Image.asset(
              'assets/images/logo_fundo_transparente.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.green[500], shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AgroGen Crateús',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Barra de Progresso
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    width: (MediaQuery.of(context).size.width - 48) *
                        ((controller.currentPage.value + 1) / 3),
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 32),
            // PageView para os passos
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(),
                  _Step2(),
                  _Step3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final OnboardingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final atuacao_ordenada = ["Fazendeiro", "Veterinário", "Técnico"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seus Dados pessoais', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Passo 1 de 3: Configure sua identidade para acesso seguro.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 32),
            _buildTextField(
              controller: controller.nomeController,
              hint: 'Nome completo',
              errorText: controller.nomeError,
            ),
            const SizedBox(height: 16),
            Obx(() => TextField(
              controller: controller.cpfController,
              inputFormatters: [controller.cpfMask],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'CPF',
                errorText: controller.cpfError.value,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            )),
            const SizedBox(height: 16),

            Obx(() => DropdownButtonFormField<String>(
              value: controller.perfilAtuacao.value.isEmpty ? null : controller.perfilAtuacao.value,
              hint: Text('Perfil de atuação', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              items: atuacao_ordenada.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) => controller.perfilAtuacao.value = val ?? "",
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                errorText: controller.perfilError.value,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            )),
            const SizedBox(height: 28),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilOption(String option) {
    return InkWell(
      onTap: () {
        controller.perfilAtuacao.value = option;
        controller.isPerfilPickerOpen.value = false;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          option,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final OnboardingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sua Propriedade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Passo 2 de 3: Conte-nos sobre a localização e estrutura da fazenda',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 32),
            _buildTextField(
              controller: controller.nomePropriedadeController,
              hint: 'Nome da propriedade',
              errorText: controller.nomePropriedadeError,
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.localidade.value.isEmpty ? null : controller.localidade.value,
              hint: Text('Localidade', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              items: [
                "Assis", "Crateús (distrito-sede)", "Curral Velho", "Ibiapaba",
                "Irapuã", "Lagoa das Pedras", "Montenebo", "Oiticica",
                "Poti", "Realejo", "Santana", "Santo Antônio", "Tucuns"
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) => controller.localidade.value = val ?? "",
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                errorText: controller.localidadeError.value,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            )),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _buildBackButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildNextButton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalidadeOption(String option) {
    return InkWell(
      onTap: () {
        controller.localidade.value = option;
        controller.isLocalidadePickerOpen.value = false;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          option,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  final OnboardingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seu Rebanho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Passo 3 de 3: Selecione as espécies que deseja gerenciar.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            const Text('Seleção de espécies', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSpeciesCard('Bovinos', FontAwesomeIcons.cow),
                _buildSpeciesCard('Ovinos', Icons.pets), // Fallback para garantir compilação
                _buildSpeciesCard('Caprinos', Icons.agriculture), // Fallback para garantir compilação
              ],
            ),
            const SizedBox(height: 24),
            const Text('Finalidade da Produção', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildFinalidadeCard('Leite', Icons.opacity)), // Ícone de gota para leite
                const SizedBox(width: 16),
                Expanded(child: _buildFinalidadeCard('Carne', Icons.restaurant)), // Ícone de talher para carne
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(child: _buildBackButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildNextButton(label: 'Concluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesCard(String label, dynamic icon) {
    return Obx(() {
      bool isSelected = controller.especiesSelecionadas.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleEspecie(label),
        child: Container(
          width: Get.width * 0.26,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              icon is IconData 
                ? Icon(icon, color: isSelected ? Colors.green[700] : Colors.grey[600], size: 30)
                : FaIcon(icon, color: isSelected ? Colors.green[700] : Colors.grey[600], size: 30),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.green[700] : Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFinalidadeCard(String label, IconData icon) {
    return Obx(() {
      bool isSelected = controller.finalidadeProducao.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleFinalidade(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green[700] : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.green[700] : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Helpers
Widget _buildTextField({required TextEditingController controller, required String hint, Rxn<String>? errorText}) {
  final decoration = InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  if (errorText == null) {
    return TextField(
      controller: controller,
      decoration: decoration,
    );
  }

  return Obx(() => TextField(
    controller: controller,
    decoration: decoration.copyWith(errorText: errorText.value),
  ));
}

Widget _buildNextButton({String label = 'Avançar'}) {
  final OnboardingController controller = Get.find();
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: controller.nextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _buildBackButton() {
  final OnboardingController controller = Get.find();
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton(
      onPressed: controller.previousStep,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Voltar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}
