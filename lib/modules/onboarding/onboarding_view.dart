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
              'AgroTech Crateús',
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
    final atuacoes = ["Veterinário", "Técnico", "Pecuarista"];
    
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
              controller: controller.celularController,
              inputFormatters: [controller.celularMask],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Número de Celular (WhatsApp)',
                errorText: controller.celularError.value,
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
            const SizedBox(height: 24),
            
            const Text('Sua Atuação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => Column(
              children: atuacoes.map((atuacao) {
                final isSelected = controller.perfilAtuacao.value == atuacao;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => controller.perfilAtuacao.value = atuacao,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.green[700] : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            atuacao,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.green[800] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
            Obx(() => controller.perfilError.value != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(controller.perfilError.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                )
              : const SizedBox.shrink()),
            
            const SizedBox(height: 24),
            
            // Termos de Uso e Dados Pessoais
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Checkbox(
                    value: controller.aceitouTermos.value,
                    onChanged: (val) => controller.aceitouTermos.value = val ?? false,
                    activeColor: Colors.green[700],
                  )),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacidade e Segurança de Dados',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ao prosseguir, você autoriza o AgroTech Crateús a processar seus dados para fins de gestão técnica. Garantimos a criptografia e sigilo total de suas informações pessoais e produtivas.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => controller.termosError.value != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(controller.termosError.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                )
              : const SizedBox.shrink()),

            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _buildBackButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildNextButton()),
              ],
            ),
            const SizedBox(height: 20),
          ],
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
              hint: Text('Localidade / Distrito', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              items: [
                "Assis", "Crateús (distrito-sede)", "Curral Velho", "Ibiapaba",
                "Irapuã", "Lagoa das Pedras", "Montenebo", "Oiticica",
                "Poti", "Realejo", "Santana", "Santo Antônio", "Tucuns", "Outro..."
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) => controller.setLocalidade(val ?? ""),
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
            Obx(() => controller.isOutroDistrito.value 
              ? Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildTextField(
                    controller: controller.outroDistritoController,
                    hint: 'Digite o nome do seu Distrito',
                    errorText: controller.outroDistritoError,
                  ),
                )
              : const SizedBox.shrink()),
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
