import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'galeriadefotos.dart';
import 'niveles_screen.dart';

class ExpedientePacienteScreen extends StatefulWidget {
  final String uid;
  final String nombre;

  const ExpedientePacienteScreen({
    super.key,
    required this.uid,
    required this.nombre,
  });

  @override
  State<ExpedientePacienteScreen> createState() => _ExpedientePacienteScreenState();
}

class _ExpedientePacienteScreenState extends State<ExpedientePacienteScreen> {
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

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
                    icono: Icons.edit_outlined,
                    titulo: 'Editar expediente',
                    subtitulo: 'Historial médico y nivel de riesgo',
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

                  // Resumen rápido del paciente
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
                          valor: _etiquetaRiesgo(datos?['riesgo'] ?? 'estable'),
                          colorValor: _colorRiesgo(datos?['riesgo'] ?? 'estable'),
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
                      ],
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

  String _etiquetaRiesgo(String riesgo) {
    if (riesgo == 'alto') return 'Alto';
    if (riesgo == 'moderado') return 'Moderado';
    return 'Estable';
  }

  Color _colorRiesgo(String riesgo) {
    if (riesgo == 'alto') return Colors.redAccent;
    if (riesgo == 'moderado') return Colors.orange;
    return Colors.green;
  }
}

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
              child: Icon(icono, color: const Color(0xFF6A93BE), size: 22),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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

class EditarExpedienteScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> datos;

  const EditarExpedienteScreen({
    super.key,
    required this.uid,
    required this.datos,
  });

  @override
  State<EditarExpedienteScreen> createState() => _EditarExpedienteScreenState();
}

class _EditarExpedienteScreenState extends State<EditarExpedienteScreen> {
  bool cargando = false;
  String riesgo = 'estable';

  late final diagnosticoController = TextEditingController(text: widget.datos['diagnostico'] ?? '');
  late final duracionController = TextEditingController(text: widget.datos['duracion'] ?? '');
  late final comorbilController = TextEditingController(text: widget.datos['comorbilidades'] ?? '');
  late final hba1cController = TextEditingController(text: widget.datos['hba1c'] ?? '');
  late final heridasController = TextEditingController(text: widget.datos['heridas'] ?? '');
  late final alergiasController = TextEditingController(text: widget.datos['alergias'] ?? '');
  late final tabaquismoController = TextEditingController(text: widget.datos['tabaquismo'] ?? '');
  late final dislipidemiasController = TextEditingController(text: widget.datos['dislipidemias'] ?? '');
  late final actividadController = TextEditingController(text: widget.datos['actividadFisica'] ?? '');

  @override
  void initState() {
    super.initState();
    riesgo = widget.datos['riesgo'] ?? 'estable';
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
    super.dispose();
  }

  Future<void> guardar() async {
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
      'riesgo': riesgo,
    });
    if (mounted) Navigator.pop(context);
    setState(() => cargando = false);
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
          'Editar expediente',
          style: TextStyle(color: azul, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _seccion('Diagnóstico y evolución', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Diagnóstico principal', icono: Icons.medical_services_outlined, controller: diagnosticoController),
            const SizedBox(height: 12),
            _Campo(label: 'Tiempo desde el diagnóstico (ej. 5 años)', icono: Icons.history_rounded, controller: duracionController),
            const SizedBox(height: 12),
            _Campo(label: 'Último HbA1c (ej. 7.4%)', icono: Icons.bloodtype_outlined, controller: hba1cController),
            const SizedBox(height: 24),
            _seccion('Condiciones asociadas', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Comorbilidades', icono: Icons.warning_amber_outlined, controller: comorbilController),
            const SizedBox(height: 12),
            _Campo(label: 'Heridas actuales o pasadas', icono: Icons.healing_outlined, controller: heridasController),
            const SizedBox(height: 12),
            _Campo(label: 'Alergias', icono: Icons.medication_outlined, controller: alergiasController),
            const SizedBox(height: 12),
            _Campo(label: 'Dislipidemias (colesterol, triglicéridos)', icono: Icons.favorite_outline, controller: dislipidemiasController),
            const SizedBox(height: 24),
            _seccion('Estilo de vida', azulOscuro),
            const SizedBox(height: 12),
            _Campo(label: 'Tabaquismo', icono: Icons.smoking_rooms_rounded, controller: tabaquismoController),
            const SizedBox(height: 12),
            _Campo(label: 'Actividad física', icono: Icons.directions_run_rounded, controller: actividadController),
            const SizedBox(height: 24),
            _seccion('Nivel de riesgo', azulOscuro),
            const SizedBox(height: 12),
            Row(
              children: [
                _BotonRiesgo(
                  label: 'Estable',
                  color: Colors.green,
                  seleccionado: riesgo == 'estable',
                  onTap: () => setState(() => riesgo = 'estable'),
                ),
                const SizedBox(width: 10),
                _BotonRiesgo(
                  label: 'Moderado',
                  color: Colors.orange,
                  seleccionado: riesgo == 'moderado',
                  onTap: () => setState(() => riesgo = 'moderado'),
                ),
                const SizedBox(width: 10),
                _BotonRiesgo(
                  label: 'Alto',
                  color: Colors.redAccent,
                  seleccionado: riesgo == 'alto',
                  onTap: () => setState(() => riesgo = 'alto'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar cambios', style: TextStyle(color: Colors.white, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Color color) {
    return Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15));
  }
}

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
          child: Text(
            label,
            style: TextStyle(
              color: seleccionado ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icono, color: const Color(0xFF6A93BE)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

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
                Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorValor ?? const Color(0xFF2C3E6B),
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