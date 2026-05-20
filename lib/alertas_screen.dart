import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alertas_service.dart';

class AlertasScreen extends StatelessWidget {
  final String uid;
  final String nombrePaciente;

  const AlertasScreen({
    super.key,
    required this.uid,
    required this.nombrePaciente,
  });

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas clínicas',
              style: TextStyle(
                color: azulOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              nombrePaciente,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('alertas')
            .orderBy('fechaHora', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: azul));
          }

          final alertas = snapshot.data?.docs ?? [];

          if (alertas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin alertas activas',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Este paciente no tiene alertas recientes',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alertas.length,
            itemBuilder: (context, i) {
              final data = alertas[i].data() as Map<String, dynamic>;
              final alertaId = alertas[i].id;
              final nivel = data['nivel'] ?? 'moderado';
              final leida = data['leida'] ?? false;
              final fecha = data['fechaHora'] != null
                  ? (data['fechaHora'] as Timestamp).toDate()
                  : DateTime.now();

              final color = nivel == 'alto'
                  ? Colors.redAccent
                  : nivel == 'moderado'
                      ? Colors.orange
                      : Colors.green;

              final colorFondo = nivel == 'alto'
                  ? const Color(0xFFFFEBEE)
                  : nivel == 'moderado'
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFE8F5E9);

              final icono = _iconoPorOrigen(data['origen'] ?? '');

              return GestureDetector(
                onTap: () async {
                  if (!leida) {
                    await AlertasService.marcarLeida(
                        uid: uid, alertaId: alertaId);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: leida ? Colors.white : colorFondo,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: leida
                          ? const Color(0xFFE0E0E0)
                          : color.withOpacity(0.4),
                      width: leida ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícono de origen
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icono, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nivel + no leída
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    nivel == 'alto'
                                        ? 'Alto riesgo'
                                        : nivel == 'moderado'
                                            ? 'Moderado'
                                            : 'Estable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                if (!leida) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Mensaje
                            Text(
                              data['mensaje'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C3E6B),
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Fecha
                            Text(
                              _fechaLegible(fecha),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconoPorOrigen(String origen) {
    switch (origen) {
      case 'glucosa':
        return Icons.bloodtype_outlined;
      case 'presion':
        return Icons.favorite_outline;
      case 'foto':
        return Icons.photo_camera_outlined;
      case 'expediente':
        return Icons.healing_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  String _fechaLegible(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year} — $hora:$min';
  }
}