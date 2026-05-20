import 'package:cloud_firestore/cloud_firestore.dart';

class AlertasService {
  static final _db = FirebaseFirestore.instance;

  // ─── Guardar alerta sin necesitar índice compuesto ────────────────────────
  static Future<void> _guardarAlerta({
    required String uid,
    required String tipoAlerta,
    required String mensaje,
    required String nivel,
    required String origen,
  }) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    // ✅ Buscar solo por fechaHora — sin índice compuesto
    final existente = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('alertas')
        .where('fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fechaHora', isLessThan: Timestamp.fromDate(finDia))
        .get();

    // ✅ Filtrar por tipoAlerta en memoria — no en Firestore
    final yaExiste = existente.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipoAlerta'] == tipoAlerta;
    });

    if (yaExiste) return;

    // Guardar alerta nueva
    await _db
        .collection('usuarios')
        .doc(uid)
        .collection('alertas')
        .add({
      'tipoAlerta': tipoAlerta,
      'mensaje': mensaje,
      'nivel': nivel,
      'origen': origen,
      'fechaHora': FieldValue.serverTimestamp(),
      'leida': false,
    });
  }

  // ─── Evaluar glucosa ──────────────────────────────────────────────────────
  static Future<void> evaluarGlucosa({
    required String uid,
    required double valor,
  }) async {
    if (valor < 70 || valor > 180) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'glucosa_peligro',
        mensaje: 'Glucosa fuera de rango. Se recomienda revisión del paciente.',
        nivel: 'alto',
        origen: 'glucosa',
      );
    } else if (valor > 130 && valor <= 180) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'glucosa_precaucion',
        mensaje: 'Glucosa elevada. Se recomienda continuar monitoreo.',
        nivel: 'moderado',
        origen: 'glucosa',
      );
    }
  }

  // ─── Evaluar presión arterial ─────────────────────────────────────────────
  static Future<void> evaluarPresion({
    required String uid,
    required int sistolica,
    required int diastolica,
  }) async {
    if (sistolica >= 140 || diastolica >= 90) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'presion_peligro',
        mensaje:
            'Presión arterial elevada. Se recomienda revisión del paciente.',
        nivel: 'alto',
        origen: 'presion',
      );
    } else if ((sistolica >= 130 && sistolica <= 139) ||
        (diastolica >= 80 && diastolica <= 89)) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'presion_precaucion',
        mensaje:
            'Presión arterial en rango de precaución. Se recomienda seguimiento.',
        nivel: 'moderado',
        origen: 'presion',
      );
    }
  }

  // ─── Evaluar foto semanal ─────────────────────────────────────────────────
  static Future<void> evaluarFotoSemanal({required String uid}) async {
    final hace7dias = DateTime.now().subtract(const Duration(days: 7));

    final fotos = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('fotos')
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(hace7dias))
        .get();

    if (fotos.docs.isEmpty) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'foto_faltante',
        mensaje:
            'El paciente no ha registrado fotografía del pie esta semana.',
        nivel: 'moderado',
        origen: 'foto',
      );
    }
  }

  // ─── Evaluar heridas en expediente ───────────────────────────────────────
  static Future<void> evaluarHeridas({
    required String uid,
    required String heridas,
  }) async {
    final palabrasClave = [
      'sí', 'si', 'herida', 'heridas', 'enrojecimiento',
      'inflamación', 'inflamacion', 'secreción', 'secrecion',
      'cambio de color', 'lesión', 'lesion', 'llaga'
    ];

    final heridasLower = heridas.toLowerCase();
    final tieneHerida =
        palabrasClave.any((p) => heridasLower.contains(p));

    if (tieneHerida) {
      await _guardarAlerta(
        uid: uid,
        tipoAlerta: 'herida_detectada',
        mensaje:
            'Paciente con posible lesión o cambio clínico en el pie.',
        nivel: 'alto',
        origen: 'expediente',
      );
    }
  }

  // ─── Marcar alerta como leída ─────────────────────────────────────────────
  static Future<void> marcarLeida({
    required String uid,
    required String alertaId,
  }) async {
    await _db
        .collection('usuarios')
        .doc(uid)
        .collection('alertas')
        .doc(alertaId)
        .update({'leida': true});
  }
}