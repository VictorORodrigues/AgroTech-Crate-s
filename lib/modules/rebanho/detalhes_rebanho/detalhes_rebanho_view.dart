import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'detalhes_rebanho_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../database/database_helper.dart';
import '../../../utils/agro_alerts.dart';

class DetalhesRebanhoView extends StatelessWidget {
  final DetalhesRebanhoController controller = Get.put(DetalhesRebanhoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Obx(() {
          final isSelecting = controller.selectedAnimals.isNotEmpty;
          return Text(
            isSelecting ? "${controller.selectedAnimals.length} selecionados" : (controller.rebanho['name'] ?? 'Detalhes'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          );
        }),
        leading: IconButton(
          icon: Obx(() => Icon(controller.selectedAnimals.isNotEmpty ? Icons.close : Icons.arrow_back, color: Colors.white)),
          onPressed: () {
            if (controller.selectedAnimals.isNotEmpty) {
              controller.clearAnimalSelection();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          Obx(() {
            final isSelecting = controller.selectedAnimals.isNotEmpty;
            if (controller.selectedTabIndex.value == 0 && !isSelecting) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: "Editar Rebanho",
                    onPressed: () => _showEditNomeDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: "Excluir Rebanho",
                    onPressed: () => _showConfirmDeleteHerdDialog(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final isSelecting = controller.selectedAnimals.isNotEmpty;
            if (isSelecting) {
              return Row(
                children: [
                  Checkbox(
                    value: controller.isAllAnimalsSelected,
                    onChanged: (val) => controller.toggleSelectAllAnimals(),
                    activeColor: Colors.white,
                    checkColor: Colors.red[800],
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.move_up_outlined, color: Colors.white),
                    tooltip: "Mover Selecionados",
                    onPressed: () => _showRelocateSelectionSelector(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _showDeleteAnimalsConfirmation(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Animais'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          _buildGeralTab(context),
          _buildAnimaisTab(context),
        ],
      ),
      floatingActionButton: Obx(() => (controller.selectedTabIndex.value == 1 && controller.selectedAnimals.isEmpty)
        ? FloatingActionButton(
            onPressed: () => _showAddAnimalPage(),
            backgroundColor: Colors.green[800],
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink()),
    );
  }

  Widget _buildGeralTab(BuildContext context) {
    return Obx(() {
      final String management = controller.rebanho['management_type'] ?? "Extensivo";
      final String category = controller.rebanho['category'] ?? "Bovino";
      final String location = controller.rebanho['location'] ?? "Não informada";

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoCard(
              title: "Informações do Rebanho",
              icon: Icons.info_outline,
              content: [
                _buildInfoRow("Categoria", category),
                _buildInfoRow("Tipo de Manejo", management),
                _buildInfoRow("Localização/Galpão", location),
                _buildInfoRow("Total de Animais", controller.rebanho['animal_count'].toString()),
                _buildInfoRow("Fêmeas ♀️", controller.totalFemeas.value.toString()),
                _buildInfoRow("Machos ♂️", controller.totalMachos.value.toString()),
                _buildInfoRow("ECC Médio do Lote", controller.avgEcc.value.toStringAsFixed(1), isHighlight: true),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: "Índices Reprodutivos (Fêmeas)",
              icon: Icons.favorite_border,
              content: [
                _buildInfoRow("Prenhes", "${controller.totalPrenhes.value} (${controller.taxaPrenhez.value})", isHighlight: true),
                _buildInfoRow("Aptas / Vazias", "${controller.femeasAptas.value} (${controller.taxaAptas.value})", isHighlight: true),
                _buildInfoRow("Em Lactação", "${controller.totalLactacao.value} (${controller.taxaLactacao.value})", isHighlight: true),
                _buildInfoRow("Inseminadas", "${controller.totalInseminada.value} (${controller.taxaInseminada.value})", isHighlight: true),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAnimaisTab(BuildContext context) {
    return Obx(() {
      final String category = controller.rebanho['category'] ?? "Bovino";
      
      dynamic animalIcon;
      if (category == 'Bovino') {
        animalIcon = FontAwesomeIcons.cow;
      } else if (category == 'Ovino') {
        animalIcon = Icons.pets;
      } else {
        animalIcon = Icons.agriculture;
      }

      final filteredList = controller.paginatedAnimais;
      final totalCount = controller.totalFilteredAnimalsCount;

      return Column(
        children: [
          // Barra de Pesquisa e Filtros de Sexo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: context.theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => controller.searchText.value = v,
                  decoration: InputDecoration(
                    hintText: "Buscar por ID, Apelido ou Raça...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: context.isDarkMode ? Colors.white10 : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.green[800]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtro de Sexo
                      ...["Todos", "Macho", "Fêmea"].map((f) {
                        bool isSelected = controller.selectedSexFilter.value == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            selected: isSelected,
                            onSelected: (val) {
                              controller.selectedSexFilter.value = f;
                              if (f == "Macho") controller.selectedStatusFilter.value = "Todos";
                            },
                            selectedColor: Colors.green[800],
                            backgroundColor: context.isDarkMode ? Colors.white10 : Colors.grey[200],
                            checkmarkColor: Colors.white,
                            shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green[800]! : Colors.transparent)),
                          ),
                        );
                      }),
                      
                      const SizedBox(width: 8),
                      const SizedBox(height: 24, child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey)),
                      const SizedBox(width: 16),

                      // Filtro de Status Reprodutivo
                      ...["Todos", "Prenhe", "Vazia / Apta", "Em Lactação", "Inseminada"].map((s) {
                        bool isSelected = controller.selectedStatusFilter.value == s;
                        bool isVisible = controller.selectedSexFilter.value != "Macho";
                        
                        if (!isVisible && s != "Todos") return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            selected: isSelected,
                            onSelected: (val) {
                              controller.selectedStatusFilter.value = s;
                              if (s != "Todos") controller.selectedSexFilter.value = "Fêmea";
                            },
                            selectedColor: Colors.purple[700],
                            backgroundColor: context.isDarkMode ? Colors.white10 : Colors.grey[200],
                            checkmarkColor: Colors.white,
                            shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.purple[700]! : Colors.transparent)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: controller.animais.isEmpty
                ? _buildEmptyAnimaisState(context, category)
                : (filteredList.isEmpty 
                    ? const Center(child: Text("Nenhum animal encontrado para esta busca."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final animal = filteredList[index];
                          final int animalId = animal['id'];
                          final isFemale = animal['sex'] == 'Fêmea';
                          
                          return Obx(() {
                            final isSelected = controller.selectedAnimals.contains(animalId);
                            final bool isSelecting = controller.selectedAnimals.isNotEmpty;

                            return GestureDetector(
                              onLongPress: () => controller.toggleAnimalSelection(animalId),
                              onTap: () {
                                if (isSelecting) {
                                  controller.toggleAnimalSelection(animalId);
                                } else {
                                  Get.toNamed('/perfil-animal', arguments: animal);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green[50] : context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected ? Colors.green[800]! : Colors.green[800]!.withOpacity(0.05),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Foto ou Ícone (Redondo)
                                    Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green[100] : Colors.green[50],
                                            shape: BoxShape.circle,
                                            image: animal['photo_path'] != null && animal['photo_path'].toString().isNotEmpty
                                                ? DecorationImage(image: FileImage(File(animal['photo_path'])), fit: BoxFit.cover)
                                                : DecorationImage(
                                                    image: AssetImage(
                                                      category == 'Bovino' ? 'assets/images/bovino_default.png' :
                                                      category == 'Ovino' ? 'assets/images/ovino_default.png' :
                                                      'assets/images/caprino_default.png'
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          bottom: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                            ),
                                            child: Icon(
                                              isFemale ? Icons.female : Icons.male,
                                              size: 16,
                                              color: isFemale ? Colors.pink[300] : Colors.blue[400],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "${animal['identifier']}",
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (isSelecting)
                                                Icon(
                                                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                                                  color: isSelected ? Colors.green[800] : Colors.grey[300],
                                                ),
                                            ],
                                          ),
                                          if (animal['name'] != null && animal['name'].toString().isNotEmpty)
                                            Text(
                                              animal['name'],
                                              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (animal['breed_name'] != null && animal['breed_name'].toString().isNotEmpty)
                                                ? animal['breed_name']
                                                : animal['breed'],
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (isFemale) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: () {
                                                  final status = animal['reproductive_status']?.toString() ?? "";
                                                  if (status == "Prenhe") return Colors.pink[50];
                                                  if (status == "Em Lactação") return Colors.blue[50];
                                                  if (status == "Inseminada") return Colors.green[50];
                                                  return isSelected ? Colors.white : Colors.grey[100];
                                                }(),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: () {
                                                    final status = animal['reproductive_status']?.toString() ?? "";
                                                    if (status == "Prenhe") return Colors.pink[200]!;
                                                    if (status == "Em Lactação") return Colors.blue[200]!;
                                                    if (status == "Inseminada") return Colors.green[200]!;
                                                    return Colors.transparent;
                                                  }(),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                animal['reproductive_status'] ?? "Vazia / Apta",
                                                style: TextStyle(
                                                  fontSize: 10, 
                                                  fontWeight: FontWeight.bold,
                                                  color: () {
                                                    final status = animal['reproductive_status']?.toString() ?? "";
                                                    if (status == "Prenhe") return Colors.pink[800];
                                                    if (status == "Em Lactação") return Colors.blue[800];
                                                    if (status == "Inseminada") return Colors.green[800];
                                                    return Colors.black54;
                                                  }(),
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            if (animal['aptitude'] != null && animal['aptitude'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: animal['aptitude'] == "Rústico" ? Colors.orange[50] : Colors.indigo[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: animal['aptitude'] == "Rústico" ? Colors.orange[200]! : Colors.indigo[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  animal['aptitude'],
                                                  style: TextStyle(
                                                    fontSize: 10, 
                                                    fontWeight: FontWeight.bold,
                                                    color: animal['aptitude'] == "Rústico" ? Colors.orange[800] : Colors.indigo[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!isSelecting) const Icon(Icons.chevron_right, color: Colors.black26),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      )),
          ),
          // CONTROLES DE PAGINAÇÃO
          if (totalCount > controller.animalPageSize)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: context.theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${controller.currentAnimalRangeStart}–${controller.currentAnimalRangeEnd} de $totalCount",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: controller.currentAnimalPage.value > 1 ? Colors.black87 : Colors.grey[300]),
                    onPressed: controller.previousAnimalPage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: controller.currentAnimalPage.value * controller.animalPageSize < totalCount ? Colors.black87 : Colors.grey[300]),
                    onPressed: controller.nextAnimalPage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildEmptyAnimaisState(BuildContext context, String category) {
    dynamic animalIcon;
    if (category == 'Bovino') {
      animalIcon = FontAwesomeIcons.cow;
    } else if (category == 'Ovino') {
      animalIcon = Icons.pets;
    } else {
      animalIcon = Icons.agriculture;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: animalIcon is IconData 
                ? Icon(animalIcon, size: 60, color: Colors.green[200])
                : FaIcon(animalIcon, size: 60, color: Colors.green[200]),
            ),
            const SizedBox(height: 24),
            const Text('Nenhum animal cadastrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Ops! Parece que você ainda não possui animais cadastrados neste rebanho.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => _showAddAnimalPage(),
              icon: const Icon(Icons.add, color: Colors.grey),
              label: Text('Cadastrar $category no Rebanho'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> content}) {
    return Container(
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.green[800]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          ...content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[800] : Colors.black,
          )),
        ],
      ),
    );
  }

  void _showDeleteAnimalsConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text("Excluir ${controller.selectedAnimals.length} animais?"),
          ],
        ),
        content: const Text("Esta ação apagará permanentemente todos os registros destes animais. Deseja continuar?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSelectedAnimals();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("EXCLUIR SELECIONADOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRelocateSelectionSelector(BuildContext context) async {
    final herds = await controller.getRelocationOptions();
    if (herds.isEmpty) {
      AgroAlert.show(
        title: "Aviso",
        message: "Não existem outros rebanhos da mesma categoria para realocar este lote.",
      );
      return;
    }

    var filteredHerds = <Map<String, dynamic>>[].obs;
    filteredHerds.value = herds;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Text(
              "Mover ${controller.selectedAnimals.length} Animais",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Selecione o rebanho de destino",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) {
                filteredHerds.value = herds
                    .where((h) => h['name'].toString().toLowerCase().contains(v.toLowerCase()))
                    .toList();
              },
              decoration: InputDecoration(
                hintText: "Pesquisar rebanho...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.isDarkMode ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: filteredHerds.length,
                itemBuilder: (context, index) {
                  final h = filteredHerds[index];
                  return ListTile(
                    leading: const Icon(Icons.other_houses_outlined, color: Colors.green),
                    title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${h['category']} | ${h['management_type']}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.relocateSelectedAnimals(h['id'], h['name']);
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEditNomeDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: controller.rebanho['name']);
    final locCtrl = TextEditingController(text: controller.rebanho['location'] ?? "");
    final RxString selectedManejo = (controller.rebanho['management_type'] ?? "Extensivo").toString().obs;
    final List<String> manejos = ["Extensivo", "Semiextensivo", "Intensivo"];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Editar Rebanho", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Nome do Rebanho",
                  filled: true,
                  fillColor: context.isDarkMode ? Colors.white10 : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locCtrl,
                decoration: InputDecoration(
                  labelText: "Localização / Galpão",
                  filled: true,
                  fillColor: context.isDarkMode ? Colors.white10 : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Tipo de Manejo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Obx(() => Column(
                children: manejos.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRadioTile(
                    label: m,
                    value: m,
                    groupValue: selectedManejo.value,
                    onChanged: (v) => selectedManejo.value = v!,
                    isFullWidth: true,
                  ),
                )).toList(),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await controller.editarRebanho(
                      nameCtrl.text.trim(),
                      locCtrl.text.trim(),
                      selectedManejo.value,
                    );
                    Get.back();
                    AgroAlert.show(title: "Sucesso", message: "Rebanho atualizado!", isSuccess: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRadioTile({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
    bool isFullWidth = false,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[800]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green[800] : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAnimalPage() {
    Get.toNamed('/add-animal', arguments: {
      'herd': controller.rebanho.value,
      'isEdition': false,
    });
  }

  void _showConfirmDeleteDialog(Map<String, dynamic> animal) {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Animal"),
        content: Text("Tem certeza que deseja excluir o animal '${animal['identifier']}'? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.excluirAnimal(animal['id']);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteHerdDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Excluir Rebanho"),
        content: Text("Tem certeza que deseja excluir o rebanho '${controller.rebanho['name']}' e TODOS os animais vinculados a ele? Esta ação é irreversível."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Fecha o modal
              controller.excluirRebanho();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir Tudo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
