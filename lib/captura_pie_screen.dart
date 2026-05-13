import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

enum FootSide { left, right }

class CapturaPieScreen extends StatefulWidget {
  final FootSide pieSide;

  const CapturaPieScreen({super.key, required this.pieSide});

  @override
  State<CapturaPieScreen> createState() => _CapturaPieScreenState();
}

class _CapturaPieScreenState extends State<CapturaPieScreen> {
  CameraController? _controller;
  bool isLoading = true;
  bool pieDetectado = false;
  int cuentaRegresiva = 0;
  bool tomandoFoto = false;

  late ObjectDetector _objectDetector;

  @override
  void initState() {
    super.initState();
    _inicializarDetector();
    inicializarCamara();
  }

  void _inicializarDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> inicializarCamara() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => isLoading = false);
    _controller!.startImageStream((CameraImage image) async {
      if (tomandoFoto) return;
      await _analizarImagen(image);
    });
  }

  Future<void> _analizarImagen(CameraImage image) async {
    try {
      final inputImage = _convertirImagen(image);
      if (inputImage == null) return;

      final objects = await _objectDetector.processImage(inputImage);

      bool hayObjeto = false;
      for (final obj in objects) {
        final rect = obj.boundingBox;
        final imgW = image.width.toDouble();
        final imgH = image.height.toDouble();

        final anchoSuficiente = rect.width > imgW * 0.20;
        final altoSuficiente = rect.height > imgH * 0.30;
        final centroX = rect.center.dx;
        final centroY = rect.center.dy;
        final enCentroX = centroX > imgW * 0.25 && centroX < imgW * 0.75;
        final enCentroY = centroY > imgH * 0.20 && centroY < imgH * 0.80;

        if (anchoSuficiente && altoSuficiente && enCentroX && enCentroY) {
          hayObjeto = true;
          break;
        }
      }

      if (hayObjeto && !pieDetectado && !tomandoFoto) {
        setState(() => pieDetectado = true);
        await _iniciarCuentaRegresiva();
      } else if (!hayObjeto) {
        setState(() {
          pieDetectado = false;
          cuentaRegresiva = 0;
        });
      }
    } catch (e) {
      debugPrint('Error al analizar: $e');
    }
  }

  InputImage? _convertirImagen(CameraImage image) {
    final camera = _controller!.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _iniciarCuentaRegresiva() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted || !pieDetectado) return;
      setState(() => cuentaRegresiva = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (pieDetectado && mounted) await tomarFoto();
  }

  Future<void> tomarFoto() async {
    if (tomandoFoto) return;
    setState(() {
      tomandoFoto = true;
      cuentaRegresiva = 0;
    });

    try {
      await _controller!.stopImageStream();
      final image = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewFotoScreen(
            imagePath: image.path,
            footSide: widget.pieSide,
            uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
        ),
      ).then((_) async {
        setState(() {
          tomandoFoto = false;
          pieDetectado = false;
          cuentaRegresiva = 0;
        });
        await _controller!.startImageStream((CameraImage image) async {
          if (tomandoFoto) return;
          await _analizarImagen(image);
        });
      });
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      setState(() => tomandoFoto = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorPrincipal = Color(0xFF6A93BE);

    if (isLoading || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),

          // Imagen del pie con puntos clínicos de tu amiga
          Positioned(
            top: screenH * 0.15,
            bottom: screenH * 0.18,
            left: screenW * 0.25,
            right: screenW * 0.25,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    pieDetectado
                        ? Colors.green.withValues(alpha: 0.35)
                        : Colors.blue.withValues(alpha: 0.20),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    widget.pieSide == FootSide.left
                        ? 'assets/images/pie_izq.png'
                        : 'assets/images/pie_der.png',
                    fit: BoxFit.contain,
                    color: pieDetectado ? Colors.green : Colors.white,
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
                Image.asset(
                  widget.pieSide == FootSide.left
                      ? 'assets/images/pie_izq.png'
                      : 'assets/images/pie_der.png',
                  fit: BoxFit.contain,
                  color: pieDetectado ? Colors.green : Colors.white,
                  colorBlendMode: BlendMode.modulate,
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: PuntosCiclicosPainter(widget.pieSide),
                ),
              ],
            ),
          ),

          if (cuentaRegresiva > 0)
            Center(
              child: Text(
                '$cuentaRegresiva',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 20, color: Colors.black)],
                ),
              ),
            ),

          // Flecha de regresar
          Positioned(
            top: 44,
            left: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 45,
            left: 60,
            right: 20,
            child: Column(
              children: [
                Text(
                  widget.pieSide == FootSide.left ? 'Pie izquierdo' : 'Pie derecho',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pieDetectado
                      ? '¡Pie detectado! Mantén quieto...'
                      : 'Coloca el pie dentro del marco',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pieDetectado ? Colors.greenAccent : Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: tomandoFoto ? null : tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrincipal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter de tu amiga con puntos clínicos y zonas anatómicas
class PuntosCiclicosPainter extends CustomPainter {
  final FootSide footSide;
  PuntosCiclicosPainter(this.footSide);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintLinea = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintVertical = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.50, h * 0.10),
      Offset(w * 0.50, h * 0.92),
      paintVertical,
    );

    final zonas = [
      {'y': 0.18, 'nombre': 'Dedos'},
      {'y': 0.35, 'nombre': 'Metatarso'},
      {'y': 0.58, 'nombre': 'Arco plantar'},
      {'y': 0.78, 'nombre': 'Talón'},
    ];

    for (final zona in zonas) {
      final y = (zona['y'] as double) * h;
      final nombre = zona['nombre'] as String;

      canvas.drawLine(Offset(w * 0.15, y), Offset(w * 0.85, y), paintLinea);

      final tp = TextPainter(
        text: TextSpan(
          text: nombre,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      if (footSide == FootSide.left) {
        tp.paint(canvas, Offset(w * 0.15, y - 12));
      } else {
        tp.paint(canvas, Offset(w * 0.85 - tp.width, y - 12));
      }
    }

    final puntos = footSide == FootSide.left
        ? [
            [0.62, 0.14, Colors.red, '1'],
            [0.38, 0.25, Colors.orange, '2'],
            [0.65, 0.30, Colors.orange, '3'],
            [0.50, 0.55, Colors.green, '4'],
            [0.36, 0.68, Colors.orange, '5'],
            [0.50, 0.88, Colors.purple, '6'],
          ]
        : [
            [0.38, 0.14, Colors.red, '1'],
            [0.62, 0.25, Colors.orange, '2'],
            [0.35, 0.30, Colors.orange, '3'],
            [0.50, 0.55, Colors.green, '4'],
            [0.64, 0.68, Colors.orange, '5'],
            [0.50, 0.88, Colors.purple, '6'],
          ];

    for (final p in puntos) {
      final dx = (p[0] as double) * w;
      final dy = (p[1] as double) * h;
      final color = p[2] as Color;
      final label = p[3] as String;

      canvas.drawCircle(
        Offset(dx, dy),
        10,
        Paint()..color = color..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(dx, dy),
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
    }

    final leyenda = ['🔴 Máximo', '🟠 Alto', '🟢 Rutina', '🟣 Talón'];

    double anchoTotal = 0;
    final tpTemps = <TextPainter>[];
    for (final texto in leyenda) {
      final tpTemp = TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 8,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tpTemp.layout();
      tpTemps.add(tpTemp);
      anchoTotal += tpTemp.width + 8;
    }

    double leyendaX = (w - anchoTotal) / 2;
    final leyendaY = h * 0.96;

    for (final tpL in tpTemps) {
      tpL.paint(canvas, Offset(leyendaX, leyendaY));
      leyendaX += tpL.width + 8;
    }
  }

  @override
  bool shouldRepaint(covariant PuntosCiclicosPainter oldDelegate) {
    return oldDelegate.footSide != footSide;
  }
}

class PreviewFotoScreen extends StatefulWidget {
  final String imagePath;
  final FootSide footSide;
  final String uid;

  const PreviewFotoScreen({
    super.key,
    required this.imagePath,
    required this.footSide,
    required this.uid,
  });

  @override
  State<PreviewFotoScreen> createState() => _PreviewFotoScreenState();
}

class _PreviewFotoScreenState extends State<PreviewFotoScreen> {
  bool guardando = false;

  Future<void> guardarFoto() async {
    setState(() => guardando = true);

    try {
      final bytesComprimidos = await FlutterImageCompress.compressWithFile(
        widget.imagePath,
        quality: 40,
      );

      if (bytesComprimidos == null) {
        setState(() => guardando = false);
        return;
      }

      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytesComprimidos)}';

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('fotos')
          .add({
        'imagenBase64': base64Str,
        'fecha': FieldValue.serverTimestamp(),
        'pie': widget.footSide == FootSide.left ? 'izquierdo' : 'derecho',
        'observaciones': '',
      });

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto guardada correctamente'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar: $e');
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final footText = widget.footSide == FootSide.left
        ? 'Pie izquierdo'
        : 'Pie derecho';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de imagen'),
        backgroundColor: const Color(0xFF6A93BE),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(
              footText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verifica que la imagen sea clara, que el pie esté completo, centrado y sin sombras fuertes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const QualityChecklist(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Repetir foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: guardando ? null : guardarFoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A93BE),
                      foregroundColor: Colors.white,
                    ),
                    child: guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Usar foto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QualityChecklist extends StatelessWidget {
  const QualityChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Se observa todo el pie',
      'La imagen no está borrosa',
      'No hay sombras fuertes',
      'El fondo es claro',
      'El pie está centrado',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF6A93BE),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item)),
            ],
          ),
        );
      }).toList(),
    );
  }
}