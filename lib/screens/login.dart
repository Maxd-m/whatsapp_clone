import 'package:flutter/material.dart';
import '../firebase/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para obtener el texto de los campos
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Variable para mostrar el estado de carga
  bool _isLoading = false;

  void _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithPhoneAndPassword(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
      // NOTA: No necesitamos navegar. El StreamBuilder en main.dart lo hará solo.
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
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
                Icons.lock_person_rounded,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 48),

              // Campo de Teléfono
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de Teléfono (+52...)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Botón de Inicio de Sesión
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // ElevatedButton(
                //   onPressed: () => Navigator.pushNamed(context, '/home'),
                //   style: ElevatedButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(vertical: 16),
                //   ),
                //   child: const Text(
                //     'Iniciar Sesión',
                //     style: TextStyle(fontSize: 18),
                //   ),
                // ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Iniciar Sesión'),
                  ),
                ),
                const SizedBox(height: 8),
                // BOTÓN DE REGISTRO
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('¿No tienes cuenta? Regístrate aquí'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
