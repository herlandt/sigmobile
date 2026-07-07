// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/services/recorrido_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarServicioRecorrido();
  runApp(const ProviderScope(child: MicrobusesApp()));
}
