import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'captura_pie_screen.dart';

class GaleriaFotosScreen extends StatelessWidget {
  final String uid;
  final bool esDoctor;

  const GaleriaFotosScreen({
    super.key,
    required this.uid,
    required this.esDoctor,
  });

  void mostrarSelectorPie(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué pie vas a fotografiar?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E6B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona antes de tomar la foto',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CapturaPieScreen(
                              pieSide: FootSide.left,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6A93BE)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Pie izquierdo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A93BE),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CapturaPieScreen(
                              pieSide: FootSide.right,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A93BE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6A93BE)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Pie derecho',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _nombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A93BE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fotos del pie',
          style: TextStyle(
            color: Color(0xFF2C3E6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!esDoctor)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF6A93BE)),
              onPressed: () => mostrarSelectorPie(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('fotos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A93BE)),
            );
          }

          final fotos = snapshot.data?.docs ?? [];

          if (fotos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no hay fotos registradas',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  if (!esDoctor) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Toca el ícono de cámara para agregar una',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          }

          final Map<String, List<QueryDocumentSnapshot>> agrupadas = {};
          for (var doc in fotos) {
            final data = doc.data() as Map<String, dynamic>;
            final fecha = data['fecha'] != null
                ? (data['fecha'] as dynamic).toDate().toLocal()
                : DateTime.now();
            final clave = '${_nombreMes(fecha.month)} ${fecha.year}';
            agrupadas.putIfAbsent(clave, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: agrupadas.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E6B),
                      ),
                    ),
                  ),
                  ...entry.value.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fecha = data['fecha'] != null
                        ? (data['fecha'] as dynamic).toDate().toLocal()
                        : DateTime.now();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleFotoScreen(
                              data: data,
                              docId: doc.id,
                              uid: uid,
                              esDoctor: esDoctor,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF3FB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${fecha.day}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A93BE),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['pie'] != null
                                        ? data['pie'] == 'izquierdo'
                                            ? 'Pie izquierdo'
                                            : 'Pie derecho'
                                        : 'Sin especificar',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E6B),
                                    ),
                                  ),
                                  if (data['observaciones'] != null &&
                                      data['observaciones'].toString().isNotEmpty)
                                    const Text(
                                      'Con observaciones del doctor',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (data['imagenBase64'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  Uri.parse(data['imagenBase64']).data!.contentAsBytes(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF3FB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF6A93BE),
                                  size: 22,
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class DetalleFotoScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  final bool esDoctor;

  const DetalleFotoScreen({
    super.key,
    required this.data,
    required this.docId,
    required this.uid,
    required this.esDoctor,
  });

  @override
  State<DetalleFotoScreen> createState() => _DetalleFotoScreenState();
}

class _DetalleFotoScreenState extends State<DetalleFotoScreen> {
  late final observacionesController = TextEditingController(
    text: widget.data['observaciones'] ?? '',
  );
  bool guardando = false;

  @override
  void dispose() {
    observacionesController.dispose();
    super.dispose();
  }

  Future<void> guardarObservacion() async {
    setState(() => guardando = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('fotos')
        .doc(widget.docId)
        .update({
      'observaciones': observacionesController.text.trim(),
    });

    if (mounted) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Observación guardada'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.data['pie'] != null
            ? Text(
                widget.data['pie'] == 'izquierdo'
                    ? 'Pie izquierdo'
                    : 'Pie derecho',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              )
            : null,
      ),
      body: Column(
        children: [

          Expanded(
            child: widget.data['imagenBase64'] != null
                ? Image.memory(
                    Uri.parse(widget.data['imagenBase64']).data!.contentAsBytes(),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: Colors.white30,
                    ),
                  ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: Color(0xFF6A93BE),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Observaciones del doctor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E6B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (widget.esDoctor)
                  TextField(
                    controller: observacionesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escribe una observación sobre esta foto...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      widget.data['observaciones'] != null &&
                              widget.data['observaciones'].toString().isNotEmpty
                          ? widget.data['observaciones']
                          : 'El doctor aún no ha agregado observaciones',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.data['observaciones'] != null &&
                                widget.data['observaciones'].toString().isNotEmpty
                            ? const Color(0xFF2C3E6B)
                            : Colors.grey,
                      ),
                    ),
                  ),

                if (widget.esDoctor) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: guardando ? null : guardarObservacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A93BE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Guardar observación',
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}