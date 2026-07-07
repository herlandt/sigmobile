// lib/shared/utils/polilinea_offset.dart
import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Desplaza una polilínea perpendicularmente (a su DERECHA según el sentido de
/// avance) por [metros]. Sirve para que el recorrido de ida y el de vuelta se
/// vean como dos líneas paralelas y no se superpongan cuando comparten la calle.
List<LatLng> desplazarDerecha(List<LatLng> pts, double metros) {
  if (pts.length < 2 || metros == 0) return pts;
  final out = <LatLng>[];
  for (var i = 0; i < pts.length; i++) {
    final a = i == 0 ? pts[0] : pts[i - 1];
    final b = i == 0 ? pts[1] : pts[i];
    final perp = _bearing(a, b) + 90.0; // perpendicular hacia la derecha
    out.add(_mover(pts[i], metros, perp));
  }
  return out;
}

/// Desplaza [propia] a su derecha SOLO en los tramos donde corre pegada a
/// [otra] (misma calle, doble sentido). Donde van por calles distintas (una
/// avenida de un sentido y su par por otra calle), deja la geometría intacta
/// para no sacarla de su avenida real. Así se separan las dos manos cuando
/// comparten calle, sin montarse sobre las casas, y los pares de un sentido
/// quedan correctos.
List<LatLng> desplazarSiSolapa(
  List<LatLng> propia,
  List<LatLng> otra,
  double metros, {
  double umbralM = 25,
}) {
  if (propia.length < 2 || metros == 0) return propia;
  if (otra.length < 2) return propia; // sin par => nada que separar
  final out = <LatLng>[];
  for (var i = 0; i < propia.length; i++) {
    final a = i == 0 ? propia[0] : propia[i - 1];
    final b = i == 0 ? propia[1] : propia[i];
    if (_distAPolilinea(propia[i], otra) <= umbralM) {
      final perp = _bearing(a, b) + 90.0; // perpendicular a la derecha
      out.add(_mover(propia[i], metros, perp));
    } else {
      out.add(propia[i]); // van por calles distintas => no tocar
    }
  }
  return out;
}

/// Distancia mínima (m) de un punto a una polilínea.
double _distAPolilinea(LatLng p, List<LatLng> linea) {
  var best = double.infinity;
  for (var i = 0; i < linea.length - 1; i++) {
    final d = _distAPuntoSegmento(p, linea[i], linea[i + 1]);
    if (d < best) best = d;
  }
  return best;
}

/// Distancia (m) punto→segmento con proyección equirectangular local
/// (suficiente para distancias cortas a esta latitud).
double _distAPuntoSegmento(LatLng p, LatLng a, LatLng b) {
  const mPorGradoLat = 110540.0;
  final mPorGradoLon = 111320.0 * cos(p.latitude * pi / 180);
  double px = p.longitude * mPorGradoLon, py = p.latitude * mPorGradoLat;
  double ax = a.longitude * mPorGradoLon, ay = a.latitude * mPorGradoLat;
  double bx = b.longitude * mPorGradoLon, by = b.latitude * mPorGradoLat;
  final dx = bx - ax, dy = by - ay;
  final largo2 = dx * dx + dy * dy;
  var t = largo2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / largo2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  final ex = px - cx, ey = py - cy;
  return sqrt(ex * ex + ey * ey);
}

double _bearing(LatLng a, LatLng b) {
  final lat1 = a.latitude * pi / 180, lat2 = b.latitude * pi / 180;
  final dlon = (b.longitude - a.longitude) * pi / 180;
  final y = sin(dlon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dlon);
  return atan2(y, x) * 180 / pi;
}

LatLng _mover(LatLng p, double metros, double bearingDeg) {
  const r = 6371000.0;
  final br = bearingDeg * pi / 180;
  final lat1 = p.latitude * pi / 180, lon1 = p.longitude * pi / 180;
  final dr = metros / r;
  final lat2 = asin(sin(lat1) * cos(dr) + cos(lat1) * sin(dr) * cos(br));
  final lon2 =
      lon1 + atan2(sin(br) * sin(dr) * cos(lat1), cos(dr) - sin(lat1) * sin(lat2));
  return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
}
