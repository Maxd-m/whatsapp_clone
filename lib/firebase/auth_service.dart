// Archivo: lib/firebase/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Enviar el código SMS al teléfono
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber, // Debe incluir código de país (ej. +52)
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Resolución automática (solo en algunos dispositivos Android)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Error al verificar el teléfono');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(
            verificationId,
          ); // Devuelve el ID para usarlo con el código OTP
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // 2. Verificar el código SMS que el usuario ingresó
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Inicia sesión con el teléfono
      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception("El código es incorrecto o ha expirado.");
    }
  }

  // 3. Vincular el correo/contraseña a la cuenta telefónica y enviar email
  Future<void> linkEmailAndSendVerification({
    required String email,
    required String password,
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Creamos la credencial del correo y contraseña
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        // Vinculamos el correo a la cuenta actual (creada con el teléfono)
        await user.linkWithCredential(credential);

        // Enviamos el correo de verificación
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw Exception(e.message ?? "Error al registrar el correo.");
      }
    } else {
      throw Exception("No hay un usuario activo para vincular el correo.");
    }
  }
}
