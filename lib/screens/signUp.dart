// Archivo: lib/screens/sign_up_screen.dart (o la ruta donde lo tengas)
import 'package:flutter/material.dart';
import '../firebase/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // Añadido

  final AuthService _authService = AuthService(); // Instancia del servicio

  bool _phoneVerified = false;
  bool _isLoading = false;
  String? _verificationId;

  // Función para mostrar mensajes de error o éxito
  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Flujo 1: Enviar SMS
  void _sendSMS() {
    if (_phoneController.text.isEmpty) {
      _showMessage("Ingresa un número de teléfono válido (ej. +52...)");
      return;
    }

    setState(() => _isLoading = true);

    _authService.sendPhoneVerification(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId) {
        setState(() {
          _isLoading = false;
          _verificationId = verificationId;
        });
        _showOTPDialog(); // Muestra el popup para el código SMS
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showMessage(error);
      },
    );
  }

  // Flujo 2: Cuadro de diálogo para ingresar el código SMS
  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Ingresa el código SMS"),
        content: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Código de 6 dígitos"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_otpController.text.isEmpty || _verificationId == null)
                return;

              Navigator.pop(context); // Cierra el diálogo
              setState(() => _isLoading = true);

              try {
                await _authService.verifyOTP(
                  verificationId: _verificationId!,
                  smsCode: _otpController.text.trim(),
                );
                setState(() {
                  _phoneVerified = true;
                  _isLoading = false;
                });
                _showMessage("Teléfono verificado exitosamente");
              } catch (e) {
                setState(() => _isLoading = false);
                _showMessage(e.toString());
              }
            },
            child: const Text("Verificar"),
          ),
        ],
      ),
    );
  }

  // Flujo 3: Registrar Email, vincularlo y enviar verificación
  void _registerEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Completa tu correo y contraseña");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.linkEmailAndSendVerification(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _isLoading = false);
      _showMessage("¡Registro exitoso! Revisa tu bandeja de entrada.");

      // Aquí puedes redirigir al usuario a la pantalla de inicio de sesión
      // Navigator.pushNamed(context, '/login');
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add_rounded,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 48),

              if (_phoneVerified) ...[
                const Text(
                  'Configura tu correo y contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _registerEmail,
                        child: const Text('Registrarse y Verificar Email'),
                      ),
              ] else ...[
                const Text(
                  'Verifica tu número de teléfono',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número (ej. +525512345678)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _sendSMS,
                        child: const Text('Enviar SMS'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
