import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/verify_otp_page.dart';
import '../features/main/ui/pages/main_page.dart';
import 'app_routes.dart';

PageRouteBuilder _createRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
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
      return _createRoute(MainPage(), settings);
    //================================== auth routes ==================================
    case AppRoutes.login:
      return _createRoute(const LoginPage(), settings);
    case AppRoutes.register:
      return _createRoute(const RegisterPage(), settings);
    case AppRoutes.forgotPassword:
      return _createRoute(const ForgotPasswordPage(), settings);
    case AppRoutes.verifyOtp:
      return _createRoute(const VerifyOtpPage(), settings);
    case AppRoutes.resetPassword:
      return _createRoute(const ResetPasswordPage(), settings);
    default:
      return _createRoute(const SizedBox(), settings);
  }
}
