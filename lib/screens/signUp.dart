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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _phoneVerified = false;
  bool _isLoading = false;
  String? _verificationId;

  String _selectedCountryCode = '+52';
  final List<String> _countryCodes = ['+52', '+1', '+34', '+54', '+56', '+57', '+58'];

  BuildContext? _loadingDialogContext;
  BuildContext? _otpDialogContext;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showLoadingModal(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _loadingDialogContext = ctx;
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingModal() {
    if (_loadingDialogContext != null) {
      Navigator.pop(_loadingDialogContext!);
      _loadingDialogContext = null;
    }
  }

  void _sendSMS() async {
    if (_phoneController.text.isEmpty) {
      _showMessage("Ingresa un número válido");
      return;
    }

    String fullPhoneNumber = "$_selectedCountryCode${_phoneController.text.trim()}";

    // ¡AQUÍ ESTÁ EL CAMBIO VISUAL!
    // Usamos tu modal con texto en lugar de solo un boolean
    _showLoadingModal("Verificando número...");

    try {
      await _authService.sendPhoneVerification(
        phoneNumber: fullPhoneNumber,
        
        onAutoVerified: () {
          if (!mounted) return;
          _hideLoadingModal(); // Quitamos el modal de carga
          setState(() {
            _phoneVerified = true; 
          });
        },

        onCodeSent: (id) async {
          if (!mounted) return;
          
          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;

          try {
            await _authService.verifyOTP(
              verificationId: id,
              smsCode: '123456', 
            );

            if (!mounted) return;
            
            _hideLoadingModal(); 
            
            setState(() {
              _phoneVerified = true;
            });
            _showMessage("¡Número verificado exitosamente!");

          } catch (e) {
            if (!mounted) return;
            _hideLoadingModal();
            _showMessage("Error en la verificación simulada");
          }
        },

        onError: (err) {
          if (!mounted) return; 
          _hideLoadingModal(); 
          _showMessage(err);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _hideLoadingModal(); 
      _showMessage("Error: ${e.toString()}");
    }
  }

  void _registerUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage("Por favor, completa todos los campos");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage("Las contraseñas no coinciden. Intenta de nuevo.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.linkEmailAndSendVerification(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(), 
      );

      await _authService.signOut();

      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage("¡Éxito! Verifica tu email antes de iniciar sesión.");
      
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (_phoneVerified) {
          _showLoadingModal("Cancelando registro...");
          await _authService.signOut(); 
          _hideLoadingModal();
        }

        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Registro")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.green),
              const SizedBox(height: 30),
              
              if (!_phoneVerified) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Número de Teléfono",
                    border: const OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          items: _countryCodes.map((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCountryCode = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirmar Contraseña",
                    prefixIcon: Icon(Icons.lock_outline),
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
      ),
    );
  }
}