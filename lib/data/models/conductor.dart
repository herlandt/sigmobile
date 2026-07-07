// lib/data/models/conductor.dart

class Conductor {
  final String id;
  final String documentoIdentidad;
  final String nombre;
  final String fechaNacimiento; // ISO date "YYYY-MM-DD"
  final String sexo;
  final String telefono;
  final String email;
  final String categoriaLicencia;
  final String fotoUrl;
  final bool activo;

  const Conductor({
    required this.id,
    required this.documentoIdentidad,
    required this.nombre,
    required this.fechaNacimiento,
    required this.sexo,
    required this.telefono,
    required this.email,
    required this.categoriaLicencia,
    required this.fotoUrl,
    required this.activo,
  });

  factory Conductor.fromJson(Map<String, dynamic> j) => Conductor(
        id: j['id'] as String,
        documentoIdentidad: j['documento_identidad'] as String,
        nombre: j['nombre'] as String,
        fechaNacimiento: j['fecha_nacimiento'] as String,
        sexo: j['sexo'] as String,
        telefono: j['telefono'] as String,
        email: j['email'] as String,
        categoriaLicencia: j['categoria_licencia'] as String,
        fotoUrl: j['foto_url'] as String,
        activo: j['activo'] as bool,
      );
}
