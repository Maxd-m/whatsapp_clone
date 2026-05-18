import 'package:flutter/material.dart';
import '../firebase/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  final AuthService _authService = AuthService();

  String? _verificationId; 
  
  bool _isPasswordVisible = false;
  String _selectedCountryCode = '+52';
  final List<String> _countryCodes = ['+52', '+1', '+34', '+54', '+56', '+57', '+58']; 

  BuildContext? _loadingDialogContext;
  BuildContext? _otpDialogContext;

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

  void _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos")),
      );
      return;
    }

    String fullPhoneNumber = "$_selectedCountryCode${_phoneController.text.trim()}";

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _showLoadingModal("Verificando contraseña...");

    try {
      await _authService.signInWithPhoneAndPassword(
        fullPhoneNumber,
        _passwordController.text.trim(),
      );

      await _authService.signOut();

      await Future.delayed(const Duration(seconds: 1));
      _hideLoadingModal();
      _showLoadingModal("Enviando SMS a $fullPhoneNumber...");

      await _authService.sendPhoneVerification(
        phoneNumber: fullPhoneNumber,
        isLogin: true, 
        onCodeSent: (id) {
          _hideLoadingModal();
          setState(() {
            _verificationId = id;
          });
          _showOTPDialog(); 
        },
        onError: (err) async {
          _hideLoadingModal();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(err)));
        },
      );
    } catch (e) {
      _hideLoadingModal();
      String errorText = e.toString().replaceAll('Exception: ', '');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) {
        _otpDialogContext = ctx; 
        return AlertDialog(
          title: const Text("Código de Seguridad"),
          content: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Ingresa los 6 dígitos del SMS"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_otpDialogContext != null) Navigator.pop(_otpDialogContext!);
                _otpController.clear();
              },
              child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                // Cerramos cuadro de texto
                if (_otpDialogContext != null) Navigator.pop(_otpDialogContext!);
                
                _showLoadingModal("Verificando código...");
                
                try {
                  await Future.delayed(const Duration(seconds: 1)); // Efecto UX

                  await _authService.verifyOTP(
                    verificationId: _verificationId!,
                    smsCode: _otpController.text.trim(),
                  );
                  
                  _hideLoadingModal();
                  
                } catch (e) {
                  _hideLoadingModal();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()))
                  );
                }
              },
              child: const Text("Verificar"),
            ),
          ],
        );
      }
    );
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

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
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

              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}