import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'modules/auth/login_view.dart';
import 'modules/auth/register_view.dart';
import 'modules/auth/email_verification_view.dart';
import 'modules/auth/auth_controller.dart';
import 'modules/auth/forgot_password/forgot_password_view.dart';
import 'modules/onboarding/onboarding_view.dart';
import 'modules/rebanho/rebanho_view.dart';
import 'modules/rebanho/cadastro_rebanho/cadastro_rebanho_view.dart';
import 'modules/rebanho/detalhes_rebanho/detalhes_rebanho_view.dart';
import 'modules/rebanho/detalhes_rebanho/add_animal/add_animal_view.dart';
import 'modules/rebanho/perfil_animal/perfil_animal_view.dart';
import 'modules/rebanho/historico_animal/historico_animal_view.dart';
import 'modules/ia_analysis/ia_analysis_view.dart';
import 'modules/ia_analysis/genetic_recommendation/ranking_abs_view.dart';
import 'modules/ia_analysis/genetic_recommendation/ranking_results_view.dart';
import 'modules/ia_analysis/fertility_patterns/fertility_patterns_view.dart';
import 'modules/reports/reports_view.dart';
import 'modules/chat/chatbot_view.dart';
import 'modules/home/home_view.dart';
import 'modules/home/notifications_view.dart';
import 'modules/home/tutorial_view.dart';
import 'modules/calendar/calendar_view.dart';
import 'modules/calendar/calendar_search_view.dart';
import 'modules/activities_history/activities_history_view.dart';
import 'modules/profile/profile_view.dart';
import 'modules/profile/edit_profile/edit_profile_view.dart';
import 'modules/profile/biologic_config/biologic_config_view.dart';
import 'modules/support/support_view.dart';
import 'modules/scanner/animal_scanner_view.dart';
import 'modules/scanner/web_animal_view.dart';
import 'modules/activities_history/add_activity/add_activity_view.dart';
import 'modules/activities_history/activity_details/activity_details_view.dart';
import 'modules/home/theme_controller.dart';
import 'modules/navigation/navigation_view.dart';
import 'modules/navigation/navigation_controller.dart';
import 'modules/splash/splash_view.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Importante para tirar o # da URL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Remove o '#' da URL no navegador
  await GetStorage.init();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBD3Zu7Hp0dL3JATQN7UYVziOqG0PP0AXo",
      appId: "1:709533791846:android:7bcbd4665a7e6156ca5fa7",
      messagingSenderId: "709533791846",
      projectId: "agrogen-crateus-2026",
      storageBucket: "agrogen-crateus-2026.firebasestorage.app",
    ),
  );

  final ThemeController themeController = Get.put(ThemeController());
  Get.put(AuthController(), permanent: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AgroTech Crateús',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        primaryColor: Colors.green[800],
        scaffoldBackgroundColor: const Color(0xFFF8F9F5),
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        primaryColor: Colors.green[800],
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: Get.find<ThemeController>().isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      
      // Lógica de Entrada: Se a URL contém /animal/, vai direto para lá. Caso contrário, Splash.
      initialRoute: (Uri.base.toString().contains('/animal/')) 
          ? '/animal/${Uri.base.pathSegments.last}' 
          : '/splash',

      getPages: [
        GetPage(name: '/splash', page: () => SplashView()),
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/register', page: () => RegisterView()),
        GetPage(name: '/email-verification', page: () => EmailVerificationView()),
        GetPage(name: '/forgot-password', page: () => ForgotPasswordView()),
        GetPage(name: '/onboarding', page: () => OnboardingView()),
        GetPage(name: '/navigation', page: () => NavigationView()),
        GetPage(name: '/rebanho', page: () => RebanhoView()),
        GetPage(name: '/cadastro-rebanho', page: () => CadastroRebanhoView()),
        GetPage(name: '/detalhes-rebanho', page: () => DetalhesRebanhoView()),
        GetPage(name: '/add-animal', page: () => AddAnimalView()),
        GetPage(name: '/perfil-animal', page: () => PerfilAnimalView()),
        GetPage(name: '/historico-animal', page: () => HistoricoAnimalView()),
        GetPage(name: '/ia-analysis', page: () => IaAnalysisView()),
        GetPage(name: '/ranking-abs', page: () => RankingABSView()),
        GetPage(name: '/ranking-results', page: () => RankingResultsView()),
        GetPage(name: '/fertility-patterns', page: () => FertilityPatternsView()),
        GetPage(name: '/reports', page: () => ReportsView()),
        GetPage(name: '/notifications', page: () => NotificationsView()),
        GetPage(name: '/chatbot', page: () => ChatbotView()),
        GetPage(name: '/tutorial', page: () => TutorialView()),
        GetPage(name: '/calendar', page: () => CalendarView()),
        GetPage(name: '/calendar-search', page: () => CalendarSearchView()),
        GetPage(name: '/activities-history', page: () => ActivitiesHistoryView()),
        GetPage(name: '/add-activity', page: () => AddActivityView()),
        GetPage(name: '/activity-details', page: () => ActivityDetailsView()),
        GetPage(name: '/profile', page: () => ProfileView()),
        GetPage(name: '/edit-profile', page: () => EditProfileView()),
        GetPage(name: '/biologic-config', page: () => BiologicConfigView()),
        GetPage(name: '/support', page: () => SupportView()),
        GetPage(name: '/scanner', page: () => AnimalScannerView()),
        GetPage(name: '/home', page: () => HomeView()),
        GetPage(name: '/animal/:id', page: () => WebAnimalView()),
      ],
    );
  }
}
