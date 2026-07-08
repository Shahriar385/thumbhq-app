import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_model.dart';
import 'auth_provider.dart';

final projectMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, projectId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamProjectMessages(projectId);
});
