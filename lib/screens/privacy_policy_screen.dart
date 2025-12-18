import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import to access privacyPolicyProvider

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  bool _isAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptPolicy() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_policy_accepted', true);
    
    // Update the global provider state
    ref.read(privacyPolicyProvider.notifier).state = true;
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Navigate to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 20),
                Icon(
                  Icons.policy,
                  size: 60,
                  color: Colors.cyanAccent.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  'Privacy Policy & Liability Waiver',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                 Text(
                  'Please read and accept the terms before continuing.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blur: 10,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            '1. Data Privacy',
                            'We collect personal health data (glucose levels), location data, and contact information solely for the purpose of providing emergency medical supply delivery. Your data is stored securely and shared only with emergency services or drone operators when a critical situation is detected.',
                          ),
                          _buildSection(
                            '2. Location Tracking',
                            'To deliver supplies via drone, we require access to your real-time location. This tracking is only active during emergency dispatch or when users explicitly enable it.',
                          ),
                          _buildSection(
                            '3. Emergency Response Limitation',
                            'This application is an assistive tool and does not replace professional medical advice or 911 services. Drones are subject to weather conditions, battery life, and technical limitations.',
                          ),
                          _buildSection(
                            '4. Liability Waiver',
                            'By using this app, you acknowledge that we are not liable for any delays in delivery, technical failures, or health complications that may arise. Users are responsible for maintaining their own emergency plans.',
                          ),
                           _buildSection(
                            '5. Contact Information',
                            'You agree to provide accurate phone numbers for yourself and an emergency contact. You authorize us to contact these numbers in case of an emergency.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                   borderRadius: BorderRadius.circular(20),
                    blur: 10,
                     border: Border.all(color: Colors.white.withOpacity(0.2)),
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       child: Row(
                        children: [
                          Checkbox(
                            value: _isAccepted,
                            activeColor: Colors.cyanAccent,
                            checkColor: Colors.black,
                            side: BorderSide(color: Colors.white70),
                            onChanged: (value) {
                              setState(() {
                                _isAccepted = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'I have read and agree to the Privacy Policy and Liability Waiver.',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                                           ),
                     ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isAccepted && !_isLoading ? _acceptPolicy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'CONTINUE',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
