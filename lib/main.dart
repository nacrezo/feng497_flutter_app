import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/prediction_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chatbot',
      builder: (context, state) => const ChatbotScreen(),
    ),
    GoRoute(
      path: '/prediction',
      builder: (context, state) => const PredictionScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Diabetes AI Manager',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
