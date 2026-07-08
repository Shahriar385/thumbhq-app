import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ─── All Users Stream (for team management) ──────────────────────

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamAllUsers();
});

// ─── Users by Role ───────────────────────────────────────────────

final strategistsProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  return usersAsync.whenData(
    (users) => users.where((u) => u.isStrategist).toList(),
  );
});

final designersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  return usersAsync.whenData(
    (users) => users.where((u) => u.isDesigner).toList(),
  );
});

final pendingUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  return usersAsync.whenData(
    (users) => users.where((u) => u.isPending).toList(),
  );
});
