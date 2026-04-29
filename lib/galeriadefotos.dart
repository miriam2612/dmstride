import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GaleriaFotosScreen extends StatelessWidget {
  final String uid;
  final bool esDoctor;

  const GaleriaFotosScreen({
    super.key,
    required this.uid,
    required this.esDoctor,
  });

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
              onPressed: () {
                // aquí va el código de tu compañera para subir fotos
              },
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fotos.length,
            itemBuilder: (context, index) {
              final data = fotos[index].data() as Map<String, dynamic>;
              final docId = fotos[index].id;
              final fecha = data['fecha'] != null
                  ? (data['fecha'] as dynamic).toDate()
                  : DateTime.now();

              return _TarjetaFoto(
                data: data,
                docId: docId,
                uid: uid,
                fecha: fecha,
                esDoctor: esDoctor,
              );
            },
          );
        },
      ),
    );
  }
}

class _TarjetaFoto extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  final DateTime fecha;
  final bool esDoctor;

  const _TarjetaFoto({
    required this.data,
    required this.docId,
    required this.uid,
    required this.fecha,
    required this.esDoctor,
  });

  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleFotoScreen(
              data: data,
              docId: docId,
              uid: uid,
              esDoctor: esDoctor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: data['imagenBase64'] != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.memory(
                        Uri.parse(data['imagenBase64']).data!.contentAsBytes(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Color(0xFF6A93BE),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fechaFormateada,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (data['observaciones'] != null &&
                      data['observaciones'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Con observaciones',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A93BE),
                          fontWeight: FontWeight.w500,
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