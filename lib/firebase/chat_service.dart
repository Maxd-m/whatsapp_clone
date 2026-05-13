import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Obtener los chats recientes (Para el Home)
  Stream<List<Chat>> getChatsStream(String currentUserId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Chat.fromDocument(doc)).toList(),
        );
  }

  // 2. Obtener los mensajes de un chat específico (Para el ChatScreen)
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: true,
        ) // Descendente para que el último esté abajo
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromDocument(doc)).toList(),
        );
  }

  // 3. Enviar un mensaje
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
    String type,
  ) async {
    final now = Timestamp.now();

    // Crear el mensaje en la subcolección
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'type': type,
      'createdAt': now,
    });

    // Actualizar el "lastMessage" y "updatedAt" del chat general
    await _db.collection('chats').doc(chatId).update({
      'updatedAt': now,
      'lastMessage': {
        'senderId': senderId,
        'text': text,
        'type': type,
        'timestamp': now,
      },
    });
  }

  // 4. Obtener la lista de contactos del usuario
  Stream<List<String>> getContactIdsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }
    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      return List<String>.from(doc.data()?['contacts'] ?? []);
    });
  }

  // 5. Modificar u obtener un stream filtrado
  Stream<List<Chat>> getFilteredChatsStream(
    String currentUserId,
    List<String> contactIds,
  ) {
    return getChatsStream(currentUserId).map((chats) {
      return chats.where((chat) {
        // Si es un grupo, generalmente se muestra siempre
        if (chat.type == 'group') return true;

        // Si es chat directo, verificar si el otro participante es contacto
        String otherParticipant = chat.participants.firstWhere(
          (p) => p != currentUserId,
          orElse: () => '',
        );
        return contactIds.contains(otherParticipant);
      }).toList();
    });
  }

  Stream<UserProfile> getUserProfileStream(String uid) {
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return UserProfile.fromDocument(doc);
    });
  }
}
