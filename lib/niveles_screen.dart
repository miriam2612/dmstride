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

  DateTime semanaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    glucosaController.dispose();
    sistolicaController.dispose();
    diastolicaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  DateTime _inicioDeSemana(DateTime fecha) {
    final local = fecha.toLocal();
    final soloFecha = DateTime(local.year, local.month, local.day);
    return soloFecha.subtract(Duration(days: soloFecha.weekday - 1));
  }

  DateTime _finDeSemana(DateTime fecha) {
    final inicio = _inicioDeSemana(fecha);
    return inicio.add(const Duration(days: 6));
  }

  DateTime _inicioSemanaSiguiente(DateTime fecha) {
    final inicio = _inicioDeSemana(fecha);
    return inicio.add(const Duration(days: 7));
  }

  String _textoSemana(DateTime fecha) {
    final inicio = _inicioDeSemana(fecha);
    final fin = _finDeSemana(fecha);
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    if (inicio.month == fin.month && inicio.year == fin.year) {
      return 'Semana del ${inicio.day} al ${fin.day} de ${meses[inicio.month - 1]}';
    }
    if (inicio.year == fin.year) {
      return 'Semana del ${inicio.day} de ${meses[inicio.month - 1]} al ${fin.day} de ${meses[fin.month - 1]}';
    }
    return 'Semana del ${inicio.day} de ${meses[inicio.month - 1]} de ${inicio.year} al ${fin.day} de ${meses[fin.month - 1]} de ${fin.year}';
  }

  void _semanaAnterior() => setState(() =>
      semanaSeleccionada = semanaSeleccionada.subtract(const Duration(days: 7)));

  void _semanaSiguiente() => setState(() =>
      semanaSeleccionada = semanaSeleccionada.add(const Duration(days: 7)));

  bool _esSemanaActual() {
    final a = _inicioDeSemana(DateTime.now());
    final b = _inicioDeSemana(semanaSeleccionada);
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _nivelGlucosa(double v) {
    if (v < 70) return 'hipoglucemia';
    if (v <= 130) return 'controlada';
    if (v <= 180) return 'precaucion';
    return 'peligro';
  }

  Color _colorGlucosa(double v) {
    if (v < 70) return Colors.redAccent;
    if (v <= 130) return Colors.green;
    if (v <= 180) return Colors.orange;
    return Colors.redAccent;
  }

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

  Future<void> guardarGlucosa() async {
    final texto = glucosaController.text.trim();
    if (texto.isEmpty || momentoMedicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ingresa la glucosa y el momento de medición'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    final valor = double.tryParse(texto) ?? 0;
    setState(() => guardandoGlucosa = true);
    try {
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
      try {
        await AlertasService.evaluarGlucosa(uid: widget.uid, valor: valor);
      } catch (e) {
        debugPrint('Alerta glucosa falló: $e');
      }
      if (mounted) {
        glucosaController.clear();
        setState(() {
          momentoMedicion = null;
          semanaSeleccionada = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Glucosa guardada correctamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al guardar glucosa. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => guardandoGlucosa = false);
    }
  }

  Future<void> guardarPresion() async {
    final sText = sistolicaController.text.trim();
    final dText = diastolicaController.text.trim();
    if (sText.isEmpty || dText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ingresa sistólica y diastólica'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    final s = int.tryParse(sText) ?? 0;
    final d = int.tryParse(dText) ?? 0;
    setState(() => guardandoPresion = true);
    try {
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
      try {
        await AlertasService.evaluarPresion(uid: widget.uid, sistolica: s, diastolica: d);
      } catch (e) {
        debugPrint('Alerta presión falló: $e');
      }
      if (mounted) {
        sistolicaController.clear();
        diastolicaController.clear();
        setState(() => semanaSeleccionada = DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Presión arterial registrada correctamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al guardar presión. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => guardandoPresion = false);
    }
  }

  String _fechaLegible(DateTime fecha) {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day} ${meses[fecha.month - 1]} — $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    final inicioSemana = _inicioDeSemana(semanaSeleccionada);
    final finSemana = _finDeSemana(semanaSeleccionada);
    final inicioSemanaSiguiente = _inicioSemanaSiguiente(semanaSeleccionada);

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
          style: const TextStyle(color: azulOscuro, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: azulOscuro,
          unselectedLabelColor: Colors.grey,
          indicatorColor: azul,
          tabs: const [
            Tab(icon: Icon(Icons.bloodtype_outlined), text: 'Glucosa'),
            Tab(icon: Icon(Icons.favorite_outline), text: 'Presión'),
            Tab(icon: Icon(Icons.healing_outlined), text: 'Molestias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabGlucosa(
            uid: widget.uid, soloLectura: widget.soloLectura,
            glucosaController: glucosaController, momentoMedicion: momentoMedicion,
            momentos: momentos, guardando: guardandoGlucosa,
            onMomentoChanged: (val) => setState(() => momentoMedicion = val),
            onGuardar: guardarGlucosa,
            fechaLegible: _fechaLegible,
            inicioSemana: inicioSemana, finSemana: finSemana,
            inicioSemanaSiguiente: inicioSemanaSiguiente,
            textoSemana: _textoSemana(semanaSeleccionada),
            onSemanaAnterior: _semanaAnterior, onSemanaSiguiente: _semanaSiguiente,
            esSemanaActual: _esSemanaActual(),
          ),
          _TabPresion(
            uid: widget.uid, soloLectura: widget.soloLectura,
            sistolicaController: sistolicaController, diastolicaController: diastolicaController,
            guardando: guardandoPresion, onGuardar: guardarPresion,
            colorPresion: _colorPresion, mensajePresion: _mensajePresion,
            nivelPresionInt: _nivelPresionInt, fechaLegible: _fechaLegible,
            inicioSemana: inicioSemana, finSemana: finSemana,
            inicioSemanaSiguiente: inicioSemanaSiguiente,
            textoSemana: _textoSemana(semanaSeleccionada),
            onSemanaAnterior: _semanaAnterior, onSemanaSiguiente: _semanaSiguiente,
            esSemanaActual: _esSemanaActual(),
          ),
          _TabMolestias(
            uid: widget.uid, soloLectura: widget.soloLectura,
            fechaLegible: _fechaLegible, inicioSemana: inicioSemana,
            inicioSemanaSiguiente: inicioSemanaSiguiente,
            textoSemana: _textoSemana(semanaSeleccionada),
            onSemanaAnterior: _semanaAnterior, onSemanaSiguiente: _semanaSiguiente,
            esSemanaActual: _esSemanaActual(),
          ),
        ],
      ),
    );
  }
}

// ─── SELECTOR DE SEMANA ───────────────────────────────────────────────────────

class _SelectorSemana extends StatelessWidget {
  final String textoSemana;
  final VoidCallback onSemanaAnterior;
  final VoidCallback onSemanaSiguiente;
  final bool esSemanaActual;

  const _SelectorSemana({
    required this.textoSemana, required this.onSemanaAnterior,
    required this.onSemanaSiguiente, required this.esSemanaActual,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onSemanaAnterior, icon: const Icon(Icons.chevron_left, color: azul)),
              Expanded(
                child: Column(
                  children: [
                    Text(textoSemana, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: azulOscuro)),
                    const SizedBox(height: 2),
                    const Text('Lunes a domingo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: esSemanaActual ? null : onSemanaSiguiente,
                icon: Icon(Icons.chevron_right, color: esSemanaActual ? Colors.grey.shade300 : azul),
              ),
            ],
          ),
          if (!esSemanaActual) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(20)),
              child: const Text('Estás viendo una semana anterior',
                  style: TextStyle(fontSize: 11, color: Color(0xFF2C3E6B))),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── TAB MOLESTIAS ────────────────────────────────────────────────────────────

class _TabMolestias extends StatefulWidget {
  final String uid;
  final bool soloLectura;
  final String Function(DateTime) fechaLegible;
  final DateTime inicioSemana;
  final DateTime inicioSemanaSiguiente;
  final String textoSemana;
  final VoidCallback onSemanaAnterior;
  final VoidCallback onSemanaSiguiente;
  final bool esSemanaActual;

  const _TabMolestias({
    required this.uid, required this.soloLectura, required this.fechaLegible,
    required this.inicioSemana, required this.inicioSemanaSiguiente,
    required this.textoSemana, required this.onSemanaAnterior,
    required this.onSemanaSiguiente, required this.esSemanaActual,
  });

  @override
  State<_TabMolestias> createState() => _TabMolestiaState();
}

class _TabMolestiaState extends State<_TabMolestias> {
  final notaController = TextEditingController();
  String? pieAfectado;
  List<String> tiposMolestia = [];
  int nivelDolor = 0;
  bool guardando = false;

  final List<String> opcionesPie = ['Pie izquierdo', 'Pie derecho', 'Ambos pies'];
  final List<String> opcionesTipo = [
    'Ardor', 'Entumecimiento', 'Herida o llaga',
    'Hinchazón', 'Cambio de color', 'Dolor al caminar', 'Otra',
  ];

  @override
  void dispose() { notaController.dispose(); super.dispose(); }

  Future<void> _guardarMolestia() async {
    if (pieAfectado == null || tiposMolestia.isEmpty || nivelDolor == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Selecciona el pie, al menos un tipo de molestia y el nivel de dolor'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => guardando = true);
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('molestiaRegistros')
          .add({
        'pie': pieAfectado,
        'tipo': tiposMolestia.join(', '),
        'nivelDolor': nivelDolor,
        'nota': notaController.text.trim(),
        'fechaHora': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        notaController.clear();
        setState(() { pieAfectado = null; tiposMolestia = []; nivelDolor = 0; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Molestia registrada correctamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al guardar. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Color _colorDolor(int n) {
    if (n <= 3) return Colors.green;
    if (n <= 6) return Colors.orange;
    return Colors.redAccent;
  }

  String _etiquetaDolor(int n) {
    if (n == 0) return 'Sin seleccionar';
    if (n <= 3) return 'Leve';
    if (n <= 6) return 'Moderado';
    return 'Intenso';
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios').doc(widget.uid).collection('molestiaRegistros')
          .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.inicioSemana))
          .where('fechaHora', isLessThan: Timestamp.fromDate(widget.inicioSemanaSiguiente))
          .orderBy('fechaHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final registros = snapshot.data?.docs ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectorSemana(
                textoSemana: widget.textoSemana,
                onSemanaAnterior: widget.onSemanaAnterior,
                onSemanaSiguiente: widget.onSemanaSiguiente,
                esSemanaActual: widget.esSemanaActual,
              ),
              const SizedBox(height: 20),
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
                      const Text('Registrar molestia en el pie',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
                      const SizedBox(height: 16),
                      const Text('Pie afectado', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: opcionesPie.map((opcion) {
                          final sel = pieAfectado == opcion;
                          return ChoiceChip(
                            label: Text(opcion), selected: sel,
                            onSelected: (_) => setState(() => pieAfectado = opcion),
                            selectedColor: const Color(0xFFEEF3FB),
                            labelStyle: TextStyle(
                              color: sel ? azulOscuro : Colors.grey,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(color: sel ? azul : Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text('Tipo de molestia (puedes elegir varias)',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: opcionesTipo.map((opcion) {
                          final sel = tiposMolestia.contains(opcion);
                          return FilterChip(
                            label: Text(opcion), selected: sel,
                            onSelected: (_) {
                              setState(() {
                                if (sel) { tiposMolestia.remove(opcion); }
                                else { tiposMolestia.add(opcion); }
                              });
                            },
                            selectedColor: const Color(0xFFEEF3FB),
                            labelStyle: TextStyle(
                              color: sel ? azulOscuro : Colors.grey,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(color: sel ? azul : Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            checkmarkColor: azul,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nivel de dolor (1–10)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          if (nivelDolor > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _colorDolor(nivelDolor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$nivelDolor — ${_etiquetaDolor(nivelDolor)}',
                                  style: TextStyle(fontSize: 12, color: _colorDolor(nivelDolor), fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Slider(
                        value: nivelDolor.toDouble(), min: 0, max: 10, divisions: 10,
                        activeColor: nivelDolor == 0 ? Colors.grey.shade300 : _colorDolor(nivelDolor),
                        inactiveColor: Colors.grey.shade200,
                        label: nivelDolor == 0 ? '—' : '$nivelDolor',
                        onChanged: (val) => setState(() => nivelDolor = val.toInt()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Sin dolor', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Muy intenso', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Descripción (opcional)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notaController, maxLines: 3, maxLength: 300,
                        decoration: InputDecoration(
                          hintText: 'Describe cómo se siente o cualquier detalle que quieras agregar...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: ElevatedButton(
                          onPressed: guardando ? null : _guardarMolestia,
                          style: ElevatedButton.styleFrom(backgroundColor: azul,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: guardando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Guardar molestia', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text('Molestias registradas esta semana',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: azul))
              else if (registros.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(20),
                  child: Text(
                    widget.soloLectura
                        ? 'El paciente no registró molestias esta semana'
                        : 'No hay molestias registradas esta semana',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  )))
              else
                ...registros.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = data['fechaHora'] != null
                      ? (data['fechaHora'] as dynamic).toDate().toLocal() : DateTime.now();
                  final nivel = data['nivelDolor'] ?? 0;
                  final color = _colorDolor(nivel);
                  final nota = (data['nota'] ?? '').toString().trim();
                  return _MolestiaCard(
                    fecha: widget.fechaLegible(fecha), pie: data['pie'] ?? '',
                    tipo: data['tipo'] ?? '', nivelDolor: nivel,
                    etiquetaDolor: _etiquetaDolor(nivel), nota: nota, color: color,
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

// ─── CARD DE MOLESTIA ─────────────────────────────────────────────────────────

class _MolestiaCard extends StatelessWidget {
  final String fecha, pie, tipo, etiquetaDolor, nota;
  final int nivelDolor;
  final Color color;

  const _MolestiaCard({
    required this.fecha, required this.pie, required this.tipo,
    required this.nivelDolor, required this.etiquetaDolor,
    required this.nota, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const azulOscuro = Color(0xFF2C3E6B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 10, height: 60,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fecha, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(child: Text(tipo,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Dolor $nivelDolor — $etiquetaDolor',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(pie, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (nota.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(nota, style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4)),
          ],
        ])),
      ]),
    );
  }
}

// ─── TAB GLUCOSA ──────────────────────────────────────────────────────────────

class _TabGlucosa extends StatelessWidget {
  final String uid;
  final bool soloLectura;
  final TextEditingController glucosaController;
  final String? momentoMedicion;
  final List<String> momentos;
  final bool guardando;
  final ValueChanged<String?> onMomentoChanged;
  final VoidCallback onGuardar;
  final String Function(DateTime) fechaLegible;
  final DateTime inicioSemana, finSemana, inicioSemanaSiguiente;
  final String textoSemana;
  final VoidCallback onSemanaAnterior, onSemanaSiguiente;
  final bool esSemanaActual;

  const _TabGlucosa({
    required this.uid, required this.soloLectura, required this.glucosaController,
    required this.momentoMedicion, required this.momentos, required this.guardando,
    required this.onMomentoChanged, required this.onGuardar,
    required this.fechaLegible, required this.inicioSemana,
    required this.finSemana, required this.inicioSemanaSiguiente, required this.textoSemana,
    required this.onSemanaAnterior, required this.onSemanaSiguiente, required this.esSemanaActual,
  });

  void _mostrarRecomendacionesGlucometros(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82, minChildSize: 0.50, maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            controller: scrollController, padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 46, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.bloodtype_outlined, color: azul, size: 24)),
                const SizedBox(width: 12),
                const Expanded(child: Text('Recomendaciones de glucómetros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: azulOscuro))),
              ]),
              const SizedBox(height: 10),
              const Text('Para que el registro de glucosa sea más estandarizado, se recomienda usar un glucómetro confiable, fácil de usar y con tiras reactivas disponibles.',
                  style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.45)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0E0E0))),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: azul, size: 20), SizedBox(width: 10),
                  Expanded(child: Text('Las opciones se sugieren por disponibilidad, facilidad para conseguir consumibles y uso práctico para pacientes.',
                      style: TextStyle(fontSize: 12.5, color: azulOscuro, height: 1.45))),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Opciones sugeridas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: azulOscuro)),
              const SizedBox(height: 12),
              _GlucometroCard(nombre: 'Accu-Chek Guide', recomendacion: 'Opción recomendada',
                descripcion: 'Buena opción para uso en casa por ser una marca reconocida y práctica para mediciones frecuentes.',
                precio: r'$380–$1,200 MXN aprox.', consumibles: 'Tiras reactivas y lancetas fáciles de encontrar.',
                dondeEncontrarlo: 'Disponible en farmacias, tiendas en línea y algunos distribuidores de equipo médico.'),
              const SizedBox(height: 12),
              _GlucometroCard(nombre: 'OneTouch Select Plus Flex', recomendacion: 'Opción recomendada',
                descripcion: 'Alternativa útil para llevar un registro constante de glucosa por su facilidad de uso.',
                precio: r'$300–$1,000 MXN aprox.', consumibles: 'Tiras reactivas disponibles en farmacias y plataformas de compra en línea.',
                dondeEncontrarlo: 'Disponible en farmacias, tiendas departamentales y tiendas en línea.'),
              const SizedBox(height: 12),
              _GlucometroCard(nombre: 'Contour Next One', recomendacion: 'Opción alternativa',
                descripcion: 'Puede considerarse como alternativa por su buena calidad y desempeño.',
                precio: r'$580–$900 MXN aprox.', consumibles: 'Tiras disponibles, aunque la disponibilidad puede variar según la tienda.',
                dondeEncontrarlo: 'Disponible en tiendas en línea, farmacias y algunos puntos de venta.'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(16)),
                child: const Text('Recomendación final: se sugiere priorizar Accu-Chek Guide u OneTouch Select Plus Flex porque sus consumibles suelen ser fáciles de conseguir.',
                    style: TextStyle(fontSize: 12.5, color: azulOscuro, height: 1.45)),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: azul,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Entendido', style: TextStyle(color: Colors.white, fontSize: 16)),
                )),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios').doc(uid).collection('glucosaRegistros')
          .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
          .where('fechaHora', isLessThan: Timestamp.fromDate(inicioSemanaSiguiente))
          .orderBy('fechaHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final registros = snapshot.data?.docs ?? [];
        final listaOrdenada = registros.reversed.toList();
        final datosGrafica = listaOrdenada.asMap().entries.map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          return FlSpot(e.key.toDouble(), (data['valor'] ?? 0).toDouble());
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SelectorSemana(textoSemana: textoSemana, onSemanaAnterior: onSemanaAnterior,
                onSemanaSiguiente: onSemanaSiguiente, esSemanaActual: esSemanaActual),
            const SizedBox(height: 20),
            if (!soloLectura) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Registrar glucosa',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
                  const SizedBox(height: 16),
                  const Text('Glucosa (mg/dL)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  // Campo de glucosa SIN feedback de color (Opción A)
                  TextField(
                    controller: glucosaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ej. 120',
                      prefixIcon: const Icon(Icons.bloodtype_outlined, color: azul),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Momento de medición', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: momentoMedicion,
                    decoration: InputDecoration(
                      hintText: 'Selecciona el momento',
                      prefixIcon: const Icon(Icons.access_time, color: azul),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: momentos.map((m) => DropdownMenuItem(value: m,
                        child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: onMomentoChanged,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: guardando ? null : onGuardar,
                      style: ElevatedButton.styleFrom(backgroundColor: azul,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: guardando ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar glucosa', style: TextStyle(color: Colors.white, fontSize: 16)),
                    )),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => _mostrarRecomendacionesGlucometros(context),
                      icon: const Icon(Icons.info_outline, size: 18, color: Color(0xFF6A93BE)),
                      label: const Text('Ver recomendaciones',
                          style: TextStyle(color: Color(0xFF6A93BE), fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6A93BE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                ]),
              ),
              const SizedBox(height: 24),
            ],
            if (datosGrafica.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Evolución de glucosa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: azulOscuro)),
                  const SizedBox(height: 4),
                  Text('Registros de esta semana (${registros.length})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(height: 180, child: LineChart(LineChartData(
                    minY: 50, maxY: 250,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50,
                        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 50,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 50, y2: 70, color: Colors.red.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 70, y2: 130, color: Colors.green.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 130, y2: 180, color: Colors.orange.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 180, y2: 250, color: Colors.red.withOpacity(0.08)),
                    ]),
                    lineBarsData: [LineChartBarData(
                      spots: datosGrafica, isCurved: true, color: azul, barWidth: 2.5,
                      dotData: FlDotData(show: true, getDotPainter: (spot, _, __, ___) {
                        return FlDotCirclePainter(radius: 4, color: azul, strokeWidth: 1.5, strokeColor: Colors.white);
                      }),
                      belowBarData: BarAreaData(show: true, color: azul.withOpacity(0.06)),
                    )],
                  ))),
                ]),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Historial de glucosa de la semana',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator(color: azul))
            else if (registros.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Text(
                  soloLectura ? 'El paciente no registró glucosa esta semana' : 'No hay registros de glucosa esta semana',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                )))
            else
              // Historial SIN color ni badge de estado (Opción A)
              ...registros.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = data['fechaHora'] != null
                    ? (data['fechaHora'] as dynamic).toDate().toLocal() : DateTime.now();
                final valor = (data['valor'] ?? 0).toDouble();
                final momento = data['momentoMedicion'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0))),
                  child: Row(children: [
                    Container(width: 10, height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A93BE),
                          borderRadius: BorderRadius.circular(5),
                        )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fechaLegible(fecha), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${valor.toStringAsFixed(0)} mg/dL',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E6B))),
                      if (momento.isNotEmpty)
                        Text(momento, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                  ]),
                );
              }),
            const SizedBox(height: 30),
          ]),
        );
      },
    );
  }
}

// ─── TAB PRESIÓN ──────────────────────────────────────────────────────────────

class _TabPresion extends StatelessWidget {
  final String uid;
  final bool soloLectura;
  final TextEditingController sistolicaController, diastolicaController;
  final bool guardando;
  final VoidCallback onGuardar;
  final Color Function(int, int) colorPresion;
  final String Function(int, int) mensajePresion;
  final int Function(int, int) nivelPresionInt;
  final String Function(DateTime) fechaLegible;
  final DateTime inicioSemana, finSemana, inicioSemanaSiguiente;
  final String textoSemana;
  final VoidCallback onSemanaAnterior, onSemanaSiguiente;
  final bool esSemanaActual;

  const _TabPresion({
    required this.uid, required this.soloLectura, required this.sistolicaController,
    required this.diastolicaController, required this.guardando, required this.onGuardar,
    required this.colorPresion, required this.mensajePresion, required this.nivelPresionInt,
    required this.fechaLegible, required this.inicioSemana, required this.finSemana,
    required this.inicioSemanaSiguiente, required this.textoSemana,
    required this.onSemanaAnterior, required this.onSemanaSiguiente, required this.esSemanaActual,
  });

  void _mostrarRecomendacionesTensiometros(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82, minChildSize: 0.50, maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            controller: scrollController, padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 46, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.favorite_outline, color: azul, size: 24)),
                const SizedBox(width: 12),
                const Expanded(child: Text('Recomendaciones de baumanómetros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: azulOscuro))),
              ]),
              const SizedBox(height: 10),
              const Text('Para registrar la presión arterial de forma más constante, se recomienda usar un baumanómetro automático de brazo, sencillo de utilizar y con brazalete cómodo.',
                  style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.45)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0E0E0))),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: azul, size: 20), SizedBox(width: 10),
                  Expanded(child: Text('Se recomienda priorizar equipos de brazo sobre los de muñeca, ya que suelen ser más prácticos para mediciones constantes en casa.',
                      style: TextStyle(fontSize: 12.5, color: azulOscuro, height: 1.45))),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Opciones sugeridas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: azulOscuro)),
              const SizedBox(height: 12),
              _TensiometroCard(nombre: 'Omron HEM-7120', recomendacion: 'Mejor calidad-precio',
                descripcion: 'Muy buena marca, sencillo, automático y confiable para uso en casa.',
                precio: 'Precio variable según tienda.',
                consumibles: 'No requiere consumibles frecuentes; solo pilas o adaptador según el modelo.',
                dondeEncontrarlo: 'Disponible en farmacias, tiendas departamentales y tiendas en línea.'),
              const SizedBox(height: 12),
              _TensiometroCard(nombre: 'Omron HEM-7156T', recomendacion: 'Más completo',
                descripcion: 'Mejor si se busca algo más moderno y con mejor brazalete.',
                precio: 'Precio variable según tienda.',
                consumibles: 'No requiere consumibles frecuentes; se recomienda revisar el estado del brazalete con el uso.',
                dondeEncontrarlo: 'Disponible en tiendas en línea, farmacias y distribuidores de equipos médicos.'),
              const SizedBox(height: 12),
              _TensiometroCard(nombre: 'Beurer BM28', recomendacion: 'Bueno y económico',
                descripcion: 'Buena opción si se quiere algo funcional sin gastar tanto.',
                precio: 'Precio variable según tienda.',
                consumibles: 'No requiere consumibles frecuentes; funciona con pilas y brazalete de brazo.',
                dondeEncontrarlo: 'Disponible en tiendas en línea y algunas tiendas de equipos de salud.'),
              const SizedBox(height: 12),
              _TensiometroCard(nombre: 'Microlife BP3AG1', recomendacion: 'Más barato',
                descripcion: 'Puede servir como opción básica, aunque si el presupuesto alcanza se prioriza Omron.',
                precio: 'Precio variable según tienda.',
                consumibles: 'No requiere consumibles frecuentes; se recomienda verificar que incluya brazalete adecuado.',
                dondeEncontrarlo: 'Disponible principalmente en tiendas en línea y algunos distribuidores.'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(16)),
                child: const Text('Recomendación final: se sugiere priorizar Omron HEM-7120 u Omron HEM-7156T. Se evitarían baumanómetros de muñeca, salvo que sea por comodidad o viaje.',
                    style: TextStyle(fontSize: 12.5, color: azulOscuro, height: 1.45)),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: azul,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Entendido', style: TextStyle(color: Colors.white, fontSize: 16)),
                )),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios').doc(uid).collection('presionRegistros')
          .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
          .where('fechaHora', isLessThan: Timestamp.fromDate(inicioSemanaSiguiente))
          .orderBy('fechaHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final registros = snapshot.data?.docs ?? [];
        final listaOrdenada = registros.reversed.toList();
        final spotsSistolica = listaOrdenada.asMap().entries.map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          return FlSpot(e.key.toDouble(), (data['sistolica'] ?? 0).toDouble());
        }).toList();
        final spotsDiastolica = listaOrdenada.asMap().entries.map((e) {
          final data = e.value.data() as Map<String, dynamic>;
          return FlSpot(e.key.toDouble(), (data['diastolica'] ?? 0).toDouble());
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SelectorSemana(textoSemana: textoSemana, onSemanaAnterior: onSemanaAnterior,
                onSemanaSiguiente: onSemanaSiguiente, esSemanaActual: esSemanaActual),
            const SizedBox(height: 20),
            if (!soloLectura) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Registrar presión arterial',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
                  const SizedBox(height: 16),
                  const Text('Presión arterial (mmHg)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  StatefulBuilder(builder: (context, setLocal) {
                    final s = int.tryParse(sistolicaController.text.trim());
                    final d = int.tryParse(diastolicaController.text.trim());
                    return Column(children: [
                      Row(children: [
                        Expanded(child: TextField(
                          controller: sistolicaController, keyboardType: TextInputType.number,
                          onChanged: (_) => setLocal(() {}),
                          decoration: InputDecoration(hintText: 'Sistólica',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('/', style: TextStyle(fontSize: 22, color: Colors.grey))),
                        Expanded(child: TextField(
                          controller: diastolicaController, keyboardType: TextInputType.number,
                          onChanged: (_) => setLocal(() {}),
                          decoration: InputDecoration(hintText: 'Diastólica',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        )),
                      ]),
                      if (s != null && d != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: colorPresion(s, d).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Icon(Icons.circle, color: colorPresion(s, d), size: 12),
                            const SizedBox(width: 8),
                            Expanded(child: Text(mensajePresion(s, d),
                                style: TextStyle(fontSize: 13, color: colorPresion(s, d), fontWeight: FontWeight.w500))),
                          ]),
                        ),
                      ],
                    ]);
                  }),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: guardando ? null : onGuardar,
                      style: ElevatedButton.styleFrom(backgroundColor: azul,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: guardando ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar presión', style: TextStyle(color: Colors.white, fontSize: 16)),
                    )),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => _mostrarRecomendacionesTensiometros(context),
                      icon: const Icon(Icons.info_outline, size: 18, color: Color(0xFF6A93BE)),
                      label: const Text('Ver recomendaciones',
                          style: TextStyle(color: Color(0xFF6A93BE), fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6A93BE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                ]),
              ),
              const SizedBox(height: 24),
            ],
            if (spotsSistolica.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Evolución de presión arterial',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: azulOscuro)),
                  const SizedBox(height: 4),
                  Text('Registros de esta semana (${registros.length})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(height: 180, child: LineChart(LineChartData(
                    minY: 50, maxY: 180,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 30,
                        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 30,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 50, y2: 130, color: Colors.green.withOpacity(0.06)),
                      HorizontalRangeAnnotation(y1: 130, y2: 140, color: Colors.orange.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 140, y2: 180, color: Colors.red.withOpacity(0.08)),
                    ]),
                    lineBarsData: [
                      LineChartBarData(spots: spotsSistolica, isCurved: true, color: const Color(0xFF6A93BE),
                          barWidth: 2.5, dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: const Color(0xFF6A93BE).withOpacity(0.06))),
                      LineChartBarData(spots: spotsDiastolica, isCurved: true, color: const Color(0xFF2C3E6B),
                          barWidth: 2, dashArray: [5, 4], dotData: FlDotData(show: true)),
                    ],
                  ))),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Leyenda(color: const Color(0xFF6A93BE), texto: 'Sistólica'),
                    const SizedBox(width: 20),
                    _Leyenda(color: const Color(0xFF2C3E6B), texto: 'Diastólica'),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Historial de presión arterial de la semana',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator(color: azul))
            else if (registros.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Text(
                  soloLectura ? 'El paciente no registró presión esta semana' : 'No hay registros de presión esta semana',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                )))
            else
              ...registros.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = data['fechaHora'] != null
                    ? (data['fechaHora'] as dynamic).toDate().toLocal() : DateTime.now();
                final s = data['sistolica'] ?? 0;
                final d = data['diastolica'] ?? 0;
                final color = _colorPorEstado(data['estado'] ?? '');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0))),
                  child: Row(children: [
                    Container(width: 10, height: 50,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fechaLegible(fecha), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('$s / $d mmHg',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(_etiquetaEstado(data['estado'] ?? ''),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                );
              }),
            const SizedBox(height: 30),
          ]),
        );
      },
    );
  }
}

// ─── AUXILIARES ───────────────────────────────────────────────────────────────

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
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(texto, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _GlucometroCard extends StatelessWidget {
  final String nombre, recomendacion, descripcion, precio, consumibles, dondeEncontrarlo;
  const _GlucometroCard({required this.nombre, required this.recomendacion, required this.descripcion,
      required this.precio, required this.consumibles, required this.dondeEncontrarlo});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.bloodtype_outlined, color: azul, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
            const SizedBox(height: 2),
            Text(recomendacion, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(descripcion, style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35)),
        const SizedBox(height: 10),
        _DetalleRecomendacion(icono: Icons.payments_outlined, titulo: 'Precio aproximado', texto: precio),
        _DetalleRecomendacion(icono: Icons.shopping_bag_outlined, titulo: 'Consumibles', texto: consumibles),
        _DetalleRecomendacion(icono: Icons.storefront_outlined, titulo: 'Dónde encontrarlo', texto: dondeEncontrarlo),
      ]),
    );
  }
}

class _TensiometroCard extends StatelessWidget {
  final String nombre, recomendacion, descripcion, precio, consumibles, dondeEncontrarlo;
  const _TensiometroCard({required this.nombre, required this.recomendacion, required this.descripcion,
      required this.precio, required this.consumibles, required this.dondeEncontrarlo});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.favorite_outline, color: azul, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: azulOscuro)),
            const SizedBox(height: 2),
            Text(recomendacion, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(descripcion, style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35)),
        const SizedBox(height: 10),
        _DetalleRecomendacion(icono: Icons.payments_outlined, titulo: 'Precio aproximado', texto: precio),
        _DetalleRecomendacion(icono: Icons.battery_full_outlined, titulo: 'Consumibles', texto: consumibles),
        _DetalleRecomendacion(icono: Icons.storefront_outlined, titulo: 'Dónde encontrarlo', texto: dondeEncontrarlo),
      ]),
    );
  }
}

class _DetalleRecomendacion extends StatelessWidget {
  final IconData icono;
  final String titulo, texto;
  const _DetalleRecomendacion({required this.icono, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, size: 17, color: azul),
        const SizedBox(width: 8),
        Expanded(child: RichText(text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
          children: [
            TextSpan(text: '$titulo: ', style: const TextStyle(fontWeight: FontWeight.bold, color: azulOscuro)),
            TextSpan(text: texto),
          ],
        ))),
      ]),
    );
  }
}