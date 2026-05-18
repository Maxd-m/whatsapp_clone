import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerified, 
    bool isLogin = false, 
  }) async {
    try {
      final query = await _db
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (!isLogin && query.docs.isNotEmpty) {
        throw Exception("YA EXISTE UNA CUENTA CON ESE NUMERO ASOCIADO");
      }
      if (isLogin && query.docs.isEmpty) {
        throw Exception("No existe una cuenta vinculada a este número.");
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          onAutoVerified(); 
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
    required String displayName,
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.linkWithCredential(credential);
        await user.updateDisplayName(displayName);

        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': displayName,
          'email': email,
          'phone': user.phoneNumber,
          'photoUrl': 'https://i.pravatar.cc/150?u=${user.uid}',
          'contacts': [],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw Exception(e.message ?? "Error al registrar el correo.");
      }
    } else {
      throw Exception("No hay un usuario activo para vincular.");
    }
  }

Future<void> signInWithPhoneAndPassword(String phone, String password) async {
    try {
      final query = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw "No existe una cuenta vinculada a este número."; 
      }

      String email = query.docs.first.get('email');
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified && (userCredential.user!.email != "test@mail.com") ) {
        await _auth.signOut();
        throw "Por favor, revisa tu bandeja de entrada y verifica tu correo antes de iniciar sesión.";
      }

    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Contraseña incorrecta o error al iniciar sesión.";
    } catch (e) {
      throw e.toString();
    }
  }

  // 5. Iniciar Sesión (Email normal, por si lo ocupas)
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Error al iniciar sesión.");
    }
  }

  // 6. Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}