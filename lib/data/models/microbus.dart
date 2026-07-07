// lib/data/models/microbus.dart

class MicrobusFoto {
  final String fotoUrl;
  final int orden;
  const MicrobusFoto({required this.fotoUrl, required this.orden});

  factory MicrobusFoto.fromJson(Map<String, dynamic> j) => MicrobusFoto(
        fotoUrl: j['foto_url'] as String,
        orden: (j['orden'] as num).toInt(),
      );
}

class Microbus {
  final String id;
  final String placa;
  final String modelo;
  final int cantidadAsientos;
  final String lineaId;
  final String numeroInterno;
  final String fechaAsignacion;
  final String? fechaBaja;
  final List<MicrobusFoto> fotos;

  const Microbus({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.cantidadAsientos,
    required this.lineaId,
    required this.numeroInterno,
    required this.fechaAsignacion,
    required this.fotos,
    this.fechaBaja,
  });

  factory Microbus.fromJson(Map<String, dynamic> j) => Microbus(
        id: j['id'] as String,
        placa: j['placa'] as String,
        modelo: j['modelo'] as String,
        cantidadAsientos: (j['cantidad_asientos'] as num).toInt(),
        lineaId: j['linea_id'] as String,
        numeroInterno: j['numero_interno'] as String,
        fechaAsignacion: j['fecha_asignacion'] as String,
        fechaBaja: j['fecha_baja'] as String?,
        fotos: ((j['fotos'] as List?) ?? const [])
            .map((f) => MicrobusFoto.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  bool get activo => fechaBaja == null;
  String? get primeraFotoUrl => fotos.isNotEmpty ? fotos.first.fotoUrl : null;
}
