import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'expedientepaciente.dart';
import 'alertas_screen.dart';
import 'chat_screen.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  String nombreDoctor = '';
  String busqueda = '';
  String filtro = 'todos';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarNombreDoctor();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarNombreDoctor() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        nombreDoctor = doc.data()?['nombre'] ?? 'Doctor';
      });
    }
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

  void mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ver pacientes por...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E6B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OpcionFiltro(
                    label: 'Todos',
                    icono: Icons.people_rounded,
                    color: const Color(0xFF6A93BE),
                    seleccionado: filtro == 'todos',
                    onTap: () {
                      setState(() => filtro = 'todos');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo estables',
                    icono: Icons.check_circle_rounded,
                    color: Colors.green,
                    seleccionado: filtro == 'estable',
                    onTap: () {
                      setState(() => filtro = 'estable');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo moderados',
                    icono: Icons.warning_rounded,
                    color: Colors.orange,
                    seleccionado: filtro == 'moderado',
                    onTap: () {
                      setState(() => filtro = 'moderado');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo alto riesgo',
                    icono: Icons.dangerous_rounded,
                    color: Colors.redAccent,
                    seleccionado: filtro == 'alto',
                    onTap: () {
                      setState(() => filtro = 'alto');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Urgentes primero',
                    icono: Icons.arrow_downward_rounded,
                    color: const Color(0xFF2C3E6B),
                    seleccionado: filtro == 'alto_estable',
                    onTap: () {
                      setState(() => filtro = 'alto_estable');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Estables primero',
                    icono: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2C3E6B),
                    seleccionado: filtro == 'estable_alto',
                    onTap: () {
                      setState(() => filtro = 'estable_alto');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> aplicarFiltro(
      List<QueryDocumentSnapshot> lista) {
    final ordenRiesgo = {'alto': 0, 'moderado': 1, 'estable': 2};

    if (filtro == 'estable' || filtro == 'moderado' || filtro == 'alto') {
      return lista.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['riesgo'] ?? 'estable') == filtro;
      }).toList();
    }

    if (filtro == 'alto_estable') {
      return List.from(lista)
        ..sort((a, b) {
          final ra = (a.data() as Map)['riesgo'] ?? 'estable';
          final rb = (b.data() as Map)['riesgo'] ?? 'estable';
          return (ordenRiesgo[ra] ?? 2).compareTo(ordenRiesgo[rb] ?? 2);
        });
    }

    if (filtro == 'estable_alto') {
      return List.from(lista)
        ..sort((a, b) {
          final ra = (a.data() as Map)['riesgo'] ?? 'estable';
          final rb = (b.data() as Map)['riesgo'] ?? 'estable';
          return (ordenRiesgo[rb] ?? 2).compareTo(ordenRiesgo[ra] ?? 2);
        });
    }

    return lista;
  }

  String _etiquetaFiltro() {
    switch (filtro) {
      case 'estable':
        return 'Solo estables';
      case 'moderado':
        return 'Solo moderados';
      case 'alto':
        return 'Solo alto riesgo';
      case 'alto_estable':
        return 'Urgentes primero';
      case 'estable_alto':
        return 'Estables primero';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: azul,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Asignar revisión',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis pacientes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: azulOscuro,
                          ),
                        ),
                        Text(
                          'Dr. $nombreDoctor',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: azulOscuro,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) =>
                            setState(() => busqueda = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => mostrarFiltros(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: filtro != 'todos'
                              ? azul
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE0E0E0)),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: filtro != 'todos'
                              ? Colors.white
                              : azul,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                if (filtro != 'todos')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => filtro = 'todos'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _etiquetaFiltro(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6A93BE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.close,
                                size: 14,
                                color: Color(0xFF6A93BE)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('tipo', isEqualTo: 'paciente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6A93BE)),
                  );
                }

                final pacientes = snapshot.data?.docs ?? [];

                final porBusqueda = pacientes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre =
                      (data['nombre'] ?? '').toLowerCase();
                  return nombre
                      .contains(busqueda.toLowerCase());
                }).toList();

                final filtrados = aplicarFiltro(porBusqueda);

                int altoRiesgo = 0;
                int moderado = 0;
                int estable = 0;
                for (var doc in porBusqueda) {
                  final data = doc.data() as Map<String, dynamic>;
                  final riesgo = data['riesgo'] ?? 'estable';
                  if (riesgo == 'alto') {
                    altoRiesgo++;
                  } else if (riesgo == 'moderado') {
                    moderado++;
                  } else {
                    estable++;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          _TarjetaResumen(
                            label: 'Alto riesgo',
                            numero: altoRiesgo,
                            color: const Color(0xFFFFEBEE),
                            borderColor: Colors.redAccent,
                            textoColor: Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          _TarjetaResumen(
                            label: 'Moderado',
                            numero: moderado,
                            color: const Color(0xFFFFF8E1),
                            borderColor: Colors.orange,
                            textoColor: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _TarjetaResumen(
                            label: 'Estable',
                            numero: estable,
                            color: const Color(0xFFE8F5E9),
                            borderColor: Colors.green,
                            textoColor: Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lista de pacientes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E6B),
                            ),
                          ),
                          Text(
                            '${filtrados.length} ${filtrados.length == 1 ? 'paciente' : 'pacientes'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6A93BE),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (filtrados.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No hay pacientes con ese filtro',
                              style:
                                  TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...filtrados.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return _TarjetaPaciente(
                            nombre: data['nombre'] ?? 'Sin nombre',
                            correo: data['correo'] ?? '',
                            riesgo: data['riesgo'] ?? 'estable',
                            uid: doc.id,
                          );
                        }),

                      const SizedBox(height: 24),

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
                                color: Colors.redAccent,
                                fontSize: 15),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// OPCIÓN FILTRO
class _OpcionFiltro extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionFiltro({
    required this.label,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              seleccionado ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                seleccionado ? color : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: seleccionado
                    ? color
                    : const Color(0xFF2C3E6B),
                fontWeight: seleccionado
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (seleccionado)
              Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// TARJETA RESUMEN
class _TarjetaResumen extends StatelessWidget {
  final String label;
  final int numero;
  final Color color;
  final Color borderColor;
  final Color textoColor;

  const _TarjetaResumen({
    required this.label,
    required this.numero,
    required this.color,
    required this.borderColor,
    required this.textoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textoColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$numero',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textoColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA PACIENTE con alertas + Chat con indicador de mensajes nuevos
class _TarjetaPaciente extends StatelessWidget {
  final String nombre;
  final String correo;
  final String riesgo;
  final String uid;

  const _TarjetaPaciente({
    required this.nombre,
    required this.correo,
    required this.riesgo,
    required this.uid,
  });

  Color get colorRiesgo {
    if (riesgo == 'alto') return Colors.redAccent;
    if (riesgo == 'moderado') return Colors.orange;
    return Colors.green;
  }

  String get etiquetaRiesgo {
    if (riesgo == 'alto') return 'CRÍTICO';
    if (riesgo == 'moderado') return 'MODERADO';
    return 'ESTABLE';
  }

  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('alertas')
          .where('leida', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final alertasNoLeidas = snapshot.data?.docs ?? [];
        final tieneAlertas = alertasNoLeidas.isNotEmpty;
        final hayAltoRiesgo = alertasNoLeidas.any((doc) =>
            (doc.data() as Map<String, dynamic>)['nivel'] ==
            'alto');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hayAltoRiesgo
                  ? Colors.redAccent.withOpacity(0.4)
                  : tieneAlertas
                      ? Colors.orange.withOpacity(0.4)
                      : const Color(0xFFE0E0E0),
              width: tieneAlertas ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF3FB),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A93BE),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2C3E6B),
                          ),
                        ),
                        Text(
                          correo,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorRiesgo.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          etiquetaRiesgo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorRiesgo,
                          ),
                        ),
                      ),
                      if (tieneAlertas) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hayAltoRiesgo
                                ? Colors.redAccent
                                    .withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: 11,
                                color: hayAltoRiesgo
                                    ? Colors.redAccent
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hayAltoRiesgo
                                    ? 'Requiere revisión'
                                    : 'Alerta activa',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: hayAltoRiesgo
                                      ? Colors.redAccent
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // ── Ver expediente ──
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpedientePacienteScreen(
                              uid: uid,
                              nombre: nombre,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                      child: const Text(
                        'Ver expediente',
                        style: TextStyle(
                            color: Color(0xFF2C3E6B),
                            fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Botón alertas o Chat con indicador ──
                  Expanded(
                    child: tieneAlertas
                        ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlertasScreen(
                                    uid: uid,
                                    nombrePaciente: nombre,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 14),
                            label: Text(
                              '${alertasNoLeidas.length} alerta${alertasNoLeidas.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hayAltoRiesgo
                                  ? Colors.redAccent
                                  : Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 10),
                            ),
                          )
                        // Botón Chat con indicador de mensajes nuevos
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(uid)
                                .collection('chatDoctor')
                                .where('enviadoPor',
                                    isEqualTo: 'paciente')
                                .where('leido',
                                    isEqualTo: false)
                                .snapshots(),
                            builder: (context, chatSnap) {
                              final noLeidos =
                                  chatSnap.data?.docs.length ?? 0;

                              return ElevatedButton(
                                onPressed: () async {
                                  final doctorUid = FirebaseAuth
                                      .instance.currentUser?.uid;
                                  String doctorNombre = 'Doctor';
                                  if (doctorUid != null) {
                                    try {
                                      final doc =
                                          await FirebaseFirestore
                                              .instance
                                              .collection('usuarios')
                                              .doc(doctorUid)
                                              .get();
                                      doctorNombre =
                                          doc.data()?['nombre'] ??
                                              'Doctor';
                                    } catch (e) {
                                      debugPrint('Error: $e');
                                    }
                                  }
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChatDoctorScreen(
                                          pacienteId: uid,
                                          nombrePaciente: nombre,
                                          miUid: doctorUid ?? '',
                                          miNombre: doctorNombre,
                                          miRol: 'doctor',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF6A93BE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.chat_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Chat',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13),
                                    ),
                                    // ✅ Punto rojo con contador
                                    if (noLeidos > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration:
                                            const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$noLeidos',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
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
}