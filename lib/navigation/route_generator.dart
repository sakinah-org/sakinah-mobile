import 'package:flutter/material.dart';
import '../features/main/ui/pages/main_page.dart';
import 'app_routes.dart';

PageRouteBuilder _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04), // subtle slide from bottom
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.main:
      return _createRoute(MainPage());
    //================================== auth routes ==================================
    default:
      return _createRoute(const SizedBox());
  }
}
