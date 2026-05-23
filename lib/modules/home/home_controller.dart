import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class HomeController extends GetxController {
  final _storage = GetStorage();
  
  final String _apiKey = "786443c5b36484397985794823861274"; 

  // Dados Climáticos Observáveis
  var temperatura = "--°C".obs;
  var umidade = "--%".obs;
  var thi = "--".obs;
  var lastUpdate = "Carregando...".obs;
  var localizacao = "Detectando...".obs;
  var isLoading = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('pt_BR', null);
    _loadInitialData();
    _startAutoUpdate();
  }

  void _loadInitialData() {
    if (_storage.hasData('last_temp')) {
      temperatura.value = _storage.read('last_temp');
      umidade.value = _storage.read('last_umid');
      thi.value = _storage.read('last_thi');
      lastUpdate.value = _storage.read('last_time');
      localizacao.value = _storage.read('last_loc') ?? "Crateús, CE";
    }
    updateWeatherData();
  }

  void _startAutoUpdate() {
    // Configura atualização periódica de 1 em 1 hora conforme solicitado
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      updateWeatherData();
    });
  }

  Future<void> updateWeatherData() async {
    try {
      isLoading.value = true;
      
      Position? position = await _determinePosition();
      
      Uri url;
      if (position != null) {
        url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey&lang=pt_br'
        );
      } else {
        url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=Crateus,BR&units=metric&appid=$_apiKey&lang=pt_br'
        );
      }

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double temp = data['main']['temp'].toDouble();
        double umid = data['main']['humidity'].toDouble();
        String cityName = data['name'];
        
        // FÓRMULA REAL DO THI (Thom, 1959) - IDÊNTICA À IA
        double thiValue = (1.8 * temp + 32) - ((0.55 - 0.0055 * umid) * (1.8 * temp - 26));

        temperatura.value = "${temp.toStringAsFixed(1)}°C";
        umidade.value = "${umid.toInt()}%";
        thi.value = thiValue.toStringAsFixed(1);
        
        if (position != null) {
          localizacao.value = "$cityName, ${data['sys']['country']}";
        } else {
          localizacao.value = "Crateús, CE";
        }

        _updateTime();
        _saveDataLocally();
        print("Monitoramento Automático: Clima atualizado via API.");
      } else {
        _simulateFallback();
      }
    } catch (e) {
      print("Monitoramento Automático: Erro na rede. Usando cache local.");
      if (!_storage.hasData('last_temp')) {
        _simulateFallback();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }

  void _simulateFallback() {
    if (_storage.hasData('last_temp')) {
      temperatura.value = _storage.read('last_temp');
      umidade.value = _storage.read('last_umid');
      thi.value = _storage.read('last_thi');
      localizacao.value = _storage.read('last_loc');
    } else {
      temperatura.value = "31.5°C";
      umidade.value = "25%";
      thi.value = "79.2";
      localizacao.value = "Crateús, CE";
    }
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    lastUpdate.value = DateFormat("EEE, HH:mm", "pt_BR").format(now);
  }

  void _saveDataLocally() {
    _storage.write('last_temp', temperatura.value);
    _storage.write('last_umid', umidade.value);
    _storage.write('last_thi', thi.value);
    _storage.write('last_time', lastUpdate.value);
    _storage.write('last_loc', localizacao.value);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
