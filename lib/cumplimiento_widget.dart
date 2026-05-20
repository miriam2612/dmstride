import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Widget reutilizable — funciona tanto en vista paciente como en vista doctor
// ═══════════════════════════════════════════════════════════════════════════════
class EstadoCumplimientoCard extends StatefulWidget {
  final String uid;

  const EstadoCumplimientoCard({super.key, required this.uid});

  @override
  State<EstadoCumplimientoCard> createState() =>
      _EstadoCumplimientoCardState();
}

class _EstadoCumplimientoCardState extends State<EstadoCumplimientoCard> {
  bool cargando = true;
  bool fotoSemana = false;
  bool glucosaHoy = false;
  bool presionHoy = false;

  @override
  void initState() {
    super.initState();
    _verificarCumplimiento();
  }

  Future<void> _verificarCumplimiento() async {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    final hace7dias = ahora.subtract(const Duration(days: 7));

    final db = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid);

    // ── Verificar foto semanal ──
    final fotos = await db
        .collection('fotos')
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(hace7dias))
        .limit(1)
        .get();

    // ── Verificar glucosa de hoy ──
    final glucosa = await db
        .collection('glucosaRegistros')
        .where('fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fechaHora', isLessThan: Timestamp.fromDate(finDia))
        .limit(1)
        .get();

    // ── Verificar presión de hoy ──
    final presion = await db
        .collection('presionRegistros')
        .where('fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fechaHora', isLessThan: Timestamp.fromDate(finDia))
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        fotoSemana = fotos.docs.isNotEmpty;
        glucosaHoy = glucosa.docs.isNotEmpty;
        presionHoy = presion.docs.isNotEmpty;
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulOscuro = Color(0xFF2C3E6B);

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
          // ── Título ──
          Row(
            children: [
              const Icon(Icons.task_alt_rounded,
                  color: Color(0xFF6A93BE), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estado de cumplimiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: azulOscuro,
                ),
              ),
              const Spacer(),
              // ── Botón refrescar ──
              GestureDetector(
                onTap: () {
                  setState(() => cargando = true);
                  _verificarCumplimiento();
                },
                child: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF6A93BE), size: 18),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Color(0xFF6A93BE), strokeWidth: 2),
              ),
            )
          else ...[
            _ItemCumplimiento(
              icono: Icons.photo_camera_outlined,
              titulo: 'Foto semanal del pie',
              subtitulo: fotoSemana
                  ? 'Subida esta semana'
                  : 'No hay foto en los últimos 7 días',
              completo: fotoSemana,
            ),
            const SizedBox(height: 10),
            _ItemCumplimiento(
              icono: Icons.bloodtype_outlined,
              titulo: 'Glucosa de hoy',
              subtitulo: glucosaHoy
                  ? 'Registrada hoy'
                  : 'Sin registro de glucosa hoy',
              completo: glucosaHoy,
            ),
            const SizedBox(height: 10),
            _ItemCumplimiento(
              icono: Icons.favorite_outline,
              titulo: 'Presión arterial de hoy',
              subtitulo: presionHoy
                  ? 'Registrada hoy'
                  : 'Sin registro de presión hoy',
              completo: presionHoy,
            ),

            // ── Resumen general ──
            const SizedBox(height: 14),
            _resumenGeneral(),
          ],
        ],
      ),
    );
  }

  Widget _resumenGeneral() {
    final total = [fotoSemana, glucosaHoy, presionHoy].where((e) => e).length;

    Color color;
    String mensaje;
    IconData icono;

    if (total == 3) {
      color = Colors.green;
      mensaje = '¡Todo al día! Excelente seguimiento.';
      icono = Icons.check_circle_rounded;
    } else if (total == 2) {
      color = Colors.orange;
      mensaje = 'Casi completo. Falta 1 registro.';
      icono = Icons.warning_amber_rounded;
    } else if (total == 1) {
      color = Colors.orange;
      mensaje = 'Seguimiento incompleto. Faltan ${ 3 - total} registros.';
      icono = Icons.warning_amber_rounded;
    } else {
      color = Colors.redAccent;
      mensaje = 'Sin registros de hoy. Se requiere atención.';
      icono = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$total/3',
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

// ─── Widget auxiliar para cada ítem ──────────────────────────────────────────
class _ItemCumplimiento extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool completo;

  const _ItemCumplimiento({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.completo,
  });

  @override
  Widget build(BuildContext context) {
    final color = completo ? Colors.green : Colors.orange;
    final colorFondo =
        completo ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Ícono del tipo de registro
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: const Color(0xFF6A93BE), size: 18),
          ),
          const SizedBox(width: 12),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E6B),
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Etiqueta de estado
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  completo ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  completo ? 'Completo' : 'Pendiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
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