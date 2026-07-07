// lib/app/routes.dart
import 'package:go_router/go_router.dart';

import '../data/models/linea.dart';
import '../features/usuario/recorrido_linea/pantalla_lista_lineas.dart';
import '../features/usuario/recorrido_linea/pantalla_selector_sentido.dart';
import '../features/usuario/recorrido_linea/pantalla_mapa_recorrido.dart';
import '../features/usuario/esperando_microbus/pantalla_selector_linea_espera.dart';
import '../features/usuario/esperando_microbus/pantalla_esperando_microbus.dart';
import '../features/usuario/ruta_optima/pantalla_ruta_optima.dart';
import '../features/usuario/lineas_cercanas/pantalla_lineas_cercanas.dart';
import '../features/conductor/auth/pantalla_login_conductor.dart';
import '../features/conductor/auth/pantalla_registro_conductor.dart';
import '../features/conductor/pantalla_home_conductor.dart';
import '../features/conductor/microbus/pantalla_mis_microbuses.dart';
import '../features/conductor/microbus/pantalla_registro_microbus.dart';
import '../features/conductor/recorrido/pantalla_iniciar_recorrido.dart';
import '../features/conductor/recorrido/pantalla_recorrido_activo.dart';

final router = GoRouter(
  initialLocation: '/usuario',
  routes: [
    GoRoute(
      path: '/usuario',
      builder: (_, __) => const PantallaListaLineas(),
    ),
    GoRoute(
      path: '/usuario/recorrido/:lineaId',
      builder: (context, state) {
        final linea = state.extra as LineaResumen?;
        if (linea == null) return const PantallaListaLineas();
        return PantallaSelectorSentido(linea: linea);
      },
    ),
    GoRoute(
      path: '/usuario/mapa/:lineaId',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const PantallaListaLineas();
        return PantallaMapaRecorrido(
          lineaId: state.pathParameters['lineaId']!,
          sentido: extra['sentido'] as String,
          lineaNombre: extra['nombre'] as String,
        );
      },
    ),
    GoRoute(
      path: '/usuario/ruta-optima',
      builder: (_, __) => const PantallaRutaOptima(),
    ),
    GoRoute(
      path: '/usuario/lineas-cercanas',
      builder: (_, __) => const PantallaLineasCercanas(),
    ),
    GoRoute(
      path: '/usuario/esperando',
      builder: (_, __) => const PantallaSelectorLineaEspera(),
    ),
    GoRoute(
      path: '/usuario/esperando/:lineaId',
      builder: (context, state) {
        final linea = state.extra as LineaResumen?;
        if (linea == null) return const PantallaSelectorLineaEspera();
        return PantallaEsperandoMicrobus(linea: linea);
      },
    ),

    // ── Conductor ──────────────────────────────────────────────
    GoRoute(
      path: '/conductor/login',
      builder: (_, __) => const PantallaLoginConductor(),
    ),
    GoRoute(
      path: '/conductor',
      builder: (_, __) => const PantallaHomeConductor(),
    ),
    GoRoute(
      path: '/conductor/registro',
      builder: (_, __) => const PantallaRegistroConductor(),
    ),
    GoRoute(
      path: '/conductor/microbuses',
      builder: (_, __) => const PantallaMisMicrobuses(),
    ),
    GoRoute(
      path: '/conductor/microbuses/nuevo',
      builder: (_, __) => const PantallaRegistroMicrobus(),
    ),
    GoRoute(
      path: '/conductor/recorrido',
      builder: (_, __) => const PantallaIniciarRecorrido(),
    ),
    GoRoute(
      path: '/conductor/recorrido/activo',
      builder: (_, __) => const PantallaRecorridoActivo(),
    ),
  ],
);
