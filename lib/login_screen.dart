
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  final String apiBaseUrl;
  final WidgetBuilder destino;

  const LoginScreen({
    super.key,
    required this.apiBaseUrl,
    required this.destino,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool ocultarPassword = true;
  bool cargando = false;

  static const Color azulOscuro = Color(0xFFD97706);
  static const Color azul = Color(0xFF64748B);
  static const Color azulClaro = Color(0xFF94A3B8);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá el email y la contraseña'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final respuesta = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/login-app'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'gmail': emailController.text.trim(),
          'contrasenia': passwordController.text,
        }),
      );

      final datos = jsonDecode(respuesta.body);

      if (!mounted) return;

      if (respuesta.statusCode == 200 && datos['exito'] == true) {

        // -------------------------------------------------
        // CONTROL OPCIONAL POR ROL:
        // Actualmente NO se restringe el acceso por rol.
        //
        // Si el profesor solicita que solamente determinados
        // usuarios puedan entrar a cocina, el control se
        // incorporaría aquí, antes de abrir la pantalla.
        //
        // Ejemplo orientativo:
        // final roles = datos['usuario']['roles'] as List;
        // final rol = roles.first.toString();
        //
        // if (rol != 'ROL_PERMITIDO') {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text('No tenés permiso para ingresar.'),
        //     ),
        //   );
        //   return;
        // }
        // -------------------------------------------------

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: widget.destino,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              datos['mensaje'] ?? 'No se pudo iniciar sesión.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo conectar con el servidor. Verificá que Laravel esté funcionando.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    final double anchoFormulario = anchoPantalla >= 700
        ? 620
        : anchoPantalla * 0.88;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: -18,
              child: circulo(57, azulOscuro),
            ),
            Positioned(
              top: 36,
              left: anchoPantalla < 500 ? 105 : 120,
              child: circulo(
                anchoPantalla < 500 ? 29 : 32,
                const Color(0xFF94A3B8),
              ),
            ),
            Positioned(
              top: 64,
              left: anchoPantalla < 500 ? 74 : 90,
              child: circulo(
                anchoPantalla < 500 ? 34 : 38,
                azul,
              ),
            ),
            Positioned(
              bottom: 65,
              right: 27,
              child: circulo(34, azul),
            ),
            Positioned(
              bottom: 12,
              right: -2,
              child: circulo(27, azulClaro),
            ),
            Positioned(
              top: 430,
              right: -13,
              child: circulo(55, azulOscuro),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: anchoFormulario,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BIENVENIDOS',
                        style: TextStyle(
                          color: const Color(0xFF1E293B),
                          fontSize: anchoPantalla < 400 ? 24 : 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(
                        height: anchoPantalla < 400 ? 32 : 38,
                      ),
                      campo(
                        controller: emailController,
                        hint: 'Email',
                        ocultar: false,
                      ),
                      const SizedBox(height: 12),
                      campo(
                        controller: passwordController,
                        hint: 'Contraseña',
                        ocultar: ocultarPassword,
                        sufijo: IconButton(
                          onPressed: () {
                            setState(() {
                              ocultarPassword = !ocultarPassword;
                            });
                          },
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: anchoPantalla < 400 ? 20 : 22,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: anchoPantalla < 400 ? 25 : 30,
                      ),
                      SizedBox(
                        height: 42,
                        width: anchoPantalla < 400 ? 135 : 150,
                        child: ElevatedButton(
                          onPressed: cargando ? null : iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8F6F0),
                            foregroundColor: const Color(0xFF1E293B),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Iniciar Sesion',
                                  style: TextStyle(
                                    fontSize:
                                        anchoPantalla < 400 ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget circulo(double tamanio, Color color) {
    return Container(
      width: tamanio,
      height: tamanio,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget campo({
    required TextEditingController controller,
    required String hint,
    required bool ocultar,
    Widget? sufijo,
  }) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: ocultar,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Colors.black,
          ),
          suffixIcon: sufijo,
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Colors.black54,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: azulOscuro,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
