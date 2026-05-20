import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantallapaciente.dart';
import 'pantalladoctor.dart';
import 'consentimiento_screen.dart'; // ← agregar este import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String tipoUsuario = 'paciente';
  bool cargando = false;

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> registrarse() async {
    if (nombreController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        correoController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _mostrarMensaje('Por favor llena todos los campos');
      return;
    }

    if (passwordController.text != confirmarController.text) {
      _mostrarMensaje('Las contraseñas no coinciden');
      return;
    }

    if (passwordController.text.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => cargando = true);

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'correo': correoController.text.trim(),
        'tipo': tipoUsuario,
        'fechaRegistro': DateTime.now(),
        // ✅ Inicializar consentimiento como false hasta que lo acepte
        'consentimientoAceptado': false,
        'fechaConsentimiento': null,
      });

      if (mounted) {
        if (tipoUsuario == 'doctor') {
          // ✅ Doctores van directo sin consentimiento
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DoctorScreen()),
            (route) => false,
          );
        } else {
          // ✅ Pacientes pasan por consentimiento antes de entrar
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ConsentimientoScreen(
                nextScreen: const PatientProfileScreen(),
              ),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error, intenta de nuevo';
      if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya tiene una cuenta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no tiene un formato válido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      }
      if (mounted) _mostrarMensaje(mensaje);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: azul),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [

            const SizedBox(height: 10),

            const Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: azul,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '¿Eres paciente o doctor?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Selector de tipo
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => tipoUsuario = 'paciente'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: tipoUsuario == 'paciente' ? azul : Colors.white,
                        border: Border.all(color: azul),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            color: tipoUsuario == 'paciente'
                                ? Colors.white
                                : azul,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Paciente',
                            style: TextStyle(
                              color: tipoUsuario == 'paciente'
                                  ? Colors.white
                                  : azul,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => tipoUsuario = 'doctor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: tipoUsuario == 'doctor' ? azul : Colors.white,
                        border: Border.all(color: azul),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: tipoUsuario == 'doctor'
                                ? Colors.white
                                : azul,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Doctor',
                            style: TextStyle(
                              color: tipoUsuario == 'doctor'
                                  ? Colors.white
                                  : azul,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _campo(
              controller: nombreController,
              hint: 'Nombre completo',
              icono: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: telefonoController,
              hint: 'Teléfono',
              icono: Icons.phone,
              teclado: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: correoController,
              hint: 'Correo electrónico',
              icono: Icons.email_outlined,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: passwordController,
              hint: 'Contraseña',
              icono: Icons.lock_outline,
              oculto: true,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: confirmarController,
              hint: 'Confirmar contraseña',
              icono: Icons.lock_outline,
              oculto: true,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : registrarse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Registrarme',
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

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    bool oculto = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icono, color: const Color(0xFF6A93BE)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}