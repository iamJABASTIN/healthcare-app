import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- State Variables ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userRole;
  String? get userRole => _userRole; // 'patient' or 'doctor'

  bool _isVerified = false;
  bool get isVerified => _isVerified; // To lock out unverified doctors

  // --- SIGN UP (Register) ---
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // User selects this in UI
  }) async {
    _setLoading(true);
    try {
      // 1. Create Auth User in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Determine Verification Status
        // Patients are auto-verified. Doctors are NOT (require admin approval).
        bool isVerifiedStatus = (role == 'patient');

        // 3. Create Base User Document (Lightweight - for Login checks)
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          role: role,
          isVerified: isVerifiedStatus,
        );

        // Write to the central 'users' collection
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // 4. BRANCHING LOGIC: Create Specific Profile Document
        if (role == 'patient') {
          // Create Patient Profile in 'patients' collection
          await _firestore.collection('patients').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'createdAt': DateTime.now().toIso8601String(),
            // We will add medical history fields here later
          });
        } else if (role == 'doctor') {
          // Create Doctor Profile in 'doctors' collection
          await _firestore.collection('doctors').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'specialization': 'General', // Default placeholder
            'status':
                'pending_approval', // Admin must change this to 'approved'
            'createdAt': DateTime.now().toIso8601String(),
          });
        }

        // Update local state
        _userRole = role;
        _isVerified = isVerifiedStatus;

        return null; // Returning null indicates Success
      }
    } on FirebaseAuthException catch (e) {
      return e.message; // Return specific Firebase error
    } catch (e) {
      return "An unknown error occurred";
    } finally {
      _setLoading(false);
    }
    return "Registration failed";
  }

  // --- SIGN IN (Login) ---
  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      // 1. Authenticate with Email/Password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch User Role & Verification from Firestore 'users' collection
      if (result.user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (doc.exists) {
          // Convert Firestore data to our Map
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Store valuable info in the ViewModel state
          _userRole = data['role'];
          _isVerified = data['isVerified'] ?? false;

          notifyListeners(); // Notify UI to update
          return null; // Success
        } else {
          return "User data not found in database";
        }
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred during login";
    } finally {
      _setLoading(false);
    }
    return "Login failed";
  }

  // --- Initialize from existing Firebase auth session ---
  /// Call this on app start to populate the view model from a cached Firebase user
  Future<void> loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userRole = data['role'] as String?;
        _isVerified = data['isVerified'] ?? false;
      }
    } catch (e) {
      // ignore - keep defaults
    } finally {
      _setLoading(false);
    }
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = null;
    _isVerified = false;
    notifyListeners();
  }

  // --- Helper to update Loading State ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
