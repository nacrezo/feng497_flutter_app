import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password and save user data
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String bloodType,
    required String sex,
  }) async {
    // 1. Create user in Auth
    final userCredential = await _auth
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Connection timed out. Please check your internet.',
      );
    });

    // 2. Create user document in Firestore
    if (userCredential.user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'age': age,
        'bloodType': bloodType,
        'sex': sex,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    int? age,
    String? bloodType,
    String? sex,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (age != null) updateData['age'] = age;
    if (bloodType != null) updateData['bloodType'] = bloodType;
    if (sex != null) updateData['sex'] = sex;
    if (emergencyContacts != null) updateData['emergencyContacts'] = emergencyContacts;
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updateData);
  }

  // Add an emergency contact
  Future<void> addEmergencyContact(String name, String number) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'emergencyContacts': FieldValue.arrayUnion([
        {'name': name, 'number': number}
      ])
    });
  }

  // Remove an emergency contact
  Future<void> removeEmergencyContact(String name, String number) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'emergencyContacts': FieldValue.arrayRemove([
        {'name': name, 'number': number}
      ])
    });
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user != null) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
  return Stream.value(null);
});
