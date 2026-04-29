import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantallapaciente.dart';
import 'pantalladoctor.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String tipoUsuario = 'paciente';
  bool cargando = false;

  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
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

  Future<void> iniciarSesion() async {
    if (correoController.text.isEmpty || passwordController.text.isEmpty) {
      _mostrarMensaje('Llena tu correo y contraseña');
      return;
    }

    setState(() => cargando = true);

    try {
      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get();

      if (doc.exists) {
        final tipoGuardado = doc.data()?['tipo'];

        if (tipoGuardado != tipoUsuario) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _mostrarMensaje(
              'Esta cuenta es de $tipoGuardado, selecciona la opción correcta',
            );
          }
          return;
        }

        if (mounted) {
          if (tipoGuardado == 'doctor') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DoctorScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Algo salió mal, intenta de nuevo';
      if (e.code == 'user-not-found') {
        mensaje = 'No encontramos una cuenta con ese correo';
      } else if (e.code == 'wrong-password') {
        mensaje = 'La contraseña no es correcta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no tiene un formato válido';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos';
      }
      if (mounted) _mostrarMensaje(mensaje);
    } finally {
      if (mounted) setState(() => cargando = false);
    }
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: azul,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '¿Entras como paciente o doctor?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Selector paciente / doctor
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

            TextField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email_outlined, color: azul),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline, color: azul),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Entrar',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}