// lib/screens/analisis_resultado_screen.dart
//
// Pantalla que muestra los resultados del análisis preliminar de una imagen
// enviada a la API DM-Stride.
//
// Muestra:
//  - Imagen original (Base64) y procesada (overlay desde la API)
//  - Leyenda de colores detectados en el overlay
//
// Al tocar cualquiera de las dos imágenes, se abre en pantalla completa
// con zoom interactivo (pinch para acercar, arrastrar para mover).

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'resultado_analisis.dart';
import 'analisis_service.dart';

class AnalisisResultadoScreen extends StatelessWidget {
  final String imagenBase64;
  final ResultadoAnalisis resultado;

  const AnalisisResultadoScreen({
    super.key,
    required this.imagenBase64,
    required this.resultado,
  });

  static const _azul = Color(0xFF6A93BE);
  static const _azulOscuro = Color(0xFF2C3E6B);
  static const _fondo = Color(0xFFF5F7FA);

  // Colores que aparecen en el overlay generado por la API
  static const _colorRojez = Color(0xFFFFD600);       // Amarillo
  static const _colorUlcera = Color(0xFFFF4081);      // Rosa
  static const _colorCallo = Color(0xFF9C27B0);       // Morado

  /// Abre la imagen en una pantalla completa con zoom interactivo.
  void _abrirImagenAmpliada(
    BuildContext context, {
    required String titulo,
    required Widget imagen,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _VisorImagenAmpliada(
          titulo: titulo,
          imagen: imagen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List imagenBytes =
        AnalisisService.imageBytesFromBase64(imagenBase64);

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _azul),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Análisis de imagen',
          style: TextStyle(
            color: _azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── COMPARACIÓN DE IMÁGENES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TarjetaImagen(
                    titulo: 'Imagen original',
                    icono: Icons.photo_outlined,
                    onTap: () => _abrirImagenAmpliada(
                      context,
                      titulo: 'Imagen original',
                      imagen: Image.memory(imagenBytes, fit: BoxFit.contain),
                    ),
                    child: Image.memory(
                      imagenBytes,
                      fit: BoxFit.cover,
                      height: 160,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TarjetaImagen(
                    titulo: 'Imagen procesada',
                    icono: Icons.auto_awesome_outlined,
                    onTap: () => _abrirImagenAmpliada(
                      context,
                      titulo: 'Imagen procesada',
                      imagen: resultado.overlayUrl != null
                          ? Image.network(
                              resultado.overlayUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Image.memory(imagenBytes, fit: BoxFit.contain),
                            )
                          : Image.memory(imagenBytes, fit: BoxFit.contain),
                    ),
                    child: _ImagenProcesada(
                      overlayUrl: resultado.overlayUrl,
                      fallbackBytes: imagenBytes,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Pista visual para que el doctor sepa que puede ampliar
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Toca una imagen para ampliarla',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── LEYENDA DE COLORES ──
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: _azul, size: 18),
                SizedBox(width: 8),
                Text(
                  'Hallazgos detectados',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _azulOscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Colores identificados en la imagen procesada',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Column(
                children: [
                  _FilaLeyenda(
                    color: _colorUlcera,
                    nombreColor: 'Rosa',
                    significado: 'Úlcera',
                    descripcion: 'Zonas de lesión o herida abierta',
                  ),
                  SizedBox(height: 14),
                  _FilaLeyenda(
                    color: _colorRojez,
                    nombreColor: 'Amarillo',
                    significado: 'Rojez',
                    descripcion: 'Áreas con eritema o inflamación',
                  ),
                  SizedBox(height: 14),
                  _FilaLeyenda(
                    color: _colorCallo,
                    nombreColor: 'Morado',
                    significado: 'Callo / rugosidad',
                    descripcion: 'Hiperqueratosis o piel engrosada',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ─── FILA DE LEYENDA DE COLOR ─────────────────────────────────────────────────

class _FilaLeyenda extends StatelessWidget {
  final Color color;
  final String nombreColor;
  final String significado;
  final String descripcion;

  const _FilaLeyenda({
    required this.color,
    required this.nombreColor,
    required this.significado,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cuadrito de color con sombra sutil
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    significado,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E6B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      nombreColor,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: HSLColor.fromColor(color)
                            .withLightness(
                              (HSLColor.fromColor(color).lightness * 0.55)
                                  .clamp(0.0, 1.0),
                            )
                            .toColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                descripcion,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── VISOR DE IMAGEN AMPLIADA (pantalla completa con zoom) ────────────────────

class _VisorImagenAmpliada extends StatelessWidget {
  final String titulo;
  final Widget imagen;

  const _VisorImagenAmpliada({
    required this.titulo,
    required this.imagen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: imagen,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pinch_outlined, color: Colors.white54, size: 14),
            SizedBox(width: 6),
            Text(
              'Usa dos dedos para hacer zoom',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TARJETA DE IMAGEN (lado izquierdo / derecho) ─────────────────────────────

class _TarjetaImagen extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  final VoidCallback? onTap;

  const _TarjetaImagen({
    required this.titulo,
    required this.icono,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                children: [
                  Icon(icono, size: 14, color: const Color(0xFF6A93BE)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E6B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.zoom_in,
                      size: 14, color: Color(0xFF6A93BE)),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
              child: Stack(
                children: [
                  child,
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        splashColor: Colors.white.withOpacity(0.2),
                        highlightColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── IMAGEN PROCESADA (overlay desde API, con fallback) ───────────────────────

class _ImagenProcesada extends StatelessWidget {
  final String? overlayUrl;
  final Uint8List fallbackBytes;

  const _ImagenProcesada({
    required this.overlayUrl,
    required this.fallbackBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (overlayUrl == null) {
      return _fallbackConAviso(context, 'Sin overlay disponible');
    }

    return Image.network(
      overlayUrl!,
      fit: BoxFit.cover,
      height: 160,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 160,
          color: const Color(0xFFEEF3FB),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF6A93BE),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return _fallbackConAviso(context, 'Overlay no disponible');
      },
    );
  }

  Widget _fallbackConAviso(BuildContext context, String texto) {
    return Stack(
      children: [
        Image.memory(
          fallbackBytes,
          fit: BoxFit.cover,
          height: 160,
          width: double.infinity,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            color: Colors.black.withOpacity(0.55),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
