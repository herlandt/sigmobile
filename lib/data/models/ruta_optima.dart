// lib/data/models/ruta_optima.dart
import 'package:latlong2/latlong.dart';

class ParadaEnRuta {
  final int? idPunto;
  final String? descripcion;
  final double longitud;
  final double latitud;

  const ParadaEnRuta({
    this.idPunto,
    this.descripcion,
    required this.longitud,
    required this.latitud,
  });

  factory ParadaEnRuta.fromJson(Map<String, dynamic> j) => ParadaEnRuta(
        idPunto: j['id_punto'] as int?,
        descripcion: j['descripcion'] as String?,
        longitud: (j['longitud'] as num).toDouble(),
        latitud: (j['latitud'] as num).toDouble(),
      );

  LatLng get coordenadas => LatLng(latitud, longitud);
}

class TramoRuta {
  final String tipo; // 'linea' (micro) | 'caminata' (a pie)
  final String lineaNumero;
  final String sentido;
  final double tiempoSeg;
  final double distanciaM;
  final double esperaMin; // espera del próximo micro antes de subir (tipo='linea')
  final List<ParadaEnRuta> paradas;

  const TramoRuta({
    required this.tipo,
    required this.lineaNumero,
    required this.sentido,
    required this.tiempoSeg,
    required this.distanciaM,
    required this.esperaMin,
    required this.paradas,
  });

  factory TramoRuta.fromJson(Map<String, dynamic> j) => TramoRuta(
        tipo: j['tipo'] as String? ?? 'linea',
        lineaNumero: j['linea_numero'] as String,
        sentido: j['sentido'] as String? ?? '',
        tiempoSeg: (j['tiempo_seg'] as num).toDouble(),
        distanciaM: (j['distancia_m'] as num).toDouble(),
        esperaMin: (j['espera_min'] as num?)?.toDouble() ?? 0.0,
        paradas: (j['paradas'] as List)
            .map((p) => ParadaEnRuta.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  bool get esCaminata => tipo == 'caminata';

  List<LatLng> get puntos => paradas.map((p) => p.coordenadas).toList();
}

class RutaOptima {
  final double tiempoTotalSeg;
  final double tiempoTotalMin;
  final double distanciaTotalM;
  final int transbordos;
  final double caminataOrigenM;
  final double caminataDestinoM;
  final double esperaTotalMin;
  final double frecuenciaMin;
  final bool enServicio;
  final List<TramoRuta> tramos;

  const RutaOptima({
    required this.tiempoTotalSeg,
    required this.tiempoTotalMin,
    required this.distanciaTotalM,
    required this.transbordos,
    required this.caminataOrigenM,
    required this.caminataDestinoM,
    required this.esperaTotalMin,
    required this.frecuenciaMin,
    required this.enServicio,
    required this.tramos,
  });

  factory RutaOptima.fromJson(Map<String, dynamic> j) => RutaOptima(
        tiempoTotalSeg: (j['tiempo_total_seg'] as num).toDouble(),
        tiempoTotalMin: (j['tiempo_total_min'] as num).toDouble(),
        distanciaTotalM: (j['distancia_total_m'] as num).toDouble(),
        transbordos: (j['transbordos'] as num).toInt(),
        caminataOrigenM: (j['caminata_origen_m'] as num).toDouble(),
        caminataDestinoM: (j['caminata_destino_m'] as num).toDouble(),
        esperaTotalMin: (j['espera_total_min'] as num?)?.toDouble() ?? 0.0,
        frecuenciaMin: (j['frecuencia_min'] as num?)?.toDouble() ?? 15.0,
        enServicio: j['en_servicio'] as bool? ?? true,
        tramos: (j['tramos'] as List)
            .map((t) => TramoRuta.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
