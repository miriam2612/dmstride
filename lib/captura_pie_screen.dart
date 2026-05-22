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
  bool _camaraFrontal = false;
  bool _analizando = false;

  List<CameraDescription> _camaras = [];

  late ObjectDetector _objectDetector;

  @override
  void initState() {
    super.initState();
    _inicializarDetector();
    inicializarCamara(frontal: false);
  }

  void _inicializarDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );

    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> inicializarCamara({bool frontal = false}) async {
    try {
      if (mounted) {
        setState(() => isLoading = true);
      }

      _camaras = await availableCameras();

      if (_camaras.isEmpty) {
        debugPrint('No se encontraron cámaras disponibles');
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final camara = _camaras.firstWhere(
        (c) => frontal
            ? c.lensDirection == CameraLensDirection.front
            : c.lensDirection == CameraLensDirection.back,
        orElse: () => _camaras.first,
      );

      final oldController = _controller;

      if (oldController != null) {
        if (oldController.value.isStreamingImages) {
          await oldController.stopImageStream();
        }
        await oldController.dispose();
      }

      _controller = CameraController(
        camara,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        pieDetectado = false;
      });

      await _iniciarStream();
    } catch (e) {
      debugPrint('Error al inicializar cámara: $e');

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _iniciarStream() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;
      if (_controller!.value.isStreamingImages) return;

      await _controller!.startImageStream((CameraImage image) async {
        if (tomandoFoto || _analizando) return;

        _analizando = true;
        await _analizarImagen(image);
        _analizando = false;
      });
    } catch (e) {
      debugPrint('Error al iniciar stream: $e');
    }
  }

  Future<void> _detenerStream() async {
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error al detener stream: $e');
    }
  }

  Future<void> _cambiarCamara() async {
    try {
      if (_camaras.isEmpty) {
        _camaras = await availableCameras();
      }

      final nuevaCamaraFrontal = !_camaraFrontal;

      final existeCamara = _camaras.any(
        (c) => nuevaCamaraFrontal
            ? c.lensDirection == CameraLensDirection.front
            : c.lensDirection == CameraLensDirection.back,
      );

      if (!existeCamara) {
        debugPrint('No existe esa cámara en este dispositivo');
        return;
      }

      setState(() {
        _camaraFrontal = nuevaCamaraFrontal;
        isLoading = true;
        pieDetectado = false;
      });

      await inicializarCamara(frontal: _camaraFrontal);
    } catch (e) {
      debugPrint('Error al cambiar cámara: $e');

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

      if (mounted) {
        setState(() => pieDetectado = hayObjeto);
      }
    } catch (e) {
      debugPrint('Error al analizar: $e');
    }
  }

  InputImage? _convertirImagen(CameraImage image) {
    try {
      if (_controller == null) return null;

      final camera = _controller!.description;

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

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
    } catch (e) {
      debugPrint('Error al convertir imagen: $e');
      return null;
    }
  }

  Future<void> tomarFoto() async {
    if (tomandoFoto) return;

    setState(() => tomandoFoto = true);

    for (int i = 60; i >= 1; i--) {
      if (!mounted) return;

      setState(() => cuentaRegresiva = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setState(() => cuentaRegresiva = 0);

    try {
      await _detenerStream();

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
        if (!mounted) return;

        setState(() {
          tomandoFoto = false;
          pieDetectado = false;
          cuentaRegresiva = 0;
        });

        await _iniciarStream();
      });
    } catch (e) {
      debugPrint('Error al tomar foto: $e');

      if (mounted) {
        setState(() {
          tomandoFoto = false;
          cuentaRegresiva = 0;
        });
      }

      await _iniciarStream();
    }
  }

  @override
  void dispose() {
    _cerrarCamara();
    _objectDetector.close();
    super.dispose();
  }

  Future<void> _cerrarCamara() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      }
    } catch (e) {
      debugPrint('Error al cerrar cámara: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrincipal = Color(0xFF6A93BE);

    if (isLoading ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // Plantilla del pie con guía simple de centrado
          Positioned(
            top: screenH * 0.17,
            bottom: screenH * 0.20,
            left: screenW * 0.22,
            right: screenW * 0.22,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.95,
                  child: Image.asset(
                    widget.pieSide == FootSide.left
                        ? 'assets/images/pie_izq.png'
                        : 'assets/images/pie_der.png',
                    fit: BoxFit.contain,
                    color: pieDetectado ? Colors.greenAccent : Colors.white,
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),

                // Solo líneas guía, sin textos, sin números y sin leyenda
                CustomPaint(
                  size: Size.infinite,
                  painter: GuiaCentradoPainter(),
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
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 44,
            left: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 44,
            right: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.cameraswitch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: tomandoFoto ? null : _cambiarCamara,
              ),
            ),
          ),

          Positioned(
            top: 45,
            left: 60,
            right: 60,
            child: Column(
              children: [
                Text(
                  widget.pieSide == FootSide.left
                      ? 'Pie izquierdo'
                      : 'Pie derecho',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  pieDetectado
                      ? '¡Pie detectado! Presiona el botón cuando estés listo'
                      : 'Coloca el pie dentro del marco',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pieDetectado ? Colors.greenAccent : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black,
                      ),
                    ],
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
                icon: tomandoFoto && cuentaRegresiva > 0
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  cuentaRegresiva > 0
                      ? 'Tomando en $cuentaRegresiva...'
                      : 'Tomar foto',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrincipal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuiaCentradoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintLineaPrincipal = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final paintLineaSuave = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Línea vertical central
    canvas.drawLine(
      Offset(w * 0.50, h * 0.10),
      Offset(w * 0.50, h * 0.90),
      paintLineaPrincipal,
    );

    // Línea horizontal superior
    canvas.drawLine(
      Offset(w * 0.24, h * 0.25),
      Offset(w * 0.76, h * 0.25),
      paintLineaSuave,
    );

    // Línea horizontal central
    canvas.drawLine(
      Offset(w * 0.20, h * 0.50),
      Offset(w * 0.80, h * 0.50),
      paintLineaPrincipal,
    );

    // Línea horizontal inferior
    canvas.drawLine(
      Offset(w * 0.24, h * 0.75),
      Offset(w * 0.76, h * 0.75),
      paintLineaSuave,
    );
  }

  @override
  bool shouldRepaint(covariant GuiaCentradoPainter oldDelegate) {
    return false;
  }
}

// PREVIEW DE FOTO
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

      final base64Str =
          'data:image/jpeg;base64,${base64Encode(bytesComprimidos)}';

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

      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final footText =
        widget.footSide == FootSide.left ? 'Pie izquierdo' : 'Pie derecho';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de imagen'),
        backgroundColor: const Color(0xFF6A93BE),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              footText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
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

// CHECKLIST DE CALIDAD
class QualityChecklist extends StatelessWidget {
  const QualityChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Revisa que cumpla con los siguientes puntos:',
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
              Expanded(
                child: Text(item),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}