// lib/services/analisis_service.dart
//
// Servicio responsable de enviar una imagen (en Base64) a la API
// DM-Stride y devolver el resultado del análisis preliminar.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'resultado_analisis.dart';

class AnalisisService {
  static const String _baseUrl = 'https://dm-stride-api.onrender.com';
  static const String _predictPath = '/predict';

  /// Convierte un String Base64 (con o sin encabezado `data:image/...;base64,`)
  /// a un arreglo de bytes utilizable por la app.
  static Uint8List imageBytesFromBase64(String base64String) {
    final cleanBase64 =
        base64String.contains(',') ? base64String.split(',').last : base64String;
    return base64Decode(cleanBase64);
  }

  /// Envía la imagen al backend y devuelve un [ResultadoAnalisis].
  static Future<ResultadoAnalisis> analizarImagen(String base64Image) async {
    final uri = Uri.parse('$_baseUrl$_predictPath');

    final Uint8List imageBytes;
    try {
      imageBytes = imageBytesFromBase64(base64Image);
    } catch (_) {
      throw AnalisisException(
          'La imagen está dañada o tiene un formato no válido.');
    }

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'foot_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      // Render puede tardar en despertar el servicio (~30-50s en frío).
      // Damos 90s de margen.
      final streamed =
          await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw AnalisisException(
            'El servidor respondió con código ${response.statusCode}.');
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      return ResultadoAnalisis.fromJson(json);
    } on AnalisisException {
      rethrow;
    } catch (e) {
      throw AnalisisException(
          'No se pudo conectar con el servidor de análisis. Revisa tu conexión a internet.');
    }
  }
}

class AnalisisException implements Exception {
  final String mensaje;
  AnalisisException(this.mensaje);

  @override
  String toString() => mensaje;
}