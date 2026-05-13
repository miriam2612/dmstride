import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NivelesScreen extends StatefulWidget {
  final String uid;
  final bool soloLectura;

  const NivelesScreen({
    super.key,
    required this.uid,
    this.soloLectura = false,
  });

  @override
  State<NivelesScreen> createState() => _NivelesScreenState();
}

class _NivelesScreenState extends State<NivelesScreen> {
  final glucosaController = TextEditingController();
  final presionSistolicaController = TextEditingController();
  final presionDiastolicaController = TextEditingController();
  bool guardando = false;

  @override
  void dispose() {
    glucosaController.dispose();
    presionSistolicaController.dispose();
    presionDiastolicaController.dispose();
    super.dispose();
  }

  String _nivelGlucosa(double valor) {
    if (valor < 70) return 'hipoglucemia';
    if (valor <= 130) return 'controlada';
    if (valor <= 180) return 'precaucion';
    return 'peligro';
  }

  String _mensajeGlucosa(double valor) {
    if (valor < 70) return 'Glucosa muy baja';
    if (valor <= 130) return 'Glucosa bien controlada';
    if (valor <= 180) return 'Glucosa elevada';
    return 'Glucosa muy alta, riesgo de daño en pies';
  }

  Color _colorGlucosa(double valor) {
    if (valor < 70) return Colors.redAccent;
    if (valor <= 130) return Colors.green;
    if (valor <= 180) return Colors.orange;
    return Colors.redAccent;
  }

  String _nivelPresion(int sistolica, int diastolica) {
    if (sistolica < 130 && diastolica < 80) return 'controlada';
    if (sistolica <= 139 && diastolica <= 89) return 'precaucion';
    return 'peligro';
  }

  String _mensajePresion(int sistolica, int diastolica) {
    if (sistolica < 130 && diastolica < 80) return 'Presión bien controlada';
    if (sistolica <= 139 && diastolica <= 89) return 'Presión un poco elevada';
    return 'Presión muy alta, riesgo de complicaciones';
  }

  Color _colorPresion(int sistolica, int diastolica) {
    if (sistolica < 130 && diastolica < 80) return Colors.green;
    if (sistolica <= 139 && diastolica <= 89) return Colors.orange;
    return Colors.redAccent;
  }

  Future<void> guardarNiveles() async {
    final glucosaText = glucosaController.text.trim();
    final sistolicaText = presionSistolicaController.text.trim();
    final diastolicaText = presionDiastolicaController.text.trim();

    if (glucosaText.isEmpty || sistolicaText.isEmpty || diastolicaText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Llena todos los campos antes de guardar'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => guardando = true);

    final glucosa = double.tryParse(glucosaText) ?? 0;
    final sistolica = int.tryParse(sistolicaText) ?? 0;
    final diastolica = int.tryParse(diastolicaText) ?? 0;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('niveles')
        .add({
      'glucosa': glucosa,
      'presionSistolica': sistolica,
      'presionDiastolica': diastolica,
      'nivelGlucosa': _nivelGlucosa(glucosa),
      'nivelPresion': _nivelPresion(sistolica, diastolica),
      'fecha': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      glucosaController.clear();
      presionSistolicaController.clear();
      presionDiastolicaController.clear();
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Niveles guardados correctamente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    final glucosaText = glucosaController.text.trim();
    final sistolicaText = presionSistolicaController.text.trim();
    final diastolicaText = presionDiastolicaController.text.trim();

    final glucosa = double.tryParse(glucosaText);
    final sistolica = int.tryParse(sistolicaText);
    final diastolica = int.tryParse(diastolicaText);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: azul),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.soloLectura ? 'Niveles del paciente' : 'Mis niveles',
          style: const TextStyle(
            color: azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Solo muestra el formulario si NO es solo lectura
            if (!widget.soloLectura) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar niveles de hoy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Glucosa (mg/dL)',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: glucosaController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ej. 120',
                        prefixIcon: const Icon(Icons.bloodtype_outlined, color: azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (glucosa != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorGlucosa(glucosa).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: _colorGlucosa(glucosa), size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mensajeGlucosa(glucosa),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _colorGlucosa(glucosa),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    const Text(
                      'Presión arterial (mmHg)',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: presionSistolicaController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Sistólica',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '/',
                            style: TextStyle(fontSize: 22, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: presionDiastolicaController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Diastólica',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (sistolica != null && diastolica != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorPresion(sistolica, diastolica).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: _colorPresion(sistolica, diastolica), size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mensajePresion(sistolica, diastolica),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _colorPresion(sistolica, diastolica),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: guardando ? null : guardarNiveles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azul,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: guardando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Guardar niveles',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],

            Text(
              widget.soloLectura
                  ? 'Historial de niveles registrados'
                  : 'Historial de niveles',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: azulOscuro,
              ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(widget.uid)
                  .collection('niveles')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: azul),
                  );
                }

                final registros = snapshot.data?.docs ?? [];

                if (registros.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.soloLectura
                            ? 'El paciente aún no ha registrado niveles'
                            : 'Aún no hay registros guardados',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: registros.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fecha = data['fecha'] != null
                        ? (data['fecha'] as dynamic).toDate()
                        : DateTime.now();
                    final glucosaVal = (data['glucosa'] ?? 0).toDouble();
                    final sistolicaVal = data['presionSistolica'] ?? 0;
                    final diastolicaVal = data['presionDiastolica'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${fecha.day} de ${_nombreMes(fecha.month)} ${fecha.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ItemNivel(
                                  etiqueta: 'Glucosa',
                                  valor: '${glucosaVal.toStringAsFixed(0)} mg/dL',
                                  color: _colorGlucosa(glucosaVal),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ItemNivel(
                                  etiqueta: 'Presión',
                                  valor: '$sistolicaVal/$diastolicaVal mmHg',
                                  color: _colorPresion(sistolicaVal, diastolicaVal),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ItemNivel extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;

  const _ItemNivel({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}