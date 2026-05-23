import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

/// --- MODELO DE DADOS DE NOTÍCIA ---
class NoticiaModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;
  final Color categoryColor;
  final String imageUrl;
  final String date;

  NoticiaModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.categoryColor,
    required this.imageUrl,
    required this.date,
  });
}

/// --- COMPONENTE DE CARROSSEL DE NOTÍCIAS (CONEXÃO CRATEÚS) ---
class NewsCarousel extends StatefulWidget {
  @override
  _NewsCarouselState createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  // Mock de dados realistas para o Sertão de Crateús
  final List<NoticiaModel> _newsList = [
    NoticiaModel(
      id: '1',
      category: 'ALERTA',
      categoryColor: Colors.red[700]!,
      title: 'Surto de Pododermatite em Crateús: Cuidados com os Cascos',
      summary: 'Aumento da umidade no solo favorece doenças. Veja como proteger seu rebanho.',
      content: 'Com as chuvas recentes na região de Crateús, veterinários alertam para o aumento de casos de pododermatite (pedereira). É fundamental manter o curral seco e realizar o pedilúvio preventivo com sulfato de cobre. Fique atento a manqueiras e inchaços entre as unhas dos animais.',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=60',
      date: '22 Mai 2026',
    ),
    NoticiaModel(
      id: '2',
      category: 'MERCADO',
      categoryColor: Colors.green[700]!,
      title: 'Preço do Ovino Vivo atinge R\$ 14,50 na Feira de Crateús',
      summary: 'Valorização de 8% em relação ao mês anterior anima os produtores locais.',
      content: 'A última feira de animais de Crateús registrou uma excelente movimentação para os pequenos produtores. O quilo do ovino vivo atingiu a marca de R\$ 14,50, impulsionado pela alta demanda da capital e o bom escore corporal dos animais da região.',
      imageUrl: 'https://images.unsplash.com/photo-1484557985045-edf25e08da73?auto=format&fit=crop&w=800&q=60',
      date: '21 Mai 2026',
    ),
    NoticiaModel(
      id: '3',
      category: 'CONAB',
      categoryColor: Colors.blue[700]!,
      title: 'Milho Balcão: Novo lote liberado para retirada na CONAB Crateús',
      summary: 'Produtores cadastrados já podem emitir as guias para o próximo mês.',
      content: 'A Unidade da CONAB em Crateús informou a chegada de 500 toneladas de milho para o programa Venda em Balcão. O estoque visa garantir a suplementação nutricional durante a transição de safra. O limite por produtor continua sendo de 60 sacas por CPF.',
      imageUrl: 'https://images.unsplash.com/photo-1594755335133-722a278964d4?auto=format&fit=crop&w=800&q=60',
      date: '20 Mai 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _newsList.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _newsList.length,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return _buildNewsCard(_newsList[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildNewsCard(NoticiaModel news) {
    return GestureDetector(
      onTap: () => Get.to(() => NoticiaCompletaView(news: news)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Imagem de Fundo (Placeholder caso falte internet)
              Image.network(
                news.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.green[50],
                  child: Icon(Icons.image_outlined, color: Colors.green[200], size: 40),
                ),
              ),
              // Gradiente para legibilidade do texto
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              // Conteúdo (Tag e Textos)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: news.categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_newsList.length, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.green[800] : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

/// --- TELA DE NOTÍCIA COMPLETA ---
class NoticiaCompletaView extends StatelessWidget {
  final NoticiaModel news;

  NoticiaCompletaView({required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.green[800],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.green[800]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: news.categoryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          news.category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(news.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    news.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const Divider(height: 40),
                  Text(
                    news.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: context.isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
