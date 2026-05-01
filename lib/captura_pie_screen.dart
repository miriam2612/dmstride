import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),

          Positioned(
            top: 100,
            bottom: 120,
            left: -80,
            right: -80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    pieDetectado
                        ? Colors.green.withValues(alpha: 0.35)
                        : Colors.blue.withValues(alpha: 0.25),
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
      final bytes = await File(widget.imagePath).readAsBytes();
      final base64 = 'data:image/jpeg;base64,${_bytesToBase64(bytes)}';

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('fotos')
          .add({
        'imagenBase64': base64,
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

  String _bytesToBase64(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    var result = '';
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += chars[(b0 >> 2) & 0x3F];
      result += chars[((b0 << 4) | (b1 >> 4)) & 0x3F];
      result += i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=';
      result += i + 2 < bytes.length ? chars[b2 & 0x3F] : '=';
    }
    return result;
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