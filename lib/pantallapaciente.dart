import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'galeriadefotos.dart';
import 'niveles_screen.dart';
import 'cumplimiento_widget.dart';
import 'chat_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? datos;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        datos = doc.data();
        cargando = false;
      });
    }
  }

  String get iniciales {
    final nombre = datos?['nombre'] ?? '';
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    } else if (partes.isNotEmpty && partes[0].isNotEmpty) {
      return partes[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InicioScreen()),
        (route) => false,
      );
    }
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

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Header ──
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        iniciales,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E6B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      datos?['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Paciente activo',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
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

                  // ── Mi información ──
                  _BotonMenu(
                    icono: Icons.person_outline,
                    titulo: 'Mi información general',
                    subtitulo: 'Datos personales e historial médico',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InformacionGeneralScreen(
                            datos: datos!,
                            onActualizar: cargarDatos,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Mis niveles ──
                  _BotonMenu(
                    icono: Icons.monitor_heart_outlined,
                    titulo: 'Mis niveles',
                    subtitulo: 'Glucosa y presión arterial',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NivelesScreen(uid: uid),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Mis fotos ──
                  _BotonMenu(
                    icono: Icons.photo_library_outlined,
                    titulo: 'Mis fotos del pie',
                    subtitulo: 'Registro fotográfico y observaciones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GaleriaFotosScreen(
                            uid: uid,
                            esDoctor: false,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // ✅ Mensajes con el doctor — con indicador de nuevos
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(uid)
                        .collection('chatDoctor')
                        .where('enviadoPor', isEqualTo: 'doctor')
                        .where('leido', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapChat) {
                      final noLeidos =
                          snapChat.data?.docs.length ?? 0;

                      return GestureDetector(
                        onTap: () {
                          final nombre =
                              datos?['nombre'] ?? 'Paciente';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDoctorScreen(
                                pacienteId: uid,
                                nombrePaciente: nombre,
                                miUid: uid,
                                miNombre: nombre,
                                miRol: 'paciente',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: noLeidos > 0
                                  ? const Color(0xFF6A93BE)
                                      .withOpacity(0.5)
                                  : const Color(0xFFE0E0E0),
                              width: noLeidos > 0 ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF3FB),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.chat_outlined,
                                  color: Color(0xFF6A93BE),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mensajes con el doctor',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E6B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      noLeidos > 0
                                          ? '¡Tienes $noLeidos mensaje${noLeidos > 1 ? 's' : ''} nuevo${noLeidos > 1 ? 's' : ''}!'
                                          : 'Chat directo con tu médico',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: noLeidos > 0
                                            ? const Color(0xFF6A93BE)
                                            : Colors.grey,
                                        fontWeight: noLeidos > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ✅ Contador o chevron
                              if (noLeidos > 0)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6A93BE),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$noLeidos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // ✅ Estado de cumplimiento
                  EstadoCumplimientoCard(uid: uid),

                  const SizedBox(height: 30),

                  // ── Cerrar sesión ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: cerrarSesion,
                      icon: const Icon(Icons.logout,
                          color: Colors.redAccent),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                            color: Colors.redAccent, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

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

// ═══════════════════════════════════════════════════════════════════════════════
// BOTÓN MENÚ
// ═══════════════════════════════════════════════════════════════════════════════
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
              child: Icon(icono,
                  color: const Color(0xFF6A93BE), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E6B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFORMACIÓN GENERAL
// ═══════════════════════════════════════════════════════════════════════════════
class InformacionGeneralScreen extends StatelessWidget {
  final Map<String, dynamic> datos;
  final VoidCallback onActualizar;

  const InformacionGeneralScreen({
    super.key,
    required this.datos,
    required this.onActualizar,
  });

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre',
      'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color(0xFF6A93BE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi información',
          style: TextStyle(
            color: Color(0xFF2C3E6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF6A93BE)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditarPerfilScreen(datos: datos),
                ),
              );
              onActualizar();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _Tarjeta(
              titulo: 'Datos personales',
              child: Column(
                children: [
                  _InfoFila(
                    icono: Icons.cake_rounded,
                    etiqueta: 'Fecha de nacimiento',
                    valor: datos['fechaNacimiento'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.monitor_weight_rounded,
                    etiqueta: 'Peso',
                    valor: datos['peso'] != null
                        ? '${datos['peso']} kg'
                        : 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.height_rounded,
                    etiqueta: 'Altura',
                    valor: datos['altura'] != null
                        ? '${datos['altura']} cm'
                        : 'Sin registrar',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _Tarjeta(
              titulo: 'Historial médico',
              child: Column(
                children: [
                  _InfoFila(
                    icono: Icons.medical_services_rounded,
                    etiqueta: 'Diagnóstico principal',
                    valor: datos['diagnostico'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.history_rounded,
                    etiqueta: 'Duración',
                    valor: datos['duracion'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.warning_amber_rounded,
                    etiqueta: 'Comorbilidades',
                    valor: datos['comorbilidades'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.bloodtype_rounded,
                    etiqueta: 'Último HbA1c',
                    valor: datos['hba1c'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.healing_rounded,
                    etiqueta: 'Heridas',
                    valor: datos['heridas'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.medication_rounded,
                    etiqueta: 'Alergias',
                    valor: datos['alergias'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.smoking_rooms_rounded,
                    etiqueta: 'Tabaquismo',
                    valor: datos['tabaquismo'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.favorite_rounded,
                    etiqueta: 'Dislipidemias',
                    valor: datos['dislipidemias'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.directions_run_rounded,
                    etiqueta: 'Actividad física',
                    valor: datos['actividadFisica'] ?? 'Sin registrar',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _Tarjeta(
              titulo: 'Tratamiento de diabetes',
              child: Column(
                children: [
                  _InfoFila(
                    icono: Icons.colorize_rounded,
                    etiqueta: '¿Usa insulina?',
                    valor: datos['usaInsulina'] == true
                        ? 'Sí'
                        : datos['usaInsulina'] == false
                            ? 'No'
                            : 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.medication_liquid_rounded,
                    etiqueta: 'Tipo de tratamiento',
                    valor: datos['tipoTratamiento'] ?? 'Sin registrar',
                  ),
                  if (datos['usaInsulina'] == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFF6A93BE), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Usas insulina. Se recomienda medir tu glucosa varias veces al día.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2C3E6B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (datos['usaInsulina'] == false) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No usas insulina. Recuerda registrar tu glucosa una vez al día.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2C3E6B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            _Tarjeta(
              titulo: 'Contacto',
              child: Column(
                children: [
                  _InfoFila(
                    icono: Icons.email_outlined,
                    etiqueta: 'Correo',
                    valor: datos['correo'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.phone_android_rounded,
                    etiqueta: 'Teléfono',
                    valor: datos['telefono'] ?? 'Sin registrar',
                  ),
                  _InfoFila(
                    icono: Icons.home_rounded,
                    etiqueta: 'Dirección',
                    valor: datos['direccion'] ?? 'Sin registrar',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7D7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.contact_emergency_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'En caso de emergencia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          datos['contactoEmergenciaNombre'] ??
                              'Sin registrar',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (datos['contactoEmergenciaTel'] != null &&
                            datos['contactoEmergenciaTel'].isNotEmpty)
                          Text(
                            datos['contactoEmergenciaTel'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        const Color(0xFF6A93BE).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.privacy_tip_outlined,
                          color: Color(0xFF6A93BE),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Privacidad y consentimiento',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoFila(
                    icono: datos['consentimientoAceptado'] == true
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    etiqueta: 'Consentimiento aceptado',
                    valor: datos['consentimientoAceptado'] == true
                        ? 'Sí ✓'
                        : 'No registrado',
                  ),
                  _InfoFila(
                    icono: Icons.calendar_today_outlined,
                    etiqueta: 'Fecha de aceptación',
                    valor: datos['fechaConsentimiento'] != null
                        ? _formatearFecha(
                            (datos['fechaConsentimiento'] as Timestamp)
                                .toDate())
                        : 'No registrado',
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF6A93BE), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tus datos se usan únicamente para monitoreo clínico del pie diabético.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2C3E6B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDITAR PERFIL
// ═══════════════════════════════════════════════════════════════════════════════
class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> datos;

  const EditarPerfilScreen({super.key, required this.datos});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  bool cargando = false;
  bool? usaInsulina;
  String? tipoTratamiento;

  final List<String> opcionesTratamiento = [
    'Sin insulina',
    'Insulina',
    'Medicamento oral',
    'Insulina + medicamento oral',
    'No sabe',
  ];

  late final nombreController =
      TextEditingController(text: widget.datos['nombre'] ?? '');
  late final telefonoController =
      TextEditingController(text: widget.datos['telefono'] ?? '');
  late final direccionController =
      TextEditingController(text: widget.datos['direccion'] ?? '');
  late final fechaNacimientoController = TextEditingController(
      text: widget.datos['fechaNacimiento'] ?? '');
  late final pesoController = TextEditingController(
      text: widget.datos['peso']?.toString() ?? '');
  late final alturaController = TextEditingController(
      text: widget.datos['altura']?.toString() ?? '');
  late final contactoNombreController = TextEditingController(
      text: widget.datos['contactoEmergenciaNombre'] ?? '');
  late final contactoTelController = TextEditingController(
      text: widget.datos['contactoEmergenciaTel'] ?? '');

  @override
  void initState() {
    super.initState();
    usaInsulina = widget.datos['usaInsulina'];
    tipoTratamiento = widget.datos['tipoTratamiento'];
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    fechaNacimientoController.dispose();
    pesoController.dispose();
    alturaController.dispose();
    contactoNombreController.dispose();
    contactoTelController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (usaInsulina == null || tipoTratamiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Por favor completa la sección de tratamiento'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => cargando = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({
      'nombre': nombreController.text.trim(),
      'telefono': telefonoController.text.trim(),
      'direccion': direccionController.text.trim(),
      'fechaNacimiento': fechaNacimientoController.text.trim(),
      'peso': pesoController.text.trim(),
      'altura': alturaController.text.trim(),
      'contactoEmergenciaNombre':
          contactoNombreController.text.trim(),
      'contactoEmergenciaTel': contactoTelController.text.trim(),
      'usaInsulina': usaInsulina,
      'tipoTratamiento': tipoTratamiento,
    });

    if (mounted) Navigator.pop(context);
    setState(() => cargando = false);
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );
    if (fecha != null) {
      fechaNacimientoController.text =
          '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

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
          'Editar mi perfil',
          style: TextStyle(
            color: azul,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _seccion('Información personal', azulOscuro),
            const SizedBox(height: 12),
            _Campo(
                label: 'Nombre completo',
                icono: Icons.person_outline,
                controller: nombreController),
            const SizedBox(height: 12),
            _Campo(
                label: 'Teléfono',
                icono: Icons.phone_outlined,
                controller: telefonoController,
                teclado: TextInputType.phone),
            const SizedBox(height: 12),
            _Campo(
                label: 'Dirección',
                icono: Icons.home_outlined,
                controller: direccionController),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: seleccionarFecha,
              child: AbsorbPointer(
                child: _Campo(
                  label: 'Fecha de nacimiento',
                  icono: Icons.cake_outlined,
                  controller: fechaNacimientoController,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Campo(
                    label: 'Peso (kg)',
                    icono: Icons.monitor_weight_outlined,
                    controller: pesoController,
                    teclado: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    label: 'Altura (cm)',
                    icono: Icons.height_rounded,
                    controller: alturaController,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _seccion('Tratamiento de diabetes', azulOscuro),
            const SizedBox(height: 12),
            const Text('¿Usas insulina?',
                style: TextStyle(
                    fontSize: 14, color: Color(0xFF2C3E6B))),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sí',
                        style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: usaInsulina,
                    activeColor: azul,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) =>
                        setState(() => usaInsulina = val),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No',
                        style: TextStyle(fontSize: 14)),
                    value: false,
                    groupValue: usaInsulina,
                    activeColor: azul,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) =>
                        setState(() => usaInsulina = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoTratamiento,
              decoration: InputDecoration(
                hintText: 'Tipo de tratamiento',
                prefixIcon: const Icon(Icons.medication_outlined,
                    color: azul),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: opcionesTratamiento.map((opcion) {
                return DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion,
                      style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => tipoTratamiento = val),
            ),

            if (usaInsulina == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF6A93BE), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Usas insulina. Se recomienda medir tu glucosa varias veces al día.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2C3E6B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (usaInsulina == false) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No usas insulina. Recuerda registrar tu glucosa una vez al día.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2C3E6B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            _seccion('Contacto de emergencia', azulOscuro),
            const SizedBox(height: 12),
            _Campo(
              label: 'Nombre y parentesco (ej. María, mamá)',
              icono: Icons.contact_emergency_outlined,
              controller: contactoNombreController,
            ),
            const SizedBox(height: 12),
            _Campo(
              label: 'Teléfono de emergencia',
              icono: Icons.phone_outlined,
              controller: contactoTelController,
              teclado: TextInputType.phone,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: cargando
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(
                            color: Colors.white, fontSize: 17),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Color color) {
    return Text(
      titulo,
      style: TextStyle(
          fontWeight: FontWeight.bold, color: color, fontSize: 15),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════
class _Campo extends StatelessWidget {
  final String label;
  final IconData icono;
  final TextEditingController controller;
  final TextInputType teclado;

  const _Campo({
    required this.label,
    required this.icono,
    required this.controller,
    this.teclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icono, color: const Color(0xFF6A93BE)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Tarjeta({required this.titulo, required this.child});

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
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E6B),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _InfoFila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono,
                color: const Color(0xFF6A93BE), size: 18),
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
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}