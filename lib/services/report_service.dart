import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../database/database_helper.dart';

class ReportService {
  /// Gera e compartilha um relatório em formato CSV com todos os animais
  static Future<void> generateAndShareCSV() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> animals = await db.query('animals');

    if (animals.isEmpty) {
      throw "Nenhum animal cadastrado para exportar.";
    }

    // Cabeçalho do CSV
    List<List<dynamic>> rows = [];
    rows.add([
      "ID",
      "Brinco/Identificador",
      "Nome",
      "Espécie",
      "Raça",
      "Sexo",
      "Escore Corporal",
      "Peso (kg)",
      "Idade (meses)",
      "Status Reprodutivo",
      "Linhagem"
    ]);

    for (var a in animals) {
      rows.add([
        a['id'],
        a['identifier'],
        a['name'] ?? "N/A",
        "Puxar de Herds", // Simplificado para o POC
        a['breed'],
        a['sex'],
        a['ecc'],
        a['weight'],
        a['age_months'],
        a['reproductive_status'],
        a['lineage'] ?? "N/A"
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/relatorio_agrogen_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    
    await file.writeAsString(csvData);
    
    await Share.shareXFiles([XFile(path)], text: 'Relatório de Rebanho - AgroGen Crateús');
  }

  /// Gera e compartilha um PDF técnico formatado
  static Future<void> generateAndSharePDF() async {
    final pdf = pw.Document();
    final db = await DatabaseHelper.instance.database;
    
    // Busca dados reais para o PDF
    final List<Map<String, dynamic>> animals = await db.query('animals');
    final List<Map<String, dynamic>> herds = await db.query('herds');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("AgroGen Crateús - Relatorio Tecnico", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(DateTime.now().toString().split('.')[0]),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text("Resumo do Rebanho", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "Total de Rebanhos: ${herds.length}"),
          pw.Bullet(text: "Total de Animais: ${animals.length}"),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            context: context,
            data: <List<String>>[
              <String>['Identificador', 'Especie', 'Raca', 'ECC', 'Status'],
              ...animals.map((a) => [
                a['identifier'].toString(),
                "Animal", // Simplificado
                a['breed'].toString(),
                a['ecc'].toString(),
                a['reproductive_status'].toString(),
              ])
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 30),
            child: pw.Text("Este relatorio foi gerado de forma offline pelo motor de IA do AgroGen Crateus.", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          )
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/laudo_tecnico_agrogen_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(path)], text: 'Laudo Técnico Reprodutivo - AgroGen Crateús');
  }
}
