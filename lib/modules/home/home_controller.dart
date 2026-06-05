import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../services/noticias_service.dart';
import '../../models/noticia_model.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sync_service.dart';
import '../../database/database_helper.dart';
import 'notifications_controller.dart';

class HomeController extends GetxController {
  final _storage = GetStorage();
  final _noticiasService = NoticiasService();
  final notificationsController = Get.put(NotificationsController());
  
  // Chave Técnica OpenWeather
  final String _apiKey = "5ea0840b8529367140b08075f782390f"; 

  // Dados Climáticos Observáveis
  var temperatura = "--°C".obs;
  var umidade = "--%".obs;
  var thi = "--".obs;
  var climaIcon = "01d".obs; // Código do ícone do OpenWeather
  var lastUpdate = "Carregando...".obs;
  var localizacao = "Detectando...".obs;
  var isLoadingWeather = false.obs;
  var isOffline = false.obs;

  // Notícias
  var noticias = <NoticiaModel>[].obs;
  var isLoadingNoticias = false.obs;
  var hasNoticiasError = false.obs;

  // Dados do Usuário Reativos
  var userName = "Usuário".obs;
  var firstName = "Produtor".obs;
  var farmName = "Sua Fazenda".obs;
  var userLocation = "Crateús, CE".obs;
  var userPhotoPath = "".obs;
  var networkPhotoUrl = "".obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('pt_BR', null);
    _loadInitialData();
    loadUserProfile();
    _startAutoUpdate();
    fetchNoticias();
    SyncService.instance.syncLocalToCloud(); // Inicia sincronia silenciosa
  }

  void loadUserProfile() {
    final User? user = FirebaseAuth.instance.currentUser;
    networkPhotoUrl.value = user?.photoURL ?? "";
    userPhotoPath.value = _storage.read('userPhotoPath') ?? "";
    
    final full = _storage.read('userName') ?? user?.displayName ?? "Usuário";
    userName.value = full;
    firstName.value = full.split(' ').first;
    farmName.value = _storage.read('farmName') ?? "Sua Fazenda";
    userLocation.value = _storage.read('location') ?? "Crateús, CE";
  }

  void _loadInitialData() {
    if (_storage.hasData('last_temp')) {
      temperatura.value = _storage.read('last_temp');
      umidade.value = _storage.read('last_umid');
      thi.value = _storage.read('last_thi');
      climaIcon.value = _storage.read('last_icon') ?? "01d";
      lastUpdate.value = _storage.read('last_time');
      localizacao.value = _storage.read('last_loc') ?? "Crateús, CE";
    }
    updateWeatherData();
  }

  Future<void> fetchNoticias() async {
    try {
      isLoadingNoticias.value = true;
      hasNoticiasError.value = false;
      final result = await _noticiasService.fetchNoticias();
      noticias.value = result;
    } catch (e) {
      hasNoticiasError.value = true;
      print("Erro ao buscar notícias: $e");
    } finally {
      isLoadingNoticias.value = false;
    }
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      updateWeatherData();
      fetchNoticias();
    });
  }

  Future<void> updateWeatherData() async {
    try {
      isLoadingWeather.value = true;
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
        String iconCode = data['weather'][0]['icon'];
        
        double thiValue = (1.8 * temp + 32) - ((0.55 - 0.0055 * umid) * (1.8 * temp - 26));

        _checkThiChange(thiValue);

        temperatura.value = "${temp.toStringAsFixed(1)}°C";
        umidade.value = "${umid.toInt()}%";
        thi.value = thiValue.toStringAsFixed(1);
        climaIcon.value = iconCode;
        
        localizacao.value = position != null ? "$cityName, ${data['sys']['country']}" : "Crateús, CE";

        isOffline.value = false;
        _updateTime();
        _saveDataLocally();
      } else {
        print("CLIMA ERROR: Status ${response.statusCode} - ${response.body}");
        isOffline.value = true;
        _simulateFallback();
      }
    } catch (e) {
      print("CLIMA EXCEPTION: $e");
      isOffline.value = true;
      _simulateFallback();
    } finally {
      isLoadingWeather.value = false;
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
      climaIcon.value = _storage.read('last_icon') ?? "01d";
      localizacao.value = _storage.read('last_loc');
    } else {
      temperatura.value = "26.5°C";
      umidade.value = "54%";
      thi.value = "76.8";
      climaIcon.value = "01d";
      localizacao.value = "Crateús, CE";
      _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    lastUpdate.value = DateFormat("EEE, HH:mm", "pt_BR").format(now);
  }

  void _saveDataLocally() {
    _storage.write('last_temp', temperatura.value);
    _storage.write('last_umid', umidade.value);
    _storage.write('last_thi', thi.value);
    _storage.write('last_icon', climaIcon.value);
    _storage.write('last_time', lastUpdate.value);
    _storage.write('last_loc', localizacao.value);
  }

  void _checkThiChange(double currentThi) async {
    String currentStatus = _getThiStatus(currentThi);
    String? lastStatus = _storage.read('last_thi_status');

    if (lastStatus != currentStatus) {
      _storage.write('last_thi_status', currentStatus);
      
      String title = "Mudança Climática: THI $currentStatus";
      String message = _getThiRecommendation(currentStatus, currentThi);

      final db = await DatabaseHelper.instance.database;
      await db.insert('app_notifications', {
        'event_id': null,
        'title': title,
        'message': message,
        'date': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
      
      notificationsController.loadNotifications();
    }
  }

  String _getThiStatus(double thi) {
    if (thi < 72) return "Conforto";
    if (thi <= 78) return "Estresse Leve";
    if (thi <= 88) return "Estresse Moderado";
    return "Estresse Grave";
  }

  String _getThiRecommendation(String status, double val) {
    switch (status) {
      case "Conforto":
        return "Clima ideal (THI ${val.toStringAsFixed(1)}). Excelente janela para inseminações e manejos intensivos. Os animais estão em alto vigor metabólico.";
      case "Estresse Leve":
        return "Atenção (THI ${val.toStringAsFixed(1)}). Inicie o monitoramento de sombra. A eficiência da IA pode começar a oscilar levemente.";
      case "Estresse Moderado":
        return "Alerta Crítico (THI ${val.toStringAsFixed(1)}). Aumente a oferta de água e evite movimentar o gado nas horas mais quentes. Baixa taxa de concepção esperada.";
      case "Estresse Grave":
        return "PERIGO TÉCNICO (THI ${val.toStringAsFixed(1)}). Risco de perda embrionária e estresse calórico severo. NÃO realize inseminações. Priorize resfriamento e hidratação total.";
      default:
        return "O índice THI mudou para $status. Verifique as condições do rebanho.";
    }
  }

  Future<void> refreshHome() async {
    // Dispara todas as atualizações em paralelo
    await Future.wait([
      updateWeatherData(),
      fetchNoticias(),
      SyncService.instance.syncLocalToCloud(), // Sincroniza ao puxar para atualizar
      notificationsController.refreshNotifications(), // Verifica novas notificações
    ]);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
