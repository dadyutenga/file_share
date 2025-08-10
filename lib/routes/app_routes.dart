import 'package:flutter/material.dart';
import '../screens/LoadingScreen.dart';
import '../screens/LoginScreen.dart';
import '../screens/RegisterScreen.dart';

class AppRoutes {
  // Route names
  static const String loading = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Custom page transition
  static PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loading:
        return MaterialPageRoute(builder: (_) => const LoadingScreen());
      case login:
        return _createRoute(const LoginScreen());
      case register:
        return _createRoute(const RegisterScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            body: Center(
              child: Text(
                'No route defined for ${settings.name}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
    }
  }

  // Get initial route
  static String get initialRoute => loading;
}
