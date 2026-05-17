import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../firebase/auth_service.dart';
import '../firebase/chat_service.dart';
import 'chat_screen.dart';
import '../widgets/dialog/add_contact_dialog.dart';
import '../widgets/dialog/create_group_dialog.dart';

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
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        currentUserId: currentUserId,
        chatService: _chatService,
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        currentUserId: currentUserId,
        chatService: _chatService,
      ),
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
        if (mounted) {
          setState(() {
            _myContactIds = contacts;
          });
        }
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
          // barra de búsqueda aquí.
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

                    if (isGroup) {
                      String displayName = chat.groupDetails?.name ?? 'Grupo';

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.group, color: Colors.white),
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
                    } 
                    else {
                      final otherUserId = chat.participants.firstWhere(
                        (p) => p != currentUserId, 
                        orElse: () => ''
                      );

                      return StreamBuilder<UserProfile>(
                        stream: _chatService.getUserProfileStream(otherUserId),
                        builder: (context, snapshot) {
                          String displayName = 'Cargando...';
                          Widget avatar = const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          );

                          if (snapshot.hasData) {
                            final user = snapshot.data!;
                            
                            displayName = user.displayName.isNotEmpty 
                                ? user.displayName 
                                : 'Desconocido';

                            if (user.photoUrl.isNotEmpty) {
                              avatar = CircleAvatar(
                                backgroundImage: NetworkImage(user.photoUrl),
                              );
                            }
                          }

                          return ListTile(
                            leading: avatar, 
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
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<UserProfile>(
        stream: _chatService.getUserProfileStream(currentUserId),
        builder: (context, snapshot) {
          bool canCreateGroup = false;

          if (snapshot.hasData && snapshot.data != null) {
            canCreateGroup = snapshot.data!.createGroup;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Si tiene el permiso, mostra crear grupo
              if (canCreateGroup) ...[
                FloatingActionButton(
                  heroTag: "btn_create_group",
                  onPressed: () => _showCreateGroupDialog(context),
                  backgroundColor: Colors.blueAccent, // Color distintivo
                  child: const Icon(Icons.group_add, color: Colors.white),
                ),
                const SizedBox(height: 15),
              ],

              FloatingActionButton(
                heroTag: "btn_add_contact",
                onPressed: () => _showAddContactDialog(context),
                backgroundColor: const Color(0xFF25D366),
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}
