import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'galeriadefotos.dart';
import 'niveles_screen.dart';
import 'alertas_service.dart';
import 'alertas_screen.dart';
import 'cumplimiento_widget.dart';

class ExpedientePacienteScreen extends StatefulWidget {
  final String uid;
  final String nombre;

  const ExpedientePacienteScreen({
    super.key,
    required this.uid,
    required this.nombre,
  });

  @override
  State<ExpedientePacienteScreen> createState() =>
      _ExpedientePacienteScreenState();
}

class _ExpedientePacienteScreenState
    extends State<ExpedientePacienteScreen> {
  Map<String, dynamic>? datos;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .get();
    if (doc.exists) {
      setState(() {
        datos = doc.data();
        cargando = false;
      });
    }
  }

  String get iniciales {
    final partes = widget.nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : '?';
  }

  // Convierte riesgoTabla a etiqueta y color
  String _etiquetaRiesgo(String? r) {
    if (r == 'maximo') return 'Máximo';
    if (r == 'alto') return 'Alto';
    if (r == 'moderado') return 'Moderado';
    return 'Bajo';
  }

  Color _colorRiesgo(String? r) {
    if (r == 'maximo') return Colors.redAccent;
    if (r == 'alto') return Colors.orange;
    if (r == 'moderado') return Colors.amber;
    return Colors.green;
  }

  String _frecuenciaRiesgo(String? r) {
    if (r == 'maximo') return 'Próxima evaluación: 1–3 meses';
    if (r == 'alto') return 'Próxima evaluación: 3–6 meses';
    if (r == 'moderado') return 'Próxima evaluación: 6 meses';
    return 'Próxima evaluación: 1 año';
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6A93BE)),
        ),
      );
    }

    final riesgo = datos?['riesgoTabla'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // HEADER
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A93BE), Color(0xFF2C3E6B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        iniciales,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E6B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badge de riesgo en el header
                    if (riesgo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _colorRiesgo(riesgo).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _colorRiesgo(riesgo).withOpacity(0.5)),
                        ),
                        child: Text(
                          'Riesgo ${_etiquetaRiesgo(riesgo)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('Paciente activo',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  // CARD DE RIESGO Y PRÓXIMA CITA
                  if (riesgo != null) ...[
                    _CardRiesgoResumen(
                      riesgo: riesgo,
                      etiqueta: _etiquetaRiesgo(riesgo),
                      color: _colorRiesgo(riesgo),
                      frecuencia: _frecuenciaRiesgo(riesgo),
                      uid: widget.uid,
                      datos: datos!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _BotonMenu(
                    icono: Icons.monitor_heart_outlined,
                    titulo: 'Niveles del paciente',
                    subtitulo: 'Glucosa y presión arterial registrados',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NivelesScreen(
                            uid: widget.uid,
                            soloLectura: true,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _BotonMenu(
                    icono: Icons.photo_library_outlined,
                    titulo: 'Fotos del pie',
                    subtitulo: 'Registro fotográfico y observaciones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GaleriaFotosScreen(
                            uid: widget.uid,
                            esDoctor: true,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _BotonMenu(
                    icono: Icons.notifications_active_outlined,
                    titulo: 'Alertas clínicas',
                    subtitulo: 'Ver alertas generadas automáticamente',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlertasScreen(
                            uid: widget.uid,
                            nombrePaciente: widget.nombre,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _BotonMenu(
                    icono: Icons.edit_outlined,
                    titulo: 'Editar expediente',
                    subtitulo: 'Historial médico y evaluación de riesgo',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarExpedienteScreen(
                            uid: widget.uid,
                            datos: datos!,
                          ),
                        ),
                      );
                      cargarDatos();
                    },
                  ),

                  const SizedBox(height: 24),

                  // RESUMEN DEL PACIENTE
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
                          'Resumen del paciente',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E6B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoFila(
                          icono: Icons.medical_services_rounded,
                          etiqueta: 'Diagnóstico',
                          valor: datos?['diagnostico'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.warning_amber_rounded,
                          etiqueta: 'Nivel de riesgo',
                          valor: _etiquetaRiesgo(datos?['riesgoTabla']),
                          colorValor: _colorRiesgo(datos?['riesgoTabla']),
                        ),
                        _InfoFila(
                          icono: Icons.bloodtype_rounded,
                          etiqueta: 'Último HbA1c',
                          valor: datos?['hba1c'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.healing_rounded,
                          etiqueta: 'Heridas',
                          valor: datos?['heridas'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.medication_rounded,
                          etiqueta: 'Tratamiento',
                          valor: datos?['tipoTratamiento'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.colorize_rounded,
                          etiqueta: 'Usa insulina',
                          valor: datos?['usaInsulina'] == true
                              ? 'Sí'
                              : datos?['usaInsulina'] == false
                                  ? 'No'
                                  : 'Sin registrar',
                        ),
                        // Mostrar respuestas de la tabla si ya fueron llenadas
                        if (datos?['tablaRiesgo'] != null) ...[
                          const Divider(height: 24),
                          const Text(
                            'Evaluación de riesgo del pie',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E6B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoFila(
                            icono: Icons.history_edu_rounded,
                            etiqueta: '¿Historia de úlcera o amputación?',
                            valor: (datos?['tablaRiesgo']['historiaUlcera'] == true) ? 'Sí' : 'No',
                          ),
                          _InfoFila(
                            icono: Icons.monitor_heart_outlined,
                            etiqueta: 'Enfermedad Arterial Periférica (EAP)',
                            valor: (datos?['tablaRiesgo']['eap'] == true) ? 'Sí' : 'No',
                          ),
                          _InfoFila(
                            icono: Icons.touch_app_outlined,
                            etiqueta: 'Sensibilidad protectora',
                            valor: (datos?['tablaRiesgo']['sensibilidadAlterada'] == true)
                                ? 'Alterada'
                                : 'Normal',
                          ),
                          _InfoFila(
                            icono: Icons.accessibility_new_rounded,
                            etiqueta: 'Deformidad (DEF)',
                            valor: (datos?['tablaRiesgo']['deformidad'] == true) ? 'Sí' : 'No',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SEMÁFORO
                  _SemaforoRiesgo(riesgoActual: riesgo),

                  const SizedBox(height: 16),

                  EstadoCumplimientoCard(uid: widget.uid),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD DE RIESGO Y PRÓXIMA CITA ───────────────────────────────────────────

class _CardRiesgoResumen extends StatelessWidget {
  final String riesgo;
  final String etiqueta;
  final Color color;
  final String frecuencia;
  final String uid;
  final Map<String, dynamic> datos;

  const _CardRiesgoResumen({
    required this.riesgo,
    required this.etiqueta,
    required this.color,
    required this.frecuencia,
    required this.uid,
    required this.datos,
  });

  void _agendarCita(BuildContext context) async {
    DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona la próxima cita',
      confirmText: 'Agendar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A93BE),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({'proximaCita': Timestamp.fromDate(fechaSeleccionada)});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Próxima cita agendada: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximaCita = datos['proximaCita'];
    String textoCita = 'Sin cita agendada';
    if (proximaCita != null) {
      final fecha = (proximaCita as Timestamp).toDate();
      textoCita =
          'Próxima cita: ${fecha.day}/${fecha.month}/${fecha.year}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riesgo $etiqueta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      frecuencia,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                textoCita,
                style:
                    const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _agendarCita(context),
              icon: const Icon(Icons.calendar_month_outlined,
                  size: 18, color: Colors.white),
              label: const Text(
                'Asignar próxima cita',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BOTÓN MENÚ ───────────────────────────────────────────────────────────────

class _BotonMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _BotonMenu({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icono, color: const Color(0xFF6A93BE), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E6B))),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── SEMÁFORO DE RIESGO ───────────────────────────────────────────────────────

class _SemaforoRiesgo extends StatelessWidget {
  final String? riesgoActual;
  const _SemaforoRiesgo({this.riesgoActual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.traffic_rounded,
                  color: Color(0xFF6A93BE), size: 20),
              SizedBox(width: 8),
              Text(
                'Semáforo de riesgo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Calculado automáticamente según la evaluación del pie',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          _FilaSemaforo(
            color: Colors.green,
            nivel: 'Bajo (0)',
            descripcion: 'Evaluación cada 1 año. Educación para el autocuidado y calzado apropiado.',
            activo: riesgoActual == 'bajo',
          ),
          const SizedBox(height: 10),
          _FilaSemaforo(
            color: Colors.amber,
            nivel: 'Moderado (1)',
            descripcion: 'Evaluación cada 6 meses. Educación para el autocuidado y calzado apropiado.',
            activo: riesgoActual == 'moderado',
          ),
          const SizedBox(height: 10),
          _FilaSemaforo(
            color: Colors.orange,
            nivel: 'Alto (2)',
            descripcion: 'Evaluación cada 3–6 meses. Calzado especial, considerar derivar a especialista.',
            activo: riesgoActual == 'alto',
          ),
          const SizedBox(height: 10),
          _FilaSemaforo(
            color: Colors.redAccent,
            nivel: 'Máximo (3)',
            descripcion: 'Evaluación cada 1–3 meses. Referir a especialista para manejo conjunto.',
            activo: riesgoActual == 'maximo',
          ),
        ],
      ),
    );
  }
}

// ─── FILA SEMÁFORO ────────────────────────────────────────────────────────────

class _FilaSemaforo extends StatelessWidget {
  final Color color;
  final String nivel;
  final String descripcion;
  final bool activo;

  const _FilaSemaforo({
    required this.color,
    required this.nivel,
    required this.descripcion,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activo ? color.withOpacity(0.12) : color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activo ? color : color.withOpacity(0.15),
          width: activo ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(activo ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nivel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    if (activo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Actual',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(descripcion,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EDITAR EXPEDIENTE ────────────────────────────────────────────────────────

class EditarExpedienteScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> datos;

  const EditarExpedienteScreen({
    super.key,
    required this.uid,
    required this.datos,
  });

  @override
  State<EditarExpedienteScreen> createState() =>
      _EditarExpedienteScreenState();
}

class _EditarExpedienteScreenState
    extends State<EditarExpedienteScreen> {
  bool cargando = false;
  bool? usaInsulina;
  String? tipoTratamiento;

  // ── Tabla de 6 pasos ──
  bool? historiaUlcera;       // Paso 1
  bool? eap;                  // Paso 2
  bool? sensibilidadAlterada; // Paso 3
  bool? deformidad;           // Paso 4
  // Paso 5 y 6 se calculan automáticamente

  final List<String> opcionesTratamiento = [
    'Sin insulina', 'Insulina', 'Medicamento oral',
    'Insulina + medicamento oral', 'No sabe',
  ];

  late final diagnosticoController =
      TextEditingController(text: widget.datos['diagnostico'] ?? '');
  late final duracionController =
      TextEditingController(text: widget.datos['duracion'] ?? '');
  late final comorbilController =
      TextEditingController(text: widget.datos['comorbilidades'] ?? '');
  late final hba1cController =
      TextEditingController(text: widget.datos['hba1c'] ?? '');
  late final heridasController =
      TextEditingController(text: widget.datos['heridas'] ?? '');
  late final alergiasController =
      TextEditingController(text: widget.datos['alergias'] ?? '');
  late final tabaquismoController =
      TextEditingController(text: widget.datos['tabaquismo'] ?? '');
  late final dislipidemiasController =
      TextEditingController(text: widget.datos['dislipidemias'] ?? '');
  late final actividadController =
      TextEditingController(text: widget.datos['actividadFisica'] ?? '');
  late final notasMedicoController =
      TextEditingController(text: widget.datos['notasMedico'] ?? '');

  @override
  void initState() {
    super.initState();
    usaInsulina = widget.datos['usaInsulina'];
    tipoTratamiento = widget.datos['tipoTratamiento'];

    // Cargar respuestas previas de la tabla
    final tabla = widget.datos['tablaRiesgo'];
    if (tabla != null) {
      historiaUlcera = tabla['historiaUlcera'];
      eap = tabla['eap'];
      sensibilidadAlterada = tabla['sensibilidadAlterada'];
      deformidad = tabla['deformidad'];
    }
  }

  @override
  void dispose() {
    diagnosticoController.dispose();
    duracionController.dispose();
    comorbilController.dispose();
    hba1cController.dispose();
    heridasController.dispose();
    alergiasController.dispose();
    tabaquismoController.dispose();
    dislipidemiasController.dispose();
    actividadController.dispose();
    notasMedicoController.dispose();
    super.dispose();
  }

  // ── Lógica de la tabla de 6 pasos ──
  String? _calcularRiesgo() {
    if (historiaUlcera == null) return null;

    // Paso 1: historia de úlcera → Máximo directo
    if (historiaUlcera == true) return 'maximo';

    // Paso 2: EAP
    if (eap == null) return null;
    if (eap == true) return 'alto';

    // Paso 3: sensibilidad
    if (sensibilidadAlterada == null) return null;
    if (sensibilidadAlterada == false) return 'bajo';

    // Paso 4: deformidad
    if (deformidad == null) return null;
    if (deformidad == false) return 'moderado';
    return 'alto';
  }

  String _etiquetaRiesgo(String? r) {
    if (r == 'maximo') return 'Máximo (3)';
    if (r == 'alto') return 'Alto (2)';
    if (r == 'moderado') return 'Moderado (1)';
    if (r == 'bajo') return 'Bajo (0)';
    return 'Selecciona el Paso 1 para comenzar';
  }

  Color _colorRiesgo(String? r) {
    if (r == 'maximo') return Colors.redAccent;
    if (r == 'alto') return Colors.orange;
    if (r == 'moderado') return Colors.amber;
    if (r == 'bajo') return Colors.green;
    return Colors.grey;
  }

  String _recomendacionRiesgo(String? r) {
    if (r == 'maximo') {
      return 'Evaluación cada 1–3 meses. Intensificar educación para el autocuidado. Calzado especial. Referir a especialista para manejo conjunto.';
    }
    if (r == 'alto') {
      return 'Evaluación cada 3–6 meses. Intensificar educación para el autocuidado. Calzado especial si se requiere. Considerar derivar a especialista.';
    }
    if (r == 'moderado') {
      return 'Evaluación cada 6 meses. Educación para el autocuidado. Calzado apropiado.';
    }
    if (r == 'bajo') {
      return 'Evaluación cada 1 año. Educación para el autocuidado. Calzado apropiado.';
    }
    return '';
  }

  Future<void> guardar() async {
    if (usaInsulina == null || tipoTratamiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa la sección de tratamiento'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final riesgoCalculado = _calcularRiesgo();
    if (riesgoCalculado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor responde al menos el Paso 1 de la evaluación del pie'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => cargando = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .update({
      'diagnostico': diagnosticoController.text.trim(),
      'duracion': duracionController.text.trim(),
      'comorbilidades': comorbilController.text.trim(),
      'hba1c': hba1cController.text.trim(),
      'heridas': heridasController.text.trim(),
      'alergias': alergiasController.text.trim(),
      'tabaquismo': tabaquismoController.text.trim(),
      'dislipidemias': dislipidemiasController.text.trim(),
      'actividadFisica': actividadController.text.trim(),
      'notasMedico': notasMedicoController.text.trim(),
      'usaInsulina': usaInsulina,
      'tipoTratamiento': tipoTratamiento,
      // Tabla de 6 pasos
      'tablaRiesgo': {
        'historiaUlcera': historiaUlcera,
        'eap': eap,
        'sensibilidadAlterada': sensibilidadAlterada,
        'deformidad': deformidad,
      },
      // Riesgo calculado automáticamente
      'riesgoTabla': riesgoCalculado,
      'fechaEvaluacion': FieldValue.serverTimestamp(),
    });

    try {
      await AlertasService.evaluarHeridas(
        uid: widget.uid,
        heridas: heridasController.text.trim(),
      );
    } catch (e) {
      debugPrint('Alerta heridas falló: $e');
    }

    if (mounted) Navigator.pop(context);
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);
    final riesgoCalculado = _calcularRiesgo();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: azul),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar expediente',
          style: TextStyle(
              color: azul, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Diagnóstico ──
            _seccion('Diagnóstico y evolución', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Diagnóstico principal',
                icono: Icons.medical_services_outlined,
                controller: diagnosticoController),
            const SizedBox(height: 12),
            _Campo(label: 'Tiempo desde el diagnóstico (ej. 5 años)',
                icono: Icons.history_rounded,
                controller: duracionController),
            const SizedBox(height: 12),
            _Campo(label: 'Último HbA1c (ej. 7.4%)',
                icono: Icons.bloodtype_outlined,
                controller: hba1cController),
            const SizedBox(height: 24),

            // ── Tratamiento ──
            _seccion('Tratamiento de diabetes', azulOscuro),
            const SizedBox(height: 12),
            const Text('¿Usa insulina?',
                style: TextStyle(fontSize: 14, color: Color(0xFF2C3E6B))),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sí', style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: usaInsulina,
                    activeColor: azul,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => usaInsulina = val),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No', style: TextStyle(fontSize: 14)),
                    value: false,
                    groupValue: usaInsulina,
                    activeColor: azul,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => usaInsulina = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tipo de tratamiento',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E6B),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: tipoTratamiento,
              decoration: InputDecoration(
                hintText: 'Selecciona una opción',
                prefixIcon:
                    const Icon(Icons.medication_outlined, color: azul),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: opcionesTratamiento.map((opcion) {
                return DropdownMenuItem(
                    value: opcion,
                    child: Text(opcion,
                        style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (val) => setState(() => tipoTratamiento = val),
            ),

            if (usaInsulina == true) ...[
              const SizedBox(height: 10),
              _infoBox('Este paciente usa insulina. Se recomienda monitoreo de glucosa varias veces al día.',
                  Icons.info_outline, const Color(0xFFEEF3FB), azul),
            ],
            if (usaInsulina == false) ...[
              const SizedBox(height: 10),
              _infoBox('Este paciente no usa insulina. Se recomienda un recordatorio diario de glucosa.',
                  Icons.check_circle_outline, const Color(0xFFF0FFF4), Colors.green),
            ],

            const SizedBox(height: 24),

            // ── Condiciones asociadas ──
            _seccion('Condiciones asociadas', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Comorbilidades',
                icono: Icons.warning_amber_outlined,
                controller: comorbilController),
            const SizedBox(height: 12),
            _Campo(label: 'Heridas actuales o pasadas',
                icono: Icons.healing_outlined,
                controller: heridasController),
            const SizedBox(height: 12),
            _Campo(label: 'Alergias',
                icono: Icons.medication_outlined,
                controller: alergiasController),
            const SizedBox(height: 12),
            _Campo(label: 'Dislipidemias (colesterol, triglicéridos)',
                icono: Icons.favorite_outline,
                controller: dislipidemiasController),
            const SizedBox(height: 24),

            // ── Estilo de vida ──
            _seccion('Estilo de vida', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Tabaquismo',
                icono: Icons.smoking_rooms_rounded,
                controller: tabaquismoController),
            const SizedBox(height: 12),
            _Campo(label: 'Actividad física',
                icono: Icons.directions_run_rounded,
                controller: actividadController),

            const SizedBox(height: 24),

            // ── TABLA DE 6 PASOS ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fact_check_outlined,
                            color: azul, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Evaluación de riesgo del pie',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: azulOscuro)),
                            Text('Tabla de 6 pasos — IWGDF',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // PASO 1
                  _PasoTabla(
                    numero: 1,
                    pregunta: '¿Historia de úlcera o amputación?',
                    descripcion: 'Incluye cualquier úlcera o amputación previa en el pie.',
                    valor: historiaUlcera,
                    onChanged: (val) => setState(() => historiaUlcera = val),
                  ),

                  const SizedBox(height: 14),

                  // PASO 2 — solo si historiaUlcera == false
                  AnimatedOpacity(
                    opacity: historiaUlcera == false ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 250),
                    child: _PasoTabla(
                      numero: 2,
                      pregunta: 'Enfermedad Arterial Periférica (EAP)',
                      descripcion: 'Ausencia de pulso pedio o tibial posterior.',
                      valor: eap,
                      onChanged: historiaUlcera == false
                          ? (val) => setState(() => eap = val)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // PASO 3 — solo si eap == false
                  AnimatedOpacity(
                    opacity: (historiaUlcera == false && eap == false) ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 250),
                    child: _PasoTabla(
                      numero: 3,
                      pregunta: 'Sensibilidad protectora',
                      descripcion: 'Usando monofilamento de 10g en 8 puntos (4 por pie).',
                      valor: sensibilidadAlterada,
                      etiquetaSi: 'Alterada',
                      etiquetaNo: 'Normal',
                      onChanged: (historiaUlcera == false && eap == false)
                          ? (val) => setState(() => sensibilidadAlterada = val)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // PASO 4 — solo si sensibilidadAlterada == true
                  AnimatedOpacity(
                    opacity: (historiaUlcera == false && eap == false &&
                            sensibilidadAlterada == true)
                        ? 1.0
                        : 0.35,
                    duration: const Duration(milliseconds: 250),
                    child: _PasoTabla(
                      numero: 4,
                      pregunta: 'Deformidad (DEF)',
                      descripcion:
                          'Dedos en garra, en martillo, prominencia metatarsiana, hallux valgus, artropatía de Charcot.',
                      valor: deformidad,
                      onChanged: (historiaUlcera == false &&
                              eap == false &&
                              sensibilidadAlterada == true)
                          ? (val) => setState(() => deformidad = val)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // RESULTADO AUTOMÁTICO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _colorRiesgo(riesgoCalculado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _colorRiesgo(riesgoCalculado)
                              .withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_outlined,
                                color: _colorRiesgo(riesgoCalculado),
                                size: 18),
                            const SizedBox(width: 8),
                            const Text('Resultado automático',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Grupo de riesgo: ${_etiquetaRiesgo(riesgoCalculado)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _colorRiesgo(riesgoCalculado),
                          ),
                        ),
                        if (riesgoCalculado != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _recomendacionRiesgo(riesgoCalculado),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Notas del médico ──
            _seccion('Notas y retroalimentación', azulOscuro),
            const SizedBox(height: 12),
            const Text(
              'Observaciones e indicaciones para el paciente',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E6B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: notasMedicoController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Observaciones clínicas, indicaciones para el paciente, seguimiento...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.notes_outlined, color: azul),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar cambios',
                        style: TextStyle(
                            color: Colors.white, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Color color) {
    return Text(titulo,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: color, fontSize: 15));
  }

  Widget _infoBox(
      String texto, IconData icono, Color fondo, Color iconoColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: fondo, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icono, color: iconoColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF2C3E6B))),
          ),
        ],
      ),
    );
  }
}

// ─── PASO DE LA TABLA ─────────────────────────────────────────────────────────

class _PasoTabla extends StatelessWidget {
  final int numero;
  final String pregunta;
  final String descripcion;
  final bool? valor;
  final String etiquetaSi;
  final String etiquetaNo;
  final ValueChanged<bool>? onChanged;

  const _PasoTabla({
    required this.numero,
    required this.pregunta,
    required this.descripcion,
    required this.valor,
    this.etiquetaSi = 'Sí',
    this.etiquetaNo = 'No',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: azul,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$numero',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pregunta,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: azulOscuro)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(descripcion,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onChanged != null ? () => onChanged!(false) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: valor == false
                          ? azul
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: valor == false
                              ? azul
                              : Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      etiquetaNo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: valor == false ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onChanged != null ? () => onChanged!(true) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: valor == true ? azul : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: valor == true
                              ? azul
                              : Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      etiquetaSi,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: valor == true ? Colors.white : Colors.grey,
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
  }
}

// ─── BOTÓN RIESGO (ya no se usa, se deja por compatibilidad) ─────────────────

class _BotonRiesgo extends StatelessWidget {
  final String label;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonRiesgo({
    required this.label,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: seleccionado ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}

// ─── CAMPO DE TEXTO ───────────────────────────────────────────────────────────

class _Campo extends StatelessWidget {
  final String label;
  final IconData icono;
  final TextEditingController controller;

  const _Campo({
    required this.label,
    required this.icono,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E6B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Escribe aquí',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
            prefixIcon: Icon(
              icono,
              color: const Color(0xFF6A93BE),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── INFO FILA ────────────────────────────────────────────────────────────────

class _InfoFila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;

  const _InfoFila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icono, color: const Color(0xFF6A93BE), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(valor,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorValor ?? const Color(0xFF2C3E6B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}