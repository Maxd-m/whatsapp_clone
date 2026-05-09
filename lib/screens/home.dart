import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../firebase/chat_service.dart';
import 'chat_screen.dart'; // Importa la pantalla que crearemos en el paso 4

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final String currentUserId =
      'uid_yo'; // TODO: Obtener de FirebaseAuth.instance.currentUser!.uid

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
          // Tus íconos
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tu barra de búsqueda aquí... (Omitida por brevedad)
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: _chatService.getChatsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final chats = snapshot.data!;
                if (chats.isEmpty)
                  return const Center(child: Text('No tienes chats aún'));

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) =>
                      const Divider(indent: 85, endIndent: 10, height: 1),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isGroup = chat.type == 'group';

                    String displayName = isGroup
                        ? chat.groupDetails?.name ?? 'Grupo'
                        : 'Contacto ${chat.participants.firstWhere((p) => p != currentUserId, orElse: () => 'Desconocido')}';

                    return ListTile(
                      leading: CircleAvatar(
                        /* Tu lógica actual de CircleAvatar */
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: chat.lastMessage != null
                          ? Text(
                              chat.lastMessage!.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text('Nuevo chat'),
                      trailing: chat.lastMessage != null
                          ? Text(
                              "${chat.lastMessage!.timestamp.hour}:${chat.lastMessage!.timestamp.minute.toString().padLeft(2, '0')}",
                            )
                          : null,
                      onTap: () {
                        // NAVEGAMOS AL CHAT
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chat.id,
                              chatTitle: displayName,
                              currentUserId: currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
