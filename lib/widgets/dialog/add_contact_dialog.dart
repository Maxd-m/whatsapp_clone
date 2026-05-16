// lib/views/home/widgets/add_contact_dialog.dart
import 'package:flutter/material.dart';
import '../../../firebase/chat_service.dart';

class AddContactDialog extends StatefulWidget {
  final String currentUserId;
  final ChatService chatService;

  const AddContactDialog({
    super.key,
    required this.currentUserId,
    required this.chatService,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir nuevo contacto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresa el correo electrónico o número de teléfono:'),
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
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  final query = searchController.text.trim();
                  if (query.isEmpty) return;

                  setState(() => isLoading = true);
                  final resultMessage = await widget.chatService
                      .addContactByEmailOrPhone(widget.currentUserId, query);
                  setState(() => isLoading = false);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(resultMessage),
                        backgroundColor: resultMessage.contains('exitosamente')
                            ? const Color(0xFF25D366)
                            : Colors.redAccent,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
          ),
          child: const Text('Añadir', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
