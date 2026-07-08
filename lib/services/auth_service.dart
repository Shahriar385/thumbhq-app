import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as all_platforms;
import 'package:google_sign_in/google_sign_in.dart' as native;

/// Auth service using Firebase Auth directly for Google sign-in on web.
/// Now uses official google_sign_in for macOS/Mobile, and google_sign_in_all_platforms for Windows.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  all_platforms.GoogleSignIn? _desktopGoogleSignIn;
  native.GoogleSignIn? _nativeGoogleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google using Firebase Auth popup (web), native plugin (macOS/Mobile), or custom server (Windows)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
        _desktopGoogleSignIn ??= all_platforms.GoogleSignIn(
          params: all_platforms.GoogleSignInParams(
            clientId: '14892257053-o4kbbss2thobcbijg7nmmvi1lolfdt97.apps.googleusercontent.com',
            clientSecret: '',
            redirectPort: 8080,
          ),
        );
        final credentials = await _desktopGoogleSignIn!.signIn();
        if (credentials == null) return null;
        
        final authCredential = GoogleAuthProvider.credential(
          accessToken: credentials.accessToken,
          idToken: credentials.idToken,
        );
        return await _auth.signInWithCredential(authCredential);
      } else {
        _nativeGoogleSignIn ??= native.GoogleSignIn();
        final native.GoogleSignInAccount? account = await _nativeGoogleSignIn!.signIn();
        if (account == null) return null;

        final native.GoogleSignInAuthentication auth = account.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        return await _auth.signInWithCredential(authCredential);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
        await _desktopGoogleSignIn?.signOut();
      } else {
        await _nativeGoogleSignIn?.signOut();
      }
    }
    await _auth.signOut();
  }
}
