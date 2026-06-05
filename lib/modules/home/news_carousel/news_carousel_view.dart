import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../home_controller.dart';
import '../../../models/noticia_model.dart';

class NewsCarousel extends StatefulWidget {
  @override
  _NewsCarouselState createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final HomeController controller = Get.find<HomeController>();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (controller.noticias.isNotEmpty) {
        _currentPage++;
        if (_currentPage >= controller.noticias.length) {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
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
    return Obx(() {
      if (controller.isLoadingNoticias.value) {
        return _buildShimmerState();
      }

      if (controller.hasNoticiasError.value) {
        return _buildErrorState();
      }

      if (controller.noticias.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          SizedBox(
            height: 310, 
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: controller.noticias.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _buildNewsCard(controller.noticias[index], index == 0);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Indicadores (Bolinhas)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.noticias.length, (index) {
              bool isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6, 
                width: isActive ? 20 : 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildNewsCard(NoticiaModel noticia, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        left: isFirst ? 0 : 8, 
        right: 8, 
        top: 4, 
        bottom: 12
      ),
      decoration: BoxDecoration(
        color: Get.context!.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem da Notícia com Shimmer de carregamento
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              noticia.imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(width: double.infinity, height: 180, color: Colors.white),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity, // CORREÇÃO: Garante largura total no erro
                height: 180,
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text("Imagem indisponível", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          // Conteúdo da Notícia
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noticia.titulo.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  noticia.dataRelativa,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _launchURL(noticia.linkUrl),
                  child: Text(
                    "Continue lendo...",
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerState() {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 8, right: 8, top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 180, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 15, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 15, width: 150, color: Colors.white),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 80, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.red[300], size: 40),
          const SizedBox(height: 12),
          const Text(
            "Não foi possível carregar as notícias.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => controller.fetchNoticias(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Tentar Novamente", style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Erro", "Não foi possível abrir o link.");
    }
  }
}
