import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/drone_tracking_screen.dart';
import 'screens/emergency_onboarding_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/emergency_contact_screen.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  bool isPrivacyAccepted = false;
  try {
    await dotenv.load(fileName: ".env");
    final prefs = await SharedPreferences.getInstance();
    isPrivacyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;
  } catch (e) {
    print('Warning: Initialization error: $e');
  }
  
  runApp(ProviderScope(
    overrides: [
      privacyPolicyProvider.overrideWith((ref) => isPrivacyAccepted),
    ],
    child: const MyApp(),
  ));
}

final privacyPolicyProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authStateProvider.stream);
  
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final isPrivacyAccepted = ref.read(privacyPolicyProvider);

      // 1. Check Privacy Policy first
      if (!isPrivacyAccepted && state.uri.toString() != '/privacy-policy') {
        return '/privacy-policy';
      }
      if (isPrivacyAccepted && state.uri.toString() == '/privacy-policy') {
         // Check auth to decide where to go after privacy
         // accessing value directly via read might be null if loading, but stream updates will re-trigger
         final authState = ref.read(authStateProvider);
         if (authState.value != null) return '/';
         return '/login'; 
      }

      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      // 2. Check Auth
      if (!isLoggedIn && !isLoggingIn && state.uri.toString() != '/privacy-policy') return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      // 3. Check Emergency Contact (if logged in)
      // We use ref.read here to avoid rebuilding the router on profile changes
      if (isLoggedIn) {
         final userProfile = ref.read(userProfileProvider).value;
         
         final hasContactsList = userProfile != null && 
                               (userProfile['emergencyContacts'] as List?)?.isNotEmpty == true;
         final hasLegacyContact = userProfile != null && 
                               userProfile['emergencyContactNumber'] != null && 
                               (userProfile['emergencyContactNumber'] as String).isNotEmpty;
         
         final hasEmergencyContact = hasContactsList || hasLegacyContact;
         
         final isSettingContact = state.uri.toString() == '/emergency-contact';
         
         // Only redirect TO emergency contact if missing. 
         // Do not redirect FROM it if we just added one (because this redirect logic runs on navigation, 
         // but since we are not rebuilding router, it might not run automatically on data change which is GOOD 
         // for keeping user on screen. But we might want to force it if they delete all contacts?
         // For now, simpler is better: if they are actively using the app, let them be.
         if (userProfile != null && !hasEmergencyContact && !isSettingContact) {
           return '/emergency-contact'; 
         }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/drone-tracking',
        builder: (context, state) => const DroneTrackingScreen(),
      ),
      GoRoute(
        path: '/emergency-onboarding',
        builder: (context, state) => const EmergencyOnboardingScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/emergency-contact',
        builder: (context, state) => const EmergencyContactScreen(),
      ),
    ],
  );
});

// Helper for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isPrivacyAccepted = ref.watch(privacyPolicyProvider);

    return MaterialApp.router(
      title: 'Diabetes AI Manager',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
