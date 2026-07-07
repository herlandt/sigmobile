// lib/data/models/recorrido.dart

class RecorridoIniciado {
  final String recorridoId;
  final String microbusId;
  final String lineaId;
  final String sentido;
  final String fechaInicio;

  const RecorridoIniciado({
    required this.recorridoId,
    required this.microbusId,
    required this.lineaId,
    required this.sentido,
    required this.fechaInicio,
  });

  factory RecorridoIniciado.fromJson(Map<String, dynamic> j) => RecorridoIniciado(
        recorridoId: j['recorrido_id'] as String,
        microbusId: j['microbus_id'] as String,
        lineaId: j['linea_id'] as String,
        sentido: j['sentido'] as String,
        fechaInicio: j['fecha_inicio'] as String,
      );
}

class RecorridoResumen {
  final String sentido;
  final String? fechaFin;
  final String? tipoFinalizacion;
  final double? distanciaTotalKm;
  final int? tiempoTotalSeg;
  final String? motivoSalida;

  const RecorridoResumen({
    required this.sentido,
    this.fechaFin,
    this.tipoFinalizacion,
    this.distanciaTotalKm,
    this.tiempoTotalSeg,
    this.motivoSalida,
  });

  factory RecorridoResumen.fromJson(Map<String, dynamic> j) => RecorridoResumen(
        sentido: j['sentido'] as String,
        fechaFin: j['fecha_fin'] as String?,
        tipoFinalizacion: j['tipo_finalizacion'] as String?,
        distanciaTotalKm: (j['distancia_total_km'] as num?)?.toDouble(),
        tiempoTotalSeg: (j['tiempo_total_seg'] as num?)?.toInt(),
        motivoSalida: j['motivo_salida'] as String?,
      );
}
