import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sepadan/models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '20264636038-dh25104sket6bje7de2da3a057d9nsj9.apps.googleusercontent.com',
  );

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
        'phoneNumber': user.phoneNumber ?? '', // 🔥 Fix: Save phone number if available
        'isAdmin': false,
        'isPremium': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 🔥 Fix: Update phone number if it's missing in existing doc
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
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
      await ensureUserDocument(user);
      return _getUserProfile(user.uid);
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
      try { await _googleSignIn.signOut(); } catch (_) {}

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
    } catch (e) {
      print("Google Sign-In Error: $e");
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
      verificationFailed: verificationFailed,
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
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _auth.signOut();
  }
}
