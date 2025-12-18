import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../services/mock_glucose_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _arePermissionsChecked = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    // Request all necessary permissions upfront to ensure emergency features work smoothly
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
      Permission.phone, 
    ].request();

    // Log or handle denial if necessary, but for now just requesting is enough
    print("Permissions status: $statuses");
    
    if (mounted) {
      setState(() {
        _arePermissionsChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    
    // Auto-Emergency Trigger
    ref.listen(glucoseProvider, (previous, next) {
      if (!_arePermissionsChecked) return; // Wait for permissions

      next.whenData((readings) {
        if (readings.isEmpty) return;
        final latest = readings.lastWhere((r) => !r.isPrediction, orElse: () => readings.last);
        
        final isCritical = latest.value <= 70 || latest.value >= 250;
        final isNormal = latest.value > 75 && latest.value < 245; // Hysteresis
        final isAcknowledged = ref.read(emergencyAckProvider);

        if (isCritical && !isAcknowledged) {
           final location = GoRouterState.of(context).uri.toString();
           if (!location.startsWith('/drone-tracking')) {
              context.go('/drone-tracking?auto=true');
           }
        } else if (isNormal && isAcknowledged) {
           // Reset acknowledgement when glucose returns to safe range
           ref.read(emergencyAckProvider.notifier).state = false;
        }
      });
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            color: Colors.white70,
                          ),
                        ),
                        userProfile.when(
                          data: (data) => Text(
                            data?['name'] ?? 'Health Guardian',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 40,
                            width: 200,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: LinearProgressIndicator(
                                color: Colors.cyanAccent,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          ),
                          error: (_, __) => Text(
                            'Health Guardian',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/profile'),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.cyanAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            _showLogoutDialog(context, ref);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                _buildNavCard(
                  context,
                  title: 'AI Assistant',
                  subtitle: 'Ask about your health',
                  icon: Icons.chat_bubble_outline,
                  color: Colors.cyanAccent,
                  onTap: () => context.push('/chatbot'),
                ),
                const SizedBox(height: 20),
                _buildNavCard(
                  context,
                  title: 'Glucose Prediction',
                  subtitle: 'Monitor & Forecast',
                  icon: Icons.show_chart,
                  color: Colors.purpleAccent,
                  onTap: () => context.push('/prediction'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/emergency-onboarding'),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text(
          'EMERGENCY',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GlassContainer(
        blur: 10,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        borderRadius: BorderRadius.circular(20),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.redAccent, size: 30),
              const SizedBox(width: 10),
              Text('CRITICAL ALERT', style: GoogleFonts.outfit(color: Colors.redAccent)),
            ],
          ),
          content: Text(
            'Simulating Drone Dispatch...\n\nSending coordinates to Emergency Response Center.',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
              child: Text('CONFIRM', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => GlassContainer(
        blur: 10,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        borderRadius: BorderRadius.circular(20),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: Text(
            'Log Out',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(context);
                ref.read(authServiceProvider).signOut();
              },
              child: Text('LOG OUT', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      height: 140,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
