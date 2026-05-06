import 'package:flutter/material.dart';
import '../models/chat_model.dart';

// Datos de prueba locales para visualizar la UI
final List<Chat> mockChats = [
  Chat(
    id: '1',
    type: 'group',
    participants: ['uid_juan', 'uid_maria', 'uid_pedro'],
    updatedAt: DateTime.now(),
    lastMessage: LastMessage(
      text: '¡Hola! ¿A qué hora el partido?',
      senderId: 'uid_maria',
      type: 'text',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    groupDetails: GroupDetails(
      name: 'Amigos del Fútbol',
      photoUrl: 'https://i.pravatar.cc/150?u=futbol',
      admins: ['uid_juan'],
      hidePhoneNumbers: true,
    ),
  ),
  Chat(
    id: '2',
    type: 'direct',
    participants: ['uid_yo', 'uid_juan'],
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    lastMessage: LastMessage(
      text: 'Hola, ¿cómo estás?',
      senderId: 'uid_juan',
      type: 'text',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ),
  Chat(
    id: '3',
    type: 'direct',
    participants: ['uid_yo', 'uid_pedro'],
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    lastMessage: LastMessage(
      text: 'Envié la imagen',
      senderId: 'uid_pedro',
      type: 'image',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Barra de búsqueda al estilo WhatsApp
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Listado de chats
          Expanded(
            child: ListView.separated(
              itemCount: mockChats.length,
              separatorBuilder: (context, index) =>
                  const Divider(indent: 85, endIndent: 10, height: 1),
              itemBuilder: (context, index) {
                final chat = mockChats[index];
                final isGroup = chat.type == 'group';

                // Nombre a mostrar (Lógica simplificada para el mock)
                String displayName = isGroup
                    ? chat.groupDetails?.name ?? 'Grupo'
                    : 'Contacto ${chat.participants.firstWhere((p) => p != 'uid_yo')}';

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        isGroup && chat.groupDetails?.photoUrl != null
                        ? NetworkImage(chat.groupDetails!.photoUrl)
                        : null,
                    child:
                        (isGroup && chat.groupDetails?.photoUrl == null) ||
                            !isGroup
                        ? Icon(
                            isGroup ? Icons.group : Icons.person,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      if (chat.lastMessage.type == 'image')
                        const Icon(Icons.image, size: 16, color: Colors.grey),
                      if (chat.lastMessage.type == 'image')
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat.lastMessage.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    "${chat.lastMessage.timestamp.hour}:${chat.lastMessage.timestamp.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    // Aquí iría la navegación al chat detallado
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
