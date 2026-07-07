// lib/shared/providers/microbus_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/microbus.dart';
import 'auth_provider.dart';

/// Microbuses del conductor autenticado (GET /microbuses/mis-microbuses).
final misMicrobusesProvider = FutureProvider.autoDispose<List<Microbus>>(
  (ref) async {
    final api = ref.read(apiServiceConductorProvider);
    return api.getMisMicrobuses();
  },
);
