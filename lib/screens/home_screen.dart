import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

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
