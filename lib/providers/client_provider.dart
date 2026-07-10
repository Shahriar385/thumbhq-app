import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/client_model.dart';
import 'auth_provider.dart';

final clientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamClients();
});

final selectedClientTabProvider = StateProvider<ClientStatus>((ref) => ClientStatus.active);

final filteredClientsProvider = Provider<AsyncValue<List<ClientModel>>>((ref) {
  final clientsAsync = ref.watch(clientsProvider);
  final selectedTab = ref.watch(selectedClientTabProvider);

  return clientsAsync.whenData(
    (clients) => clients.where((c) => c.status == selectedTab).toList(),
  );
});
