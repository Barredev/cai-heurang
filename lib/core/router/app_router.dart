// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/main_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String main       = '/main';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _fade(const OnboardingScreen());
      case main:
        return _fade(const MainScreen());
      default:
        return _fade(const OnboardingScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );
}