import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class MarketCarousel extends StatefulWidget {
  @override
  _MarketCarouselState createState() => _MarketCarouselState();
}

class _MarketCarouselState extends State<MarketCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _marketData = [
    {
      'category': '🥛 Leite & Derivados',
      'items': [
        {'label': 'Leite Bovino', 'price': 'R\$ 2,40/L'},
        {'label': 'Leite Caprino', 'price': 'R\$ 3,80/L'},
        {'label': 'Queijo Coalho', 'price': 'R\$ 28,00/kg'},
      ],
      'note': 'Média Crateús/CE'
    },
    {
      'category': '🥩 Ovinos & Caprinos',
      'items': [
        {'label': 'Cordeiro Jovem', 'price': 'R\$ 15,00/kg vivo'},
        {'label': 'Cabrito p/ Abate', 'price': 'R\$ 14,20/kg vivo'},
        {'label': 'Ovelha Descarte', 'price': 'R\$ 9,50/kg vivo'},
      ],
      'note': 'Preços de Balcão'
    },
    {
      'category': '🐄 Bovinos (Corte & Reposição)',
      'items': [
        {'label': 'Boi Gordo', 'price': 'R\$ 285,00/@'},
        {'label': 'Vaca Gorda', 'price': 'R\$ 260,00/@'},
        {'label': 'Bezerro de Ano', 'price': 'R\$ 2.100,00/cab.'},
      ],
      'note': 'Cotação Regional'
    },
    {
      'category': '🌾 Insumos Alimentares',
      'items': [
        {'label': 'Milho (60kg)', 'price': 'R\$ 82,00'},
        {'label': 'Farelo Soja (50kg)', 'price': 'R\$ 115,00'},
        {'label': 'Silagem (ton)', 'price': 'R\$ 350,00'},
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
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_currentPage < _marketData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
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
    final isDark = context.isDarkMode;
    
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: isDark ? Colors.green[900]!.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[800]!.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _marketData.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final data = _marketData[index];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['category'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        data['note'],
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (data['items'] as List).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'],
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                item['price'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
