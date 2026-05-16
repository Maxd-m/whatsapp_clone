import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../firebase/auth_service.dart';
import '../firebase/chat_service.dart';
import 'chat_screen.dart'; // Importa la pantalla que crearemos en el paso 4

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  late String currentUserId;
  List<String> _myContactIds = [];

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir nuevo contacto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa el correo electrónico o número de teléfono:',
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'ej: test@mail.com o +52...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 15),
                    const CircularProgressIndicator(color: Color(0xFF25D366)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final query = searchController.text.trim();
                          if (query.isEmpty) return;

                          setStateDialog(() => isLoading = true);

                          // Llamamos a nuestro nuevo método del servicio
                          final resultMessage = await _chatService
                              .addContactByEmailOrPhone(currentUserId, query);

                          setStateDialog(() => isLoading = false);

                          if (context.mounted) {
                            Navigator.pop(context); // Cierra el diálogo
                            // Mostramos el resultado con un SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(resultMessage),
                                backgroundColor:
                                    resultMessage.contains('exitosamente')
                                    ? const Color(0xFF25D366)
                                    : Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  child: const Text(
                    'Añadir',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Obtenemos el ID de forma segura
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isNotEmpty) {
      // Escuchar cambios en los contactos
      _chatService.getContactIdsStream(currentUserId).listen((contacts) {
        setState(() {
          _myContactIds = contacts;
        });
      });
    }
  }

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
        automaticallyImplyLeading: false,
        actions: [
          // Tus íconos
          IconButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
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
              stream: _chatService.getFilteredChatsStream(
                currentUserId,
                _myContactIds,
              ),
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
                        : '${chat.participants.firstWhere((p) => p != currentUserId, orElse: () => 'Desconocido')}';

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
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
