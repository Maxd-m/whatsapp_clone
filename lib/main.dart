import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login.dart';
import 'screens/signUp.dart';
import 'screens/home.dart';
import 'screens/profile.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('CREDENCIALES: ${dotenv.env['SUPABASE_URL']}  ${dotenv.env['SUPABASE_ANON_KEY']}');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // StreamBuilder escucha si el usuario entra o sale
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
