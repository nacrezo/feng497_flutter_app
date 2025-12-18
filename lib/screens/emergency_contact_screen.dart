import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import '../services/auth_service.dart';

class EmergencyContactScreen extends ConsumerStatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  ConsumerState<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends ConsumerState<EmergencyContactScreen> {
  final _contactPicker = FlutterNativeContactPicker();
  bool _isLoading = false;

  Future<void> _pickAndAddContact() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null) {
        String? number;
        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
           number = contact.phoneNumbers!.first;
        }

        if (number != null) {
           setState(() => _isLoading = true);
           // Sanitize number if needed, but keeping raw for now
           await ref.read(authServiceProvider).addEmergencyContact(contact.fullName ?? 'Unknown', number);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact: $e', style: GoogleFonts.outfit())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeContact(String name, String number) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).removeEmergencyContact(name, number);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error removing contact: $e', style: GoogleFonts.outfit())),
        );
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onContinue() {
    // Check if we have contacts? The button should be disabled if not.
    // Logic for back/home
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (context.canPop()) 
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(), 
                      icon: const Icon(Icons.arrow_back, color: Colors.white)
                    ),
                  ),
                const SizedBox(height: 10),
                Icon(
                  Icons.contact_phone,
                  size: 60,
                  color: Colors.cyanAccent.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  'Emergency Contacts',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage your trusted contacts for emergency situations.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Contacts List
                Expanded(
                  child: userProfileAsync.when(
                    data: (data) {
                      final List<dynamic> rawContacts = data?['emergencyContacts'] ?? [];
                      // Legacy support
                      if (rawContacts.isEmpty && data?['emergencyContactNumber'] != null) {
                         // If we have legacy data, show it. Ideally we should migrate it.
                         // For now, let's treat it as "no contacts" for the list, 
                         // but maybe we should auto-migrate? 
                         // Let's just encourage user to add new ones.
                      }
                      
                      final contacts = rawContacts.map((e) => Map<String, String>.from(e as Map)).toList();

                      if (contacts.isEmpty) {
                        return Center(
                          child: Text(
                            'No contacts added yet.',
                            style: GoogleFonts.outfit(color: Colors.white54, fontStyle: FontStyle.italic),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: contacts.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return GlassContainer(
                            borderRadius: BorderRadius.circular(16),
                            blur: 10,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Colors.cyanAccent),
                              ),
                              title: Text(
                                contact['name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                contact['number'] ?? '',
                                style: GoogleFonts.outfit(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: _isLoading 
                                  ? null 
                                  : () => _removeContact(contact['name']!, contact['number']!),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    error: (e, s) => Center(child: Text('Error loading contacts', style: GoogleFonts.outfit(color: Colors.red))),
                  ),
                ),

                const SizedBox(height: 20),

                // Add Contact Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickAndAddContact,
                    icon: const Icon(Icons.add, color: Colors.cyanAccent),
                    label: Text(
                      'ADD CONTACT',
                      style: GoogleFonts.outfit(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: userProfileAsync.value != null && 
                               (userProfileAsync.value!['emergencyContacts'] as List?)?.isNotEmpty == true &&
                               !_isLoading
                        ? _onContinue 
                        : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
