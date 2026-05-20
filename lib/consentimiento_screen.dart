import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsentimientoScreen extends StatefulWidget {
  // nextScreen es la pantalla a la que va después de aceptar
  final Widget nextScreen;

  const ConsentimientoScreen({super.key, required this.nextScreen});

  @override
  State<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends State<ConsentimientoScreen> {
  bool aceptado = false;
  bool guardando = false;

  Future<void> continuar() async {
    if (!aceptado) return;

    setState(() => guardando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Guardar consentimiento en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({
        'consentimientoAceptado': true,
        'fechaConsentimiento': Timestamp.now(),
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    }
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Consentimiento y privacidad',
          style: TextStyle(
            color: azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Ícono de privacidad ──
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  color: azul,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: const Text(
                'Aviso de privacidad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: azulOscuro,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: const Text(
                'Lee con atención antes de continuar',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // ── Card: Qué datos recopilamos ──
            _CardSeccion(
              icono: Icons.folder_open_outlined,
              titulo: 'Datos que recopilamos',
              contenido:
                  'DMstride recopila información de salud como:\n\n'
                  '• Fotografías del pie\n'
                  '• Niveles de glucosa\n'
                  '• Presión arterial\n'
                  '• Historial médico\n'
                  '• Información personal del paciente',
            ),

            const SizedBox(height: 14),

            // ── Card: Cómo usamos los datos ──
            _CardSeccion(
              icono: Icons.local_hospital_outlined,
              titulo: 'Cómo usamos tus datos',
              contenido:
                  'La información recopilada será utilizada únicamente para:\n\n'
                  '• Seguimiento clínico remoto del pie diabético\n'
                  '• Revisión por el médico asignado dentro de la app\n'
                  '• Generación de historial médico personal\n\n'
                  'Tus datos NO serán compartidos con terceros '
                  'ni utilizados con fines comerciales.',
            ),

            const SizedBox(height: 14),

            // ── Card: Consentimiento ──
            _CardSeccion(
              icono: Icons.verified_user_outlined,
              titulo: 'Consentimiento informado',
              contenido:
                  'Al aceptar, confirmas que:\n\n'
                  '• Has leído y comprendido este aviso de privacidad\n'
                  '• Autorizas el uso de tus datos e imágenes para '
                  'fines de monitoreo y seguimiento del pie diabético\n'
                  '• Entiendes que puedes solicitar la eliminación '
                  'de tus datos en cualquier momento contactando '
                  'al administrador de la app',
            ),

            const SizedBox(height: 24),

            // ── Checkbox de aceptación ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: aceptado ? azul : const Color(0xFFE0E0E0),
                  width: aceptado ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: aceptado,
                    activeColor: azul,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) => setState(() => aceptado = val ?? false),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Acepto el consentimiento informado y el uso de mis datos de salud para monitoreo del pie diabético.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E6B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón Continuar ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: aceptado && !guardando ? continuar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Nota al pie
            const Center(
              child: Text(
                'Si no aceptas no podrás continuar usando la app.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar para cada sección ──
class _CardSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String contenido;

  const _CardSeccion({
    required this.icono,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: const Color(0xFF6A93BE), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contenido,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}