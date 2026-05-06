import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LinxChat',
          style: TextStyle(
            color: Color(0xFF25D366),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.camera_alt_outlined),
          // ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat)),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://avatars.githubusercontent.com/u/12345678?v=4',
              ), // Reemplaza con la URL de tu imagen
            ),
            const SizedBox(height: 16),
            const Text(
              'Nombre de Usuario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Correo Electrónico',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes agregar la lógica para editar el perfil
              },
              child: const Text('Editar Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
