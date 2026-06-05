import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/noticia_model.dart';

class NoticiasService {
  static const String baseUrl = "https://crateus.ce.gov.br";
  static const String targetUrl = "https://crateus.ce.gov.br/informa.php?dtini=&dtfim=&descr=&cate=3&secr=";

  Future<List<NoticiaModel>> fetchNoticias() async {
    try {
      final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        
        // As notícias estão dentro de .col-md-4 de acordo com a estrutura informada
        List<Element> containers = document.querySelectorAll('.col-md-4');
        List<NoticiaModel> noticias = [];

        for (var container in containers) {
          if (noticias.length >= 12) break; // Limita a 12 notícias
          try {
            // Extração da Imagem
            var imgTag = container.querySelector('img');
            String relativeImg = imgTag?.attributes['src'] ?? "";
            String fullImg = relativeImg.startsWith('http') ? relativeImg : "$baseUrl$relativeImg";

            // Extração do Link
            var linkTag = container.querySelector('a');
            String relativeLink = linkTag?.attributes['href'] ?? "";
            String fullLink = relativeLink.startsWith('http') ? relativeLink : "$baseUrl$relativeLink";

            // Extração do Título (strong dentro do link)
            var titleTag = container.querySelector('strong');
            String title = titleTag?.text.trim() ?? "Sem título";

            // Extração da Data (Procura por span que contenha 'Há' ou que esteja após o título)
            var spanTags = container.querySelectorAll('span');
            String date = "Recentemente";
            for (var span in spanTags) {
              if (span.text.contains('Há') || span.text.contains('há')) {
                date = span.text.trim();
                break;
              }
            }

            if (title != "Sem título") {
              noticias.add(NoticiaModel(
                titulo: title,
                imageUrl: fullImg,
                dataRelativa: date,
                linkUrl: fullLink,
              ));
            }
          } catch (e) {
            print("Erro ao parsear bloco de notícia individual: $e");
          }
        }
        return noticias;
      } else {
        throw Exception("Falha ao carregar notícias: Status ${response.statusCode}");
      }
    } catch (e) {
      print("Erro no Web Scraping: $e");
      rethrow;
    }
  }
}
