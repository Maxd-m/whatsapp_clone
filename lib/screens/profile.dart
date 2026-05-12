import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../firebase/chat_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ChatService _chatService = ChatService();
  // TODO: Reemplazar por el ID real de Firebase Auth cuando esté implementado
  final String currentUserId = 'uid_yo';

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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // Usamos StreamBuilder para escuchar cambios en tiempo real del perfil
      body: StreamBuilder<UserProfile>(
        stream: _chatService.getUserProfileStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el perfil'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          return Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(user.photoUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Lógica para editar el perfil
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Editar Perfil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
