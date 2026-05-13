import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance; //

  // 1. Enviar el código SMS al teléfono
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Error al verificar el teléfono');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // 2. Verificar el código SMS
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception("El código es incorrecto o ha expirado.");
    }
  }

  // 3. Vincular Email y crear Perfil en Firestore
  Future<void> linkEmailAndSendVerification({
    required String email,
    required String password,
    required String displayName, // Nuevo parámetro
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        // Vinculamos el correo a la cuenta telefónica
        await user.linkWithCredential(credential);

        // Actualizamos el nombre en el perfil de Auth
        await user.updateDisplayName(displayName);

        // CREAMOS EL DOCUMENTO EN FIRESTORE
        // Usamos el UID generado por Auth como ID del documento
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': displayName,
          'email': email,
          'phone': user.phoneNumber,
          'photoUrl':
              'https://i.pravatar.cc/150?u=${user.uid}', // Imagen por defecto
          'contacts': [], // Lista de contactos inicial vacía
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Enviamos correo de verificación
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw Exception(e.message ?? "Error al registrar el correo.");
      }
    } else {
      throw Exception("No hay un usuario activo para vincular.");
    }
  }

  // Nuevo método: Iniciar sesión con Teléfono y Contraseña
  Future<void> signInWithPhoneAndPassword(String phone, String password) async {
    try {
      // 1. Buscamos el documento del usuario que tenga ese número de teléfono
      final query = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception("No existe una cuenta vinculada a este número.");
      }

      // 2. Obtenemos el email de ese documento
      String email = query.docs.first.get('email');

      // 3. Iniciamos sesión con el email y contraseña
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Error al iniciar sesión.");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 4. Iniciar Sesión
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Error al iniciar sesión.");
    }
  }

  // 4. Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
