import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_view.dart';
import '../calendar/calendar_view.dart';
import '../scanner/animal_scanner_view.dart';
import '../chat/chatbot_view.dart';
import '../profile/profile_view.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> pages = [
    HomeView(),
    CalendarView(),
    AnimalScannerView(),
    ChatbotView(),
    ProfileView(),
  ];

  void changePage(int index) {
    currentIndex.value = index;
  }
}
