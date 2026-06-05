import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WebAnimalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? animalId = Get.parameters['id'];
    print("WEB_DEBUG: Acessando animal com ID: $animalId");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: animalId == null 
        ? const Center(child: Text("ID do animal não fornecido."))
        : FutureBuilder<DocumentSnapshot?>(
            future: _findAnimalGlobally(animalId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Buscando na base global...", style: TextStyle(color: Colors.grey)),
                  ],
                ));
              }

              if (snapshot.hasError) {
                print("WEB_DEBUG_ERROR: ${snapshot.error}");
                return _buildNotFound(animalId ?? "");
              }

              final doc = snapshot.data;
              if (doc == null || !doc.exists) {
                print("WEB_DEBUG: Nenhum documento encontrado para o ID $animalId");
                return _buildNotFound(animalId ?? "");
              }

              final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
              if (data == null) return _buildNotFound(animalId ?? "");

              print("WEB_DEBUG: Animal encontrado! Nome: ${data['name']}");
              return _buildPublicProfile(data);
            },
          ),
    );
  }

  Future<DocumentSnapshot?> _findAnimalGlobally(String id) async {
    try {
      // 1. Tenta buscar pelo ID do documento (Identifier/Brinco)
      // Como usamos collectionGroup, o ID do documento é uma ferramenta poderosa
      final queryByIdentifierDoc = await FirebaseFirestore.instance
          .collectionGroup('animals')
          .where(FieldPath.documentId, isEqualTo: id)
          .limit(1)
          .get();
      
      if (queryByIdentifierDoc.docs.isNotEmpty) {
        print("WEB_DEBUG: Animal encontrado via ID de documento");
        return queryByIdentifierDoc.docs.first;
      }

      // 2. Tenta buscar pelo campo 'id' numérico (ID sincronizado do SQLite)
      final num? idAsNumber = num.tryParse(id);
      if (idAsNumber != null) {
        final queryByNum = await FirebaseFirestore.instance
            .collectionGroup('animals')
            .where('id', isEqualTo: idAsNumber)
            .limit(1)
            .get();
        if (queryByNum.docs.isNotEmpty) {
          print("WEB_DEBUG: Animal encontrado via ID numérico");
          return queryByNum.docs.first;
        }
      }

      // 3. Tenta buscar pelo campo 'identifier' (Brinco/Texto)
      final queryByIdentifier = await FirebaseFirestore.instance
          .collectionGroup('animals')
          .where('identifier', isEqualTo: id)
          .limit(1)
          .get();

      if (queryByIdentifier.docs.isNotEmpty) {
        print("WEB_DEBUG: Animal encontrado via Identificador");
        return queryByIdentifier.docs.first;
      }
      
      return null;
    } catch (e) {
      print("WEB_DEBUG_EXCEPTION: $e");
      return null;
    }
  }

  Widget _buildNotFound(String id) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Animal não encontrado", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("O código '$id' não existe no banco de dados ou ainda não foi sincronizado.", 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.grey)
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text("IR PARA O LOGIN"),
          )
        ],
      ),
    );
  }

  Widget _buildPublicProfile(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green, size: 64),
                    const SizedBox(height: 12),
                    Text(data['identifier']?.toString() ?? "Sem ID", 
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text(data['name']?.toString() ?? "Sem apelido", 
                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Seção: Dados Biofísicos
              _buildSectionTitle("FICHA TÉCNICA BIOLÓGICA", Icons.analytics_outlined),
              _buildDataGrid([
                _buildDataCell("Espécie", data['category']),
                _buildDataCell("Raça", data['breed_name'] ?? data['breed']),
                _buildDataCell("Sexo", data['sex']),
                _buildDataCell("Peso", "${data['weight']} kg"),
                _buildDataCell("Idade", "${data['age_months']} meses"),
                _buildDataCell("ECC", data['ecc']),
                _buildDataCell("Aptidão", data['aptitude']),
                _buildDataCell("Paridade", data['parity']),
                _buildDataCell("DPP", data['dpp_status'] ?? "N/A"),
                _buildDataCell("Status Vital", data['vital_status'] ?? "Ativo"),
              ]),

              const SizedBox(height: 32),
              
              // Seção: Datas
              _buildSectionTitle("CRONOLOGIA", Icons.calendar_today_outlined),
              _buildDataRow("Data Nascimento", data['birth_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data['birth_date'])) : "Não informada"),
              if (data['death_date'] != null)
                _buildDataRow("Data de Saída/Óbito", DateFormat('dd/MM/yyyy').format(DateTime.parse(data['death_date']))),

              const SizedBox(height: 32),
              
              // Seção: Genealogia
              _buildSectionTitle("GENEALOGIA E LINHAGEM", Icons.account_tree_outlined),
              _buildDataRow("Linhagem", data['lineage']),
              _buildDataRow("Pai", data['id_pai']),
              _buildDataRow("Mãe", data['id_mae']),

              if (data['pdf_path'] != null && data['pdf_path'].toString().isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.blue),
                      SizedBox(width: 12),
                      Text("Possui Certificado de Rastreabilidade", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              
              // Seção: Histórico de Atividades (Bônus Hackathon)
              _buildSectionTitle("HISTÓRICO RECENTE DE MANEJO", Icons.history),
              _buildWebTimeline(data['id']), // Busca eventos vinculados a este animal

              const SizedBox(height: 60),
              const Center(child: Text("SISTEMA AGROTECH CRATEÚS - RASTREABILIDADE TOTAL", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.0))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTimeline(dynamic animalId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collectionGroup('events').where('animal_id', isEqualTo: animalId).orderBy('date', descending: true).limit(10).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("Nenhum manejo registrado recentemente.", style: TextStyle(color: Colors.grey, fontSize: 12));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final e = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              title: Text(e['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(e['date'].toString().split('T').first, style: const TextStyle(fontSize: 11)),
              trailing: Text(e['text_value_1'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green[800]),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildDataGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: children,
    );
  }

  Widget _buildDataCell(String label, dynamic val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val?.toString() ?? "N/A", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDataRow(String label, dynamic val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val?.toString() ?? "Desconhecido", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
