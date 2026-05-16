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

  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    List<UserProfile> selectedMembers = [];
    bool isLoading = false;
    bool isSearching = false; // Para mostrar cargando en el botón de buscar
    String? errorMessage; // Para mostrar errores como "usuario no encontrado"

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear nuevo grupo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre del grupo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Añadir integrantes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // 2. BUSCADOR DE INTEGRANTES
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Email o teléfono...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_add,
                                color: Color(0xFF25D366),
                              ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                final query = searchController.text.trim();
                                if (query.isEmpty) return;

                                setStateDialog(() {
                                  isSearching = true;
                                  errorMessage = null;
                                });

                                // Buscamos el usuario
                                final userProfile = await _chatService
                                    .searchUserByEmailOrPhone(query);

                                setStateDialog(() {
                                  isSearching = false;
                                  if (userProfile == null) {
                                    errorMessage = 'Usuario no encontrado';
                                  } else if (userProfile.uid == currentUserId) {
                                    errorMessage = 'Tú ya estás en el grupo';
                                  } else if (selectedMembers.any(
                                    (m) => m.uid == userProfile.uid,
                                  )) {
                                    errorMessage =
                                        'El usuario ya está en la lista';
                                  } else {
                                    // ¡Encontrado! Lo agregamos a la lista temporal
                                    selectedMembers.add(userProfile);
                                    searchController
                                        .clear(); // Limpiamos el input
                                    errorMessage = null;
                                  }
                                });
                              },
                      ),
                    ],
                  ),

                  // Mensaje de error si no se encuentra
                  if (errorMessage != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 15),

                  // 3. LISTA VISUAL DE INTEGRANTES SELECCIONADOS (CHIPS)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: selectedMembers.map((member) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: NetworkImage(member.photoUrl),
                        ),
                        label: Text(member.displayName),
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: () {
                          // Quitar de la lista si nos equivocamos
                          setStateDialog(() {
                            selectedMembers.removeWhere(
                              (m) => m.uid == member.uid,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 20),
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
                          final groupName = nameController.text.trim();
                          if (groupName.isEmpty) {
                            setStateDialog(
                              () => errorMessage =
                                  'Debes darle un nombre al grupo',
                            );
                            return;
                          }

                          setStateDialog(() => isLoading = true);

                          // Extraer los puros UIDs de los perfiles seleccionados
                          List<String> memberIds = selectedMembers
                              .map((m) => m.uid)
                              .toList();

                          // Llamar a nuestro servicio con la lista de integrantes
                          await _chatService.createGroupChat(
                            currentUserId,
                            groupName,
                            memberIds,
                          );

                          setStateDialog(() => isLoading = false);

                          if (context.mounted) {
                            Navigator.pop(context); // Cierra el diálogo
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Grupo creado exitosamente'),
                                backgroundColor: Color(0xFF25D366),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  child: const Text(
                    'Crear',
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
              // Si tiene el permiso, mostramos el botón de crear grupo
              if (canCreateGroup) ...[
                FloatingActionButton(
                  heroTag:
                      "btn_create_group", // Importante asignar un heroTag único
                  onPressed: () => _showCreateGroupDialog(context),
                  backgroundColor:
                      Colors.blueAccent, // Color distintivo para grupos
                  child: const Icon(Icons.group_add, color: Colors.white),
                ),
                const SizedBox(height: 15),
              ],

              // Tu botón existente de añadir contacto (el que creamos en el paso anterior)
              FloatingActionButton(
                heroTag:
                    "btn_add_contact", // Importante asignar un heroTag único
                onPressed: () =>
                    _showAddContactDialog(context), // Tu función anterior
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
