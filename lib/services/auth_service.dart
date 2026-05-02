// ============================================================
// 📁 lib/services/auth_service.dart
// ✅ UPDATED: Clear profile cache on signOut
// ============================================================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sepadan/models/user_profile.dart';
import 'package:sepadan/core/app_router.dart'; // 🔥 Import for clearProfileCache

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hapus serverClientId manual untuk membiarkan SDK menggunakan google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ================= USER DOCUMENT ENSURE =================

  Future<void> ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'isAdmin': false,
        'isPremium': false,
        'isSuspended': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      
      if (data != null && data['isSuspended'] == true) {
        await signOut();
        throw FirebaseAuthException(
          code: 'suspended',
          message: 'Account suspended. Contact support.',
        );
      }

      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        if (data != null && (data['phoneNumber'] == null || data['phoneNumber'] == '')) {
          await docRef.update({'phoneNumber': user.phoneNumber});
        }
      }
    }
  }

  // ================= GET USER PROFILE =================

  Future<UserProfile?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getUserProfile(user.uid);
  }

  Stream<UserProfile?> get userProfileStream {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      try {
        await ensureUserDocument(user);
        return _getUserProfile(user.uid);
      } catch (e) {
        return null;
      }
    });
  }

  Future<UserProfile?> _getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return UserProfile.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }

  // ================= GOOGLE SIGN IN =================

  Future<User?> signInWithGoogle() async {
    try {
      // Membersihkan session sebelumnya untuk memaksa picker akun muncul
      await _googleSignIn.signOut().catchError((_) => null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await ensureUserDocument(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Google Auth Firebase Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Google Sign-In General Error: $e");
      rethrow;
    }
  }

  // ================= EMAIL SIGN IN =================

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await ensureUserDocument(user);
    }

    return user;
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await ensureUserDocument(user);
    }

    return user;
  }

  // ================= PHONE AUTH =================

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: (e) {
        print("Phone Auth Error: ${e.code} - ${e.message}");
        verificationFailed(e);
      },
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<User?> signInWithPhoneNumber(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final cred = await _auth.signInWithCredential(credential);

    final user = cred.user;
    if (user != null) {
      await ensureUserDocument(user);
    }

    return user;
  }

  // ================= SIGN OUT =================

  Future<void> signOut() async {
    // 🔥 Clear profile cache before signing out
    await clearProfileCache();
    
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }
}
