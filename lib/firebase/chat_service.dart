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
}
