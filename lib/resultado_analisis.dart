// lib/models/resultado_analisis.dart
//
// Modelo que representa la respuesta de la API DM-Stride.
// Endpoint: POST https://dm-stride-api.onrender.com/predict
//
// Ejemplo de respuesta esperada:
// {
//   "status": "success",
//   "message": "Imagen procesada correctamente",
//   "resultado": {
//     "file_id": "...",
//     "mask_filename": "..._mask.png",
//     "overlay_filename": "..._overlay.png",
//     "porcentajes": {
//       "ulcera": 6.06,
//       "rojez": 15.99,
//       "callo_rugosidad": 1.1
//     },
//     "riesgo_preliminar": "Alto"
//   },
//   "nota": "Resultado preliminar. No representa diagnóstico médico."
// }

class ResultadoAnalisis {
  final String status;
  final String message;
  final String fileId;
  final String maskFilename;
  final String overlayFilename;
  final double porcentajeUlcera;
  final double porcentajeRojez;
  final double porcentajeCalloRugosidad;
  final String riesgoPreliminar;
  final String nota;

  ResultadoAnalisis({
    required this.status,
    required this.message,
    required this.fileId,
    required this.maskFilename,
    required this.overlayFilename,
    required this.porcentajeUlcera,
    required this.porcentajeRojez,
    required this.porcentajeCalloRugosidad,
    required this.riesgoPreliminar,
    required this.nota,
  });

  factory ResultadoAnalisis.fromJson(Map<String, dynamic> json) {
    final resultado = json['resultado'] as Map<String, dynamic>? ?? {};
    final porcentajes =
        resultado['porcentajes'] as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ResultadoAnalisis(
      status: json['status']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? '',
      fileId: resultado['file_id']?.toString() ?? '',
      maskFilename: resultado['mask_filename']?.toString() ?? '',
      overlayFilename: resultado['overlay_filename']?.toString() ?? '',
      porcentajeUlcera: parseDouble(porcentajes['ulcera']),
      porcentajeRojez: parseDouble(porcentajes['rojez']),
      porcentajeCalloRugosidad: parseDouble(porcentajes['callo_rugosidad']),
      riesgoPreliminar: resultado['riesgo_preliminar']?.toString() ?? 'No determinado',
      nota: json['nota']?.toString() ??
          'Resultado preliminar. No representa diagnóstico médico.',
    );
  }

  // URL pública del overlay procesado.
  // TODO: Confirmar con el backend si esta ruta existe o reemplazarla por la correcta.
  // Patrón estándar de FastAPI con StaticFiles: /outputs/{filename}
  String? get overlayUrl {
    if (overlayFilename.isEmpty) return null;
    return 'https://dm-stride-api.onrender.com/outputs/$overlayFilename';
  }

  String? get maskUrl {
    if (maskFilename.isEmpty) return null;
    return 'https://dm-stride-api.onrender.com/outputs/$maskFilename';
  }
}