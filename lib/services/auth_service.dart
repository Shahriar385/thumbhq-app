import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

/// Auth service using Firebase Auth directly for Google sign-in on web.
/// Now includes desktop support via google_sign_in_all_platforms.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google using Firebase Auth popup (web-native) or system browser (desktop)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        _googleSignIn ??= GoogleSignIn(
          params: GoogleSignInParams(
            clientId: '14892257053-o4kbbss2thobcbijg7nmmvi1lolfdt97.apps.googleusercontent.com',
            clientSecret: '',
            redirectPort: 8080,
          ),
        );
        final credentials = await _googleSignIn!.signIn();
        if (credentials == null) return null;
        
        final authCredential = GoogleAuthProvider.credential(
          accessToken: credentials.accessToken,
          idToken: credentials.idToken,
        );
        return await _auth.signInWithCredential(authCredential);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    await _auth.signOut();
  }
}
