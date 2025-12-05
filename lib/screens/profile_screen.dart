import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

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
          child: Column(
            children: [
              // AppBar-like Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'My Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Profile Content
              Expanded(
                child: userProfileAsync.when(
                  data: (data) {
                    if (data == null) {
                      return Center(
                        child: Text(
                          'No profile data found.',
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar Placeholder
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.cyanAccent, width: 2),
                            ),
                            child: const Icon(Icons.person, size: 50, color: Colors.cyanAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['name'] ?? 'User',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            data['email'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Info Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Age',
                                  '${data['age'] ?? '-'}',
                                  Icons.calendar_today,
                                  Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoCard(
                                  'Sex',
                                  data['sex'] ?? '-',
                                  (data['sex'] == 'Female') ? Icons.female : Icons.male,
                                  (data['sex'] == 'Female') ? Colors.pinkAccent : Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            'Blood Type',
                            data['bloodType'] ?? '-',
                            Icons.bloodtype,
                            Colors.redAccent,
                          ),

                          const SizedBox(height: 40),
                          
                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                _showLogoutDialog(context, ref);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.2),
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'LOG OUT',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading profile',
                      style: GoogleFonts.outfit(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
