import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class MarketCarousel extends StatefulWidget {
  @override
  _MarketCarouselState createState() => _MarketCarouselState();
}

class _MarketCarouselState extends State<MarketCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _marketData = [
    {
      'category': 'Leite & Derivados',
      'icon': Icons.opacity,
      'color': Colors.blue[600],
      'items': [
        {'label': 'Leite Bovino', 'price': 'R\$ 2,40', 'unit': '/L'},
        {'label': 'Leite Caprino', 'price': 'R\$ 3,80', 'unit': '/L'},
        {'label': 'Queijo Coalho', 'price': 'R\$ 28,00', 'unit': '/kg'},
      ],
      'note': 'Média Crateús/CE'
    },
    {
      'category': 'Ovinos & Caprinos',
      'icon': Icons.pets,
      'color': Colors.orange[800],
      'items': [
        {'label': 'Cordeiro Jovem', 'price': 'R\$ 15,00', 'unit': '/kg vivo'},
        {'label': 'Cabrito p/ Abate', 'price': 'R\$ 14,20', 'unit': '/kg vivo'},
        {'label': 'Ovelha Descarte', 'price': 'R\$ 9,50', 'unit': '/kg vivo'},
      ],
      'note': 'Preços de Balcão'
    },
    {
      'category': 'Bovinos de Corte',
      'icon': Icons.agriculture,
      'color': Colors.brown[600],
      'items': [
        {'label': 'Boi Gordo', 'price': 'R\$ 285,00', 'unit': '/@'},
        {'label': 'Vaca Gorda', 'price': 'R\$ 260,00', 'unit': '/@'},
        {'label': 'Bezerro Ano', 'price': 'R\$ 2.100', 'unit': '/cab.'},
      ],
      'note': 'Cotação Regional'
    },
    {
      'category': 'Insumos Alimentares',
      'icon': Icons.grass,
      'color': Colors.green[700],
      'items': [
        {'label': 'Milho (60kg)', 'price': 'R\$ 82,00', 'unit': ''},
        {'label': 'Farelo Soja', 'price': 'R\$ 115,00', 'unit': '/50kg'},
        {'label': 'Silagem', 'price': 'R\$ 350,00', 'unit': '/ton'},
      ],
      'note': 'Posto Crateús'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentPage < _marketData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
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
          height: 135,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _marketData.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final data = _marketData[index];
              return _buildMarketCard(data);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_marketData.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width: _currentPage == index ? 12 : 4,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.green[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> data) {
    final isDark = Get.isDarkMode;
    final color = data['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da Categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(data['icon'], size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  data['category'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  data['note'],
                  style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Itens de Preço
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: (data['items'] as List).map((item) {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: item['price'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: item['unit'],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
