import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'galeriadefotos.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarPerfilScreen(datos: datos!),
                ),
              );
              cargarDatos();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A93BE), Color(0xFF2C3E6B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
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
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _Tarjeta(
                    titulo: 'Datos personales',
                    child: Column(
                      children: [
                        _InfoFila(
                          icono: Icons.cake_rounded,
                          etiqueta: 'Fecha de nacimiento',
                          valor: datos?['fechaNacimiento'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.monitor_weight_rounded,
                          etiqueta: 'Peso',
                          valor: datos?['peso'] != null
                              ? '${datos!['peso']} kg'
                              : 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.height_rounded,
                          etiqueta: 'Altura',
                          valor: datos?['altura'] != null
                              ? '${datos!['altura']} cm'
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
                          valor: datos?['diagnostico'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.history_rounded,
                          etiqueta: 'Duración',
                          valor: datos?['duracion'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.warning_amber_rounded,
                          etiqueta: 'Comorbilidades',
                          valor: datos?['comorbilidades'] ?? 'Sin registrar',
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
                          etiqueta: 'Alergias',
                          valor: datos?['alergias'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.smoking_rooms_rounded,
                          etiqueta: 'Tabaquismo',
                          valor: datos?['tabaquismo'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.favorite_rounded,
                          etiqueta: 'Dislipidemias',
                          valor: datos?['dislipidemias'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.directions_run_rounded,
                          etiqueta: 'Actividad física',
                          valor: datos?['actividadFisica'] ?? 'Sin registrar',
                        ),
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
                          valor: datos?['correo'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.phone_android_rounded,
                          etiqueta: 'Teléfono',
                          valor: datos?['telefono'] ?? 'Sin registrar',
                        ),
                        _InfoFila(
                          icono: Icons.home_rounded,
                          etiqueta: 'Dirección',
                          valor: datos?['direccion'] ?? 'Sin registrar',
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
                                datos?['contactoEmergenciaNombre'] ?? 'Sin registrar',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (datos?['contactoEmergenciaTel'] != null &&
                                  datos!['contactoEmergenciaTel'].isNotEmpty)
                                Text(
                                  datos!['contactoEmergenciaTel'],
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

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: cerrarSesion,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.redAccent, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
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

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> datos;

  const EditarPerfilScreen({super.key, required this.datos});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  bool cargando = false;

  late final nombreController = TextEditingController(text: widget.datos['nombre'] ?? '');
  late final telefonoController = TextEditingController(text: widget.datos['telefono'] ?? '');
  late final direccionController = TextEditingController(text: widget.datos['direccion'] ?? '');
  late final fechaNacimientoController = TextEditingController(text: widget.datos['fechaNacimiento'] ?? '');
  late final pesoController = TextEditingController(text: widget.datos['peso']?.toString() ?? '');
  late final alturaController = TextEditingController(text: widget.datos['altura']?.toString() ?? '');
  late final contactoNombreController = TextEditingController(text: widget.datos['contactoEmergenciaNombre'] ?? '');
  late final contactoTelController = TextEditingController(text: widget.datos['contactoEmergenciaTel'] ?? '');

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
      'contactoEmergenciaNombre': contactoNombreController.text.trim(),
      'contactoEmergenciaTel': contactoTelController.text.trim(),
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
      fechaNacimientoController.text = '${fecha.day}/${fecha.month}/${fecha.year}';
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _seccion('Información personal', azulOscuro),
            const SizedBox(height: 12),

            _Campo(label: 'Nombre completo', icono: Icons.person_outline, controller: nombreController),
            const SizedBox(height: 12),
            _Campo(label: 'Teléfono', icono: Icons.phone_outlined, controller: telefonoController, teclado: TextInputType.phone),
            const SizedBox(height: 12),
            _Campo(label: 'Dirección', icono: Icons.home_outlined, controller: direccionController),
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(color: Colors.white, fontSize: 17),
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
        fontWeight: FontWeight.bold,
        color: color,
        fontSize: 15,
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(12),
        ),
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
            child: Icon(icono, color: const Color(0xFF6A93BE), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
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