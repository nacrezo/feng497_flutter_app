import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _sexController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await ref.read(authServiceProvider).signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      } else {
        if (_nameController.text.isEmpty ||
            _ageController.text.isEmpty ||
            _bloodTypeController.text.isEmpty ||
            _sexController.text.isEmpty) {
          throw Exception('Please fill in all fields');
        }
        
        await ref.read(authServiceProvider).signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              bloodType: _bloodTypeController.text.trim(),
              sex: _sexController.text.trim(),
            );
      }
      // Navigation is handled by the router listener in main.dart
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password. Please try again.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered. Please sign in instead.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please choose a stronger one.';
          break;
        default:
          message = 'An error occurred. Please try again later.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: Colors.cyanAccent.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  'Diabetes Manager',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI-Powered Health Companion',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 50),
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  blur: 10,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.outfit(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: GoogleFonts.outfit(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.cyanAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    labelStyle: GoogleFonts.outfit(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.cyanAccent),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.cyanAccent),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _sexController,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Sex',
                                    labelStyle: GoogleFonts.outfit(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.male, color: Colors.cyanAccent),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.cyanAccent),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _bloodTypeController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Blood Type (e.g. A+)',
                              labelStyle: GoogleFonts.outfit(color: Colors.white70),
                              prefixIcon: const Icon(Icons.bloodtype, color: Colors.cyanAccent),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.cyanAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextField(
                          controller: _emailController,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: GoogleFonts.outfit(color: Colors.white70),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.cyanAccent),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.outfit(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyanAccent),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                              style: ButtonStyle(
                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.purpleAccent.withOpacity(0.1);
                                    }
                                    return null;
                                  },
                                ),
                                foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.purpleAccent;
                                    }
                                    return Colors.cyanAccent;
                                  },
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Register' : 'Sign In',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
