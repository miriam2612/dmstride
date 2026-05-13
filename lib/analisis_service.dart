import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalisisService {
  // Cambia esta IP por la de tu computadora en la red WiFi
  static const String _baseUrl = 'http://10.43.104.222:8000';

  static Future<Map<String, dynamic>?> analizarImagen({
    required String imagenBase64,
    required String usuarioId,
    required String fotoId,
  }) async {
    try {
      // 1. Mandar imagen a FastAPI
      final response = await http.post(
        Uri.parse('$_baseUrl/analizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imagenBase64': imagenBase64}),
      );

      if (response.statusCode == 200) {
        final resultado = jsonDecode(response.body);

        // 2. Guardar resultados en Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioId)
            .collection('fotos')
            .doc(fotoId)
            .update({
          'analisis': {
            'enrojecimiento_pct': resultado['enrojecimiento_pct'],
            'zona_palida_pct': resultado['zona_palida_pct'],
            'contornos_detectados': resultado['contornos_detectados'],
            'nivel_riesgo': resultado['nivel_riesgo'],
            'imagen_anotada_base64': resultado['imagen_anotada_base64'],
            'fecha_analisis': DateTime.now().toIso8601String(),
          }
        });

        return resultado;
      }
    } catch (e) {
      print('Error en análisis: $e');
    }
    return null;
  }
}