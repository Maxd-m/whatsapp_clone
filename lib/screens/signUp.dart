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
  final TextEditingController _nameController =
      TextEditingController(); // NUEVO
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _phoneVerified = false;
  bool _isLoading = false;
  String? _verificationId;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _sendSMS() {
    if (_phoneController.text.isEmpty) {
      _showMessage("Ingresa un número válido");
      return;
    }
    setState(() => _isLoading = true);
    _authService.sendPhoneVerification(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (id) {
        setState(() {
          _isLoading = false;
          _verificationId = id;
        });
        _showOTPDialog();
      },
      onError: (err) {
        setState(() => _isLoading = false);
        _showMessage(err);
      },
    );
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Código SMS"),
        content: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "6 dígitos"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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

  void _registerUser() async {
    // Validamos que todos los campos estén llenos
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage("Por favor, completa todos los campos");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.linkEmailAndSendVerification(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(), // Enviamos el nombre
      );
      setState(() => _isLoading = false);
      _showMessage("¡Éxito! Verifica tu email antes de iniciar sesión.");
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.green),
            const SizedBox(height: 30),
            if (!_phoneVerified) ...[
              // PASO 1: TELÉFONO
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Teléfono (+52...)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendSMS,
                      child: const Text("Enviar SMS"),
                    ),
            ] else ...[
              // PASO 2: DATOS PERSONALES
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de Usuario",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerUser,
                      child: const Text("Finalizar Registro"),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
