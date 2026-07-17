import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleInitialized) return;

    if (kIsWeb) {
      await _googleSignIn.initialize(
        clientId: '837187985882-fhc4m8i1pjljd50le64p8q4nps03h942.apps.googleusercontent.com',
      );
    } else {
      await _googleSignIn.initialize();
    }

    _isGoogleInitialized = true;
  }

  AuthService() {
    _initializeGoogleSignIn();
    _googleSignIn.authenticationEvents.listen((event) async {
      final GoogleSignInAccount? user = switch (event) {
        GoogleSignInAuthenticationEventSignIn(:final user) => user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };

      if (user != null && kIsWeb) {
        try {
          final GoogleSignInAuthentication googleAuth = user.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );
          await _firebaseAuth.signInWithCredential(credential);
        } catch (e) {
          debugPrint("Firebase Google sign-in stream error: $e");
        }
      }
    });
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> loginWithGoogle() async {
    await _initializeGoogleSignIn();

    try {
      final googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _initializeGoogleSignIn();

    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<String?> getIdToken() async {
    return _firebaseAuth.currentUser?.getIdToken();
  }

  // --- NEW STATIC METHODS FOR USER_REQUEST ---
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _staticGoogleSignIn = GoogleSignIn.instance;
  static bool _staticIsGoogleInitialized = false;

  static Future<void> _staticInitializeGoogleSignIn() async {
    if (_staticIsGoogleInitialized) return;
    if (kIsWeb) {
      await _staticGoogleSignIn.initialize(
        clientId: '837187985882-fhc4m8i1pjljd50le64p8q4nps03h942.apps.googleusercontent.com',
      );
    } else {
      await _staticGoogleSignIn.initialize();
    }
    _staticIsGoogleInitialized = true;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await _staticInitializeGoogleSignIn();
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _staticGoogleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _staticInitializeGoogleSignIn();
      await _staticGoogleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error in signOut: $e');
    }
  }
}