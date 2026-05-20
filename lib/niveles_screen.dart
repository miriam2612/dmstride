import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'alertas_service.dart';

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

class _NivelesScreenState extends State<NivelesScreen>
    with SingleTickerProviderStateMixin {
  final glucosaController = TextEditingController();
  final sistolicaController = TextEditingController();
  final diastolicaController = TextEditingController();

  String? momentoMedicion;
  final List<String> momentos = [
    'En ayunas',
    'Antes de comer',
    '2 horas después de comer',
    'Antes de dormir',
    'Síntomas / emergencia',
  ];

  bool guardandoGlucosa = false;
  bool guardandoPresion = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    glucosaController.dispose();
    sistolicaController.dispose();
    diastolicaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Rangos glucosa ──────────────────────────────────────────────────────────
  String _nivelGlucosa(double valor) {
    if (valor < 70) return 'hipoglucemia';
    if (valor <= 130) return 'controlada';
    if (valor <= 180) return 'precaucion';
    return 'peligro';
  }

  String _mensajeGlucosa(double valor) {
    if (valor < 70) return 'Glucosa muy baja — come algo dulce';
    if (valor <= 130) return 'Glucosa bien controlada';
    if (valor <= 180) return 'Glucosa elevada — vigila tu alimentación';
    return 'Glucosa muy alta — consulta a tu médico';
  }

  Color _colorGlucosa(double valor) {
    if (valor < 70) return Colors.redAccent;
    if (valor <= 130) return Colors.green;
    if (valor <= 180) return Colors.orange;
    return Colors.redAccent;
  }

  // ─── Rangos presión ──────────────────────────────────────────────────────────
  int _nivelPresionInt(int s, int d) {
    if (s >= 140 || d >= 90) return 2;
    if (s >= 130 || d >= 81) return 1;
    return 0;
  }

  String _nivelPresion(int s, int d) {
    final n = _nivelPresionInt(s, d);
    if (n == 0) return 'controlada';
    if (n == 1) return 'precaucion';
    return 'peligro';
  }

  String _mensajePresion(int s, int d) {
    final n = _nivelPresionInt(s, d);
    if (n == 0) return 'Presión bien controlada';
    if (n == 1) return 'Presión levemente elevada — vigilar';
    return 'Presión alta — consulta a tu médico';
  }

  Color _colorPresion(int s, int d) {
    final n = _nivelPresionInt(s, d);
    if (n == 0) return Colors.green;
    if (n == 1) return Colors.orange;
    return Colors.redAccent;
  }

  // ─── Guardar glucosa ✅ CORREGIDO ────────────────────────────────────────────
  Future<void> guardarGlucosa() async {
    final texto = glucosaController.text.trim();
    if (texto.isEmpty || momentoMedicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa la glucosa y el momento de medición'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final valor = double.tryParse(texto) ?? 0;
    setState(() => guardandoGlucosa = true);

    try {
      // ✅ Guardar glucosa en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('glucosaRegistros')
          .add({
        'valor': valor,
        'momentoMedicion': momentoMedicion,
        'estado': _nivelGlucosa(valor),
        'fechaHora': FieldValue.serverTimestamp(),
      });

      // ✅ Evaluar alerta por separado — si falla no afecta el guardado
      try {
        await AlertasService.evaluarGlucosa(uid: widget.uid, valor: valor);
      } catch (e) {
        debugPrint('Alerta glucosa falló: $e');
      }

      if (mounted) {
        glucosaController.clear();
        setState(() => momentoMedicion = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Glucosa guardada correctamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al guardar glucosa. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      // ✅ Siempre desactiva el loading
      if (mounted) setState(() => guardandoGlucosa = false);
    }
  }

  // ─── Guardar presión ✅ CORREGIDO ────────────────────────────────────────────
  Future<void> guardarPresion() async {
    final sText = sistolicaController.text.trim();
    final dText = diastolicaController.text.trim();

    if (sText.isEmpty || dText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa sistólica y diastólica'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final s = int.tryParse(sText) ?? 0;
    final d = int.tryParse(dText) ?? 0;

    setState(() => guardandoPresion = true);

    try {
      // ✅ Guardar presión en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('presionRegistros')
          .add({
        'sistolica': s,
        'diastolica': d,
        'estado': _nivelPresion(s, d),
        'fechaHora': FieldValue.serverTimestamp(),
      });

      // ✅ Evaluar alerta por separado — si falla no afecta el guardado
      try {
        await AlertasService.evaluarPresion(
            uid: widget.uid, sistolica: s, diastolica: d);
      } catch (e) {
        debugPrint('Alerta presión falló: $e');
      }

      if (mounted) {
        sistolicaController.clear();
        diastolicaController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Presión arterial registrada correctamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Error al guardar presión. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      // ✅ Siempre desactiva el loading
      if (mounted) setState(() => guardandoPresion = false);
    }
  }

  // ─── Fecha legible ───────────────────────────────────────────────────────────
  String _fechaLegible(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day} ${meses[fecha.month - 1]} — $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

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
        bottom: TabBar(
          controller: _tabController,
          labelColor: azulOscuro,
          unselectedLabelColor: Colors.grey,
          indicatorColor: azul,
          tabs: const [
            Tab(icon: Icon(Icons.bloodtype_outlined), text: 'Glucosa'),
            Tab(icon: Icon(Icons.favorite_outline), text: 'Presión'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabGlucosa(
            uid: widget.uid,
            soloLectura: widget.soloLectura,
            glucosaController: glucosaController,
            momentoMedicion: momentoMedicion,
            momentos: momentos,
            guardando: guardandoGlucosa,
            onMomentoChanged: (val) => setState(() => momentoMedicion = val),
            onGuardar: guardarGlucosa,
            colorGlucosa: _colorGlucosa,
            mensajeGlucosa: _mensajeGlucosa,
            fechaLegible: _fechaLegible,
          ),
          _TabPresion(
            uid: widget.uid,
            soloLectura: widget.soloLectura,
            sistolicaController: sistolicaController,
            diastolicaController: diastolicaController,
            guardando: guardandoPresion,
            onGuardar: guardarPresion,
            colorPresion: _colorPresion,
            mensajePresion: _mensajePresion,
            nivelPresionInt: _nivelPresionInt,
            fechaLegible: _fechaLegible,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB GLUCOSA
// ═══════════════════════════════════════════════════════════════════════════════
class _TabGlucosa extends StatelessWidget {
  final String uid;
  final bool soloLectura;
  final TextEditingController glucosaController;
  final String? momentoMedicion;
  final List<String> momentos;
  final bool guardando;
  final ValueChanged<String?> onMomentoChanged;
  final VoidCallback onGuardar;
  final Color Function(double) colorGlucosa;
  final String Function(double) mensajeGlucosa;
  final String Function(DateTime) fechaLegible;

  const _TabGlucosa({
    required this.uid,
    required this.soloLectura,
    required this.glucosaController,
    required this.momentoMedicion,
    required this.momentos,
    required this.guardando,
    required this.onMomentoChanged,
    required this.onGuardar,
    required this.colorGlucosa,
    required this.mensajeGlucosa,
    required this.fechaLegible,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('glucosaRegistros')
          .orderBy('fechaHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final registros = snapshot.data?.docs ?? [];

        final datosGrafica = registros.reversed
            .take(10)
            .toList()
            .asMap()
            .entries
            .map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          final valor = (data['valor'] ?? 0).toDouble();
          return FlSpot(e.key.toDouble(), valor);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (!soloLectura) ...[
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
                        'Registrar glucosa',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Glucosa (mg/dL)',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      StatefulBuilder(
                        builder: (context, setLocal) {
                          return Column(
                            children: [
                              TextField(
                                controller: glucosaController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setLocal(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Ej. 120',
                                  prefixIcon: const Icon(
                                      Icons.bloodtype_outlined, color: azul),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Builder(builder: (_) {
                                final val = double.tryParse(
                                    glucosaController.text.trim());
                                if (val == null) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorGlucosa(val).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.circle,
                                            color: colorGlucosa(val), size: 12),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            mensajeGlucosa(val),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorGlucosa(val),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Momento de medición',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: momentoMedicion,
                        decoration: InputDecoration(
                          hintText: 'Selecciona el momento',
                          prefixIcon:
                              const Icon(Icons.access_time, color: azul),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: momentos.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m,
                                style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: onMomentoChanged,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: guardando ? null : onGuardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: guardando
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Guardar glucosa',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (datosGrafica.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolución de glucosa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Últimos 10 registros',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            minY: 50,
                            maxY: 250,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 50,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Colors.grey.withOpacity(0.15),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 50,
                                  getTitlesWidget: (val, _) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            rangeAnnotations: RangeAnnotations(
                              horizontalRangeAnnotations: [
                                HorizontalRangeAnnotation(
                                  y1: 50,
                                  y2: 70,
                                  color: Colors.red.withOpacity(0.08),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: 70,
                                  y2: 130,
                                  color: Colors.green.withOpacity(0.08),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: 130,
                                  y2: 180,
                                  color: Colors.orange.withOpacity(0.08),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: 180,
                                  y2: 250,
                                  color: Colors.red.withOpacity(0.08),
                                ),
                              ],
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: datosGrafica,
                                isCurved: true,
                                color: azul,
                                barWidth: 2.5,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, _, __, ___) {
                                    Color c = spot.y < 70 || spot.y > 180
                                        ? Colors.redAccent
                                        : spot.y <= 130
                                            ? Colors.green
                                            : Colors.orange;
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: c,
                                      strokeWidth: 1.5,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: azul.withOpacity(0.06),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Leyenda(color: Colors.green, texto: '70–130'),
                          _Leyenda(color: Colors.orange, texto: '131–180'),
                          _Leyenda(
                              color: Colors.redAccent, texto: '<70 / >180'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Historial de glucosa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: azulOscuro,
                ),
              ),
              const SizedBox(height: 12),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: azul))
              else if (registros.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      soloLectura
                          ? 'El paciente aún no ha registrado glucosa'
                          : 'Aún no hay registros de glucosa',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ),
                )
              else
                ...registros.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = data['fechaHora'] != null
                      ? (data['fechaHora'] as dynamic).toDate()
                      : DateTime.now();
                  final valor = (data['valor'] ?? 0).toDouble();
                  final momento = data['momentoMedicion'] ?? '';
                  final color = _colorPorEstado(data['estado'] ?? '');

                  return Container(
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
                          width: 10,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fechaLegible(fecha),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${valor.toStringAsFixed(0)} mg/dL',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              if (momento.isNotEmpty)
                                Text(
                                  momento,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _etiquetaEstado(data['estado'] ?? ''),
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB PRESIÓN
// ═══════════════════════════════════════════════════════════════════════════════
class _TabPresion extends StatelessWidget {
  final String uid;
  final bool soloLectura;
  final TextEditingController sistolicaController;
  final TextEditingController diastolicaController;
  final bool guardando;
  final VoidCallback onGuardar;
  final Color Function(int, int) colorPresion;
  final String Function(int, int) mensajePresion;
  final int Function(int, int) nivelPresionInt;
  final String Function(DateTime) fechaLegible;

  const _TabPresion({
    required this.uid,
    required this.soloLectura,
    required this.sistolicaController,
    required this.diastolicaController,
    required this.guardando,
    required this.onGuardar,
    required this.colorPresion,
    required this.mensajePresion,
    required this.nivelPresionInt,
    required this.fechaLegible,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('presionRegistros')
          .orderBy('fechaHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final registros = snapshot.data?.docs ?? [];

        final listaReversed = registros.reversed.take(10).toList();
        final spotsSistolica = listaReversed.asMap().entries.map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          return FlSpot(
              e.key.toDouble(), (data['sistolica'] ?? 0).toDouble());
        }).toList();
        final spotsDiastolica = listaReversed.asMap().entries.map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          return FlSpot(
              e.key.toDouble(), (data['diastolica'] ?? 0).toDouble());
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (!soloLectura) ...[
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
                        'Registrar presión arterial',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Presión arterial (mmHg)',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      StatefulBuilder(
                        builder: (context, setLocal) {
                          final s = int.tryParse(
                              sistolicaController.text.trim());
                          final d = int.tryParse(
                              diastolicaController.text.trim());
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: sistolicaController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setLocal(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Sistólica',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text('/',
                                        style: TextStyle(
                                            fontSize: 22,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: diastolicaController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setLocal(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Diastólica',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (s != null && d != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        colorPresion(s, d).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle,
                                          color: colorPresion(s, d),
                                          size: 12),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          mensajePresion(s, d),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorPresion(s, d),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: guardando ? null : onGuardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: guardando
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Guardar presión',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (spotsSistolica.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolución de presión arterial',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Últimos 10 registros',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            minY: 50,
                            maxY: 180,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 30,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Colors.grey.withOpacity(0.15),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 30,
                                  getTitlesWidget: (val, _) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            rangeAnnotations: RangeAnnotations(
                              horizontalRangeAnnotations: [
                                HorizontalRangeAnnotation(
                                  y1: 50,
                                  y2: 130,
                                  color: Colors.green.withOpacity(0.06),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: 130,
                                  y2: 140,
                                  color: Colors.orange.withOpacity(0.08),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: 140,
                                  y2: 180,
                                  color: Colors.red.withOpacity(0.08),
                                ),
                              ],
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spotsSistolica,
                                isCurved: true,
                                color: const Color(0xFF6A93BE),
                                barWidth: 2.5,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF6A93BE)
                                      .withOpacity(0.06),
                                ),
                              ),
                              LineChartBarData(
                                spots: spotsDiastolica,
                                isCurved: true,
                                color: const Color(0xFF2C3E6B),
                                barWidth: 2,
                                dashArray: [5, 4],
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Leyenda(
                              color: const Color(0xFF6A93BE),
                              texto: 'Sistólica'),
                          const SizedBox(width: 20),
                          _Leyenda(
                              color: const Color(0xFF2C3E6B),
                              texto: 'Diastólica'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Historial de presión arterial',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: azulOscuro,
                ),
              ),
              const SizedBox(height: 12),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: azul))
              else if (registros.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      soloLectura
                          ? 'El paciente aún no ha registrado presión'
                          : 'Aún no hay registros de presión',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ),
                )
              else
                ...registros.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = data['fechaHora'] != null
                      ? (data['fechaHora'] as dynamic).toDate()
                      : DateTime.now();
                  final s = data['sistolica'] ?? 0;
                  final d = data['diastolica'] ?? 0;
                  final color = _colorPorEstado(data['estado'] ?? '');

                  return Container(
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
                          width: 10,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fechaLegible(fecha),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$s / $d mmHg',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _etiquetaEstado(data['estado'] ?? ''),
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Auxiliares
// ═══════════════════════════════════════════════════════════════════════════════
Color _colorPorEstado(String estado) {
  if (estado == 'controlada') return Colors.green;
  if (estado == 'precaucion') return Colors.orange;
  if (estado == 'hipoglucemia') return Colors.redAccent;
  if (estado == 'peligro') return Colors.redAccent;
  return Colors.grey;
}

String _etiquetaEstado(String estado) {
  if (estado == 'controlada') return 'Controlada';
  if (estado == 'precaucion') return 'Precaución';
  if (estado == 'hipoglucemia') return 'Hipoglucemia';
  if (estado == 'peligro') return 'Peligro';
  return 'Sin clasificar';
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}