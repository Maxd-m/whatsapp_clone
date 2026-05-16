import 'package:flutter/material.dart';
import '../../firebase/chat_service.dart';
import '../../models/chat_model.dart';

class CreateGroupDialog extends StatefulWidget {
  final String currentUserId;
  final ChatService chatService;

  const CreateGroupDialog({
    super.key,
    required this.currentUserId,
    required this.chatService,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<UserProfile> selectedMembers = [];
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear nuevo grupo'),
      content: SingleChildScrollView(
        child: Column(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add, color: Color(0xFF25D366)),
                  onPressed: isSearching ? null : _searchUser,
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 5),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 15),
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
                    setState(
                      () => selectedMembers.removeWhere(
                        (m) => m.uid == member.uid,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            if (isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF25D366)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _createGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
          ),
          child: const Text('Crear', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _searchUser() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    final userProfile = await widget.chatService.searchUserByEmailOrPhone(
      query,
    );

    setState(() {
      isSearching = false;
      if (userProfile == null) {
        errorMessage = 'Usuario no encontrado';
      } else if (userProfile.uid == widget.currentUserId) {
        errorMessage = 'Tú ya estás en el grupo';
      } else if (selectedMembers.any((m) => m.uid == userProfile.uid)) {
        errorMessage = 'El usuario ya está en la lista';
      } else {
        selectedMembers.add(userProfile);
        searchController.clear();
        errorMessage = null;
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = nameController.text.trim();
    if (groupName.isEmpty) {
      setState(() => errorMessage = 'Debes darle un nombre al grupo');
      return;
    }

    if (selectedMembers.isEmpty) {
      setState(() => errorMessage = 'Añade al menos un integrante');
      return;
    }

    setState(() => isLoading = true);

    try {
      List<String> memberIds = selectedMembers.map((m) => m.uid).toList();
      await widget.chatService.createGroupChat(
        widget.currentUserId,
        groupName,
        memberIds,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo creado exitosamente'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al crear el grupo';
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
