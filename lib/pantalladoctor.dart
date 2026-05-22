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

    if (doc.exists && mounted) {
      setState(() {
        nombreDoctor = doc.data()?['nombre'] ?? 'Médico';
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
                    label: 'Solo bajo riesgo',
                    icono: Icons.check_circle_rounded,
                    color: Colors.green,
                    seleccionado: filtro == 'bajo',
                    onTap: () {
                      setState(() => filtro = 'bajo');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo moderados',
                    icono: Icons.warning_rounded,
                    color: Colors.amber,
                    seleccionado: filtro == 'moderado',
                    onTap: () {
                      setState(() => filtro = 'moderado');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo alto riesgo',
                    icono: Icons.dangerous_rounded,
                    color: Colors.orange,
                    seleccionado: filtro == 'alto',
                    onTap: () {
                      setState(() => filtro = 'alto');
                      Navigator.pop(context);
                    },
                  ),
                  _OpcionFiltro(
                    label: 'Solo riesgo máximo',
                    icono: Icons.emergency_rounded,
                    color: Colors.redAccent,
                    seleccionado: filtro == 'maximo',
                    onTap: () {
                      setState(() => filtro = 'maximo');
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

  int _ordenRiesgo(String r) {
    if (r == 'maximo') return 0;
    if (r == 'alto') return 1;
    if (r == 'moderado') return 2;
    return 3;
  }

  List<QueryDocumentSnapshot> aplicarFiltro(List<QueryDocumentSnapshot> lista) {
    if (['bajo', 'moderado', 'alto', 'maximo'].contains(filtro)) {
      return lista.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['riesgoTabla'] ?? 'bajo') == filtro;
      }).toList();
    }

    if (filtro == 'alto_estable') {
      return List.from(lista)
        ..sort((a, b) {
          final ra = (a.data() as Map)['riesgoTabla'] ?? 'bajo';
          final rb = (b.data() as Map)['riesgoTabla'] ?? 'bajo';
          return _ordenRiesgo(ra).compareTo(_ordenRiesgo(rb));
        });
    }

    if (filtro == 'estable_alto') {
      return List.from(lista)
        ..sort((a, b) {
          final ra = (a.data() as Map)['riesgoTabla'] ?? 'bajo';
          final rb = (b.data() as Map)['riesgoTabla'] ?? 'bajo';
          return _ordenRiesgo(rb).compareTo(_ordenRiesgo(ra));
        });
    }

    return lista;
  }

  String _etiquetaFiltro() {
    switch (filtro) {
      case 'bajo':
        return 'Solo bajo riesgo';
      case 'moderado':
        return 'Solo moderados';
      case 'alto':
        return 'Solo alto riesgo';
      case 'maximo':
        return 'Solo riesgo máximo';
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
                          'Médico $nombreDoctor',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const _BotonNotificacionesDoctor(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) => setState(() => busqueda = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => mostrarFiltros(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: filtro != 'todos' ? azul : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: filtro != 'todos' ? Colors.white : azul,
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
                      onTap: () => setState(() => filtro = 'todos'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                            const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF6A93BE),
                            ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A93BE),
                    ),
                  );
                }

                final pacientes = snapshot.data?.docs ?? [];
                final doctorUidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

                final pacientesAsignados = pacientes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final medicoAsignado = (data['medicoId'] ??
                          data['medicoID'] ??
                          data['medicoid'] ??
                          '')
                      .toString()
                      .trim();

                  return medicoAsignado == doctorUidActual;
                }).toList();

                final porBusqueda = pacientesAsignados.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                  return nombre.contains(busqueda.toLowerCase());
                }).toList();

                final filtrados = aplicarFiltro(porBusqueda);

                int maximo = 0;
                int alto = 0;
                int moderado = 0;
                int bajo = 0;

                for (var doc in porBusqueda) {
                  final data = doc.data() as Map<String, dynamic>;
                  final riesgo = data['riesgoTabla'] ?? 'bajo';
                  if (riesgo == 'maximo') {
                    maximo++;
                  } else if (riesgo == 'alto') {
                    alto++;
                  } else if (riesgo == 'moderado') {
                    moderado++;
                  } else {
                    bajo++;
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
                            label: 'Máximo',
                            numero: maximo,
                            color: const Color(0xFFFFEBEE),
                            borderColor: Colors.redAccent,
                            textoColor: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          _TarjetaResumen(
                            label: 'Alto',
                            numero: alto,
                            color: const Color(0xFFFFF3E0),
                            borderColor: Colors.orange,
                            textoColor: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _TarjetaResumen(
                            label: 'Moderado',
                            numero: moderado,
                            color: const Color(0xFFFFFDE7),
                            borderColor: Colors.amber,
                            textoColor: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          _TarjetaResumen(
                            label: 'Bajo',
                            numero: bajo,
                            color: const Color(0xFFE8F5E9),
                            borderColor: Colors.green,
                            textoColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'No hay pacientes asignados o con ese filtro',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...filtrados.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _TarjetaPaciente(
                            nombre: data['nombre'] ?? 'Sin nombre',
                            correo: data['correo'] ?? '',
                            riesgo: data['riesgoTabla'] ?? 'bajo',
                            uid: doc.id,
                          );
                        }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: cerrarSesion,
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

class _BotonNotificacionesDoctor extends StatefulWidget {
  const _BotonNotificacionesDoctor();

  @override
  State<_BotonNotificacionesDoctor> createState() =>
      _BotonNotificacionesDoctorState();
}

class _BotonNotificacionesDoctorState
    extends State<_BotonNotificacionesDoctor> {
  Future<int> _contarAlertasNoLeidas() async {
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;
    if (doctorUid == null) return 0;

    final pacientesSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('tipo', isEqualTo: 'paciente')
        .get();

    int total = 0;

    for (final pacienteDoc in pacientesSnap.docs) {
      final pacienteData = pacienteDoc.data();
      final medicoAsignado = (pacienteData['medicoId'] ??
              pacienteData['medicoID'] ??
              pacienteData['medicoid'] ??
              '')
          .toString()
          .trim();

      if (medicoAsignado != doctorUid) continue;

      final alertasSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(pacienteDoc.id)
          .collection('alertas')
          .where('leida', isEqualTo: false)
          .get();

      total += alertasSnap.docs.length;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    const azulOscuro = Color(0xFF2C3E6B);

    return FutureBuilder<int>(
      future: _contarAlertasNoLeidas(),
      builder: (context, snapshot) {
        final totalAlertas = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificacionesDoctorScreen(),
              ),
            );

            if (mounted) {
              setState(() {});
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
              if (totalAlertas > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      totalAlertas > 99 ? '99+' : '$totalAlertas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class NotificacionesDoctorScreen extends StatefulWidget {
  const NotificacionesDoctorScreen({super.key});

  @override
  State<NotificacionesDoctorScreen> createState() =>
      _NotificacionesDoctorScreenState();
}

class _NotificacionesDoctorScreenState
    extends State<NotificacionesDoctorScreen> {
  Future<List<_ResumenAlertasPaciente>> _cargarAlertas() async {
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;
    if (doctorUid == null) return [];

    final pacientesSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('tipo', isEqualTo: 'paciente')
        .get();

    final List<_ResumenAlertasPaciente> resumenes = [];

    for (final pacienteDoc in pacientesSnap.docs) {
      final pacienteData = pacienteDoc.data();
      final medicoAsignado = (pacienteData['medicoId'] ??
              pacienteData['medicoID'] ??
              pacienteData['medicoid'] ??
              '')
          .toString()
          .trim();

      if (medicoAsignado != doctorUid) continue;

      final uidPaciente = pacienteDoc.id;

      final alertasSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uidPaciente)
          .collection('alertas')
          .where('leida', isEqualTo: false)
          .get();

      if (alertasSnap.docs.isEmpty) continue;

      bool tieneAltoRiesgo = false;
      String ultimoMensaje = '';

      for (final alertaDoc in alertasSnap.docs) {
        final alertaData = alertaDoc.data();

        final nivel = alertaData['nivel'] ?? '';
        final mensaje =
            alertaData['mensaje'] ?? alertaData['tipo'] ?? 'Alerta pendiente';

        if (nivel == 'alto') {
          tieneAltoRiesgo = true;
        }

        if (ultimoMensaje.isEmpty) {
          ultimoMensaje = mensaje.toString();
        }
      }

      resumenes.add(
        _ResumenAlertasPaciente(
          uid: uidPaciente,
          nombre: pacienteData['nombre'] ?? 'Paciente',
          correo: pacienteData['correo'] ?? '',
          cantidad: alertasSnap.docs.length,
          tieneAltoRiesgo: tieneAltoRiesgo,
          ultimoMensaje: ultimoMensaje,
        ),
      );
    }

    resumenes.sort((a, b) {
      if (a.tieneAltoRiesgo && !b.tieneAltoRiesgo) return -1;
      if (!a.tieneAltoRiesgo && b.tieneAltoRiesgo) return 1;
      return b.cantidad.compareTo(a.cantidad);
    });

    return resumenes;
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
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<_ResumenAlertasPaciente>>(
        future: _cargarAlertas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: azul),
            );
          }

          final resumenes = snapshot.data ?? [];

          final totalAlertas = resumenes.fold<int>(
            0,
            (total, item) => total + item.cantidad,
          );

          if (resumenes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay alertas pendientes',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: azul,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$totalAlertas alerta${totalAlertas == 1 ? '' : 's'} pendiente${totalAlertas == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: azul,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...resumenes.map((resumen) {
                return _TarjetaNotificacionPaciente(resumen: resumen);
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ResumenAlertasPaciente {
  final String uid;
  final String nombre;
  final String correo;
  int cantidad;
  bool tieneAltoRiesgo;
  String ultimoMensaje;

  _ResumenAlertasPaciente({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.cantidad,
    required this.tieneAltoRiesgo,
    required this.ultimoMensaje,
  });
}

class _TarjetaNotificacionPaciente extends StatelessWidget {
  final _ResumenAlertasPaciente resumen;

  const _TarjetaNotificacionPaciente({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final color = resumen.tieneAltoRiesgo ? Colors.redAccent : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.3,
        ),
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
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  resumen.tieneAltoRiesgo
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resumen.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E6B),
                      ),
                    ),
                    if (resumen.correo.toString().isNotEmpty)
                      Text(
                        resumen.correo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${resumen.cantidad} alerta${resumen.cantidad == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (resumen.ultimoMensaje.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              resumen.ultimoMensaje,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () async {
                final alertasSnap = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(resumen.uid)
                    .collection('alertas')
                    .where('leida', isEqualTo: false)
                    .get();

                if (alertasSnap.docs.isNotEmpty) {
                  final batch = FirebaseFirestore.instance.batch();

                  for (final alerta in alertasSnap.docs) {
                    batch.update(alerta.reference, {
                      'leida': true,
                      'fechaLectura': FieldValue.serverTimestamp(),
                    });
                  }

                  await batch.commit();
                }

                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlertasScreen(
                        uid: resumen.uid,
                        nombrePaciente: resumen.nombre,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.open_in_new_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Ver alertas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : const Color(0xFFE0E0E0),
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
                color: seleccionado ? color : const Color(0xFF2C3E6B),
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (seleccionado) Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(10),
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textoColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$numero',
              style: TextStyle(
                fontSize: 24,
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
    if (riesgo == 'maximo') return Colors.redAccent;
    if (riesgo == 'alto') return Colors.orange;
    if (riesgo == 'moderado') return Colors.amber.shade700;
    return Colors.green;
  }

  String get etiquetaRiesgo {
    if (riesgo == 'maximo') return 'MÁXIMO';
    if (riesgo == 'alto') return 'ALTO';
    if (riesgo == 'moderado') return 'MODERADO';
    return 'BAJO';
  }

  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2 && partes[0].isNotEmpty && partes[1].isNotEmpty) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  Future<void> _abrirChat(BuildContext context) async {
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;
    String doctorNombre = 'Médico';

    if (doctorUid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(doctorUid)
            .get();
        doctorNombre = doc.data()?['nombre'] ?? 'Médico';
      } catch (e) {
        debugPrint('Error al obtener médico: $e');
      }
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDoctorScreen(
            pacienteId: uid,
            nombrePaciente: nombre,
            miUid: doctorUid ?? '',
            miNombre: doctorNombre,
            miRol: 'doctor',
          ),
        ),
      );
    }
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
        final hayAltoRiesgo = alertasNoLeidas.any(
          (doc) => (doc.data() as Map<String, dynamic>)['nivel'] == 'alto',
        );

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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorRiesgo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: hayAltoRiesgo
                                ? Colors.redAccent.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
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
                                '${alertasNoLeidas.length} alerta${alertasNoLeidas.length == 1 ? '' : 's'}',
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpedientePacienteScreen(
                              uid: uid,
                              nombre: nombre,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Ver expediente',
                        style: TextStyle(
                          color: Color(0xFF2C3E6B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .collection('chatDoctor')
                          .where('enviadoPor', isEqualTo: 'paciente')
                          .where('leido', isEqualTo: false)
                          .snapshots(),
                      builder: (context, chatSnap) {
                        final noLeidos = chatSnap.data?.docs.length ?? 0;

                        return ElevatedButton(
                          onPressed: () => _abrirChat(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A93BE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontSize: 13,
                                ),
                              ),
                              if (noLeidos > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$noLeidos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
