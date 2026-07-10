import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ─── Service Providers ───────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// ─── Auth State ──────────────────────────────────────────────────

/// Stream of Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// ─── Current User Model ──────────────────────────────────────────

/// Stream the current user's Firestore doc (role, etc.)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(firestoreServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Auth Actions ────────────────────────────────────────────────

/// Provider for sign-in action
final signInProvider = FutureProvider.family<void, void>((ref, _) async {
  final authService = ref.read(authServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  final credential = await authService.signInWithGoogle();
  if (credential?.user != null) {
    final user = credential!.user!;
    await firestoreService.createUserIfNotExists(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoURL: user.photoURL ?? '',
    );
  }
});
