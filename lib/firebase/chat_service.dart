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

  // 6. Añadir un contacto por email o teléfono y crear chat
  Future<String> addContactByEmailOrPhone(
    String currentUserId,
    String query,
  ) async {
    try {
      // Intentamos buscar primero por email
      var emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: query)
          .get();
      // Y también por teléfono
      var phoneQuery = await _db
          .collection('users')
          .where('phone', isEqualTo: query)
          .get();

      String? newContactId;

      if (emailQuery.docs.isNotEmpty) {
        newContactId = emailQuery.docs.first.id;
      } else if (phoneQuery.docs.isNotEmpty) {
        newContactId = phoneQuery.docs.first.id;
      }

      if (newContactId != null) {
        // Evitar que el usuario se agregue a sí mismo
        if (newContactId == currentUserId) {
          return 'No puedes agregarte a ti mismo.';
        }

        // 1. Agregar el UID encontrado al arreglo 'contacts'
        await _db.collection('users').doc(currentUserId).update({
          'contacts': FieldValue.arrayUnion([newContactId]),
        });

        // 2. Crear el chat vacío en la colección 'chats' si no existe
        await _createDirectChatIfNotExists(currentUserId, newContactId);

        return 'Contacto agregado y chat creado exitosamente.';
      } else {
        return 'Usuario no encontrado.';
      }
    } catch (e) {
      return 'Error al buscar el usuario: $e';
    }
  }

  // 7. Crear un chat grupal
  Future<void> createGroupChat(
    String currentUserId,
    String groupName,
    List<String> memberIds,
  ) async {
    // Asegurarnos de que el creador está en la lista de participantes y que no haya duplicados
    List<String> allParticipants = [
      currentUserId,
      ...memberIds,
    ].toSet().toList();
    // Al crear el grupo, inicializamos al creador como el único participante y administrador.
    await _db.collection('chats').add({
      'type': 'group',
      'participants': allParticipants,
      'updatedAt': FieldValue.serverTimestamp(),
      'groupDetails': {
        'name': groupName,
        'photoUrl':
            'https://picsum.photos/seed/${groupName.replaceAll(' ', '')}/200/200', // URL generada para foto aleatoria
        'admins': [currentUserId],
        'hidePhoneNumbers': true,
      },
      // Nota: lastMessage no se agrega hasta que alguien escriba
    });
  }

  // 8. Buscar usuario por email o teléfono y devolver su perfil ---
  Future<UserProfile?> searchUserByEmailOrPhone(String query) async {
    try {
      var emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: query)
          .get();
      var phoneQuery = await _db
          .collection('users')
          .where('phone', isEqualTo: query)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return UserProfile.fromDocument(emailQuery.docs.first);
      } else if (phoneQuery.docs.isNotEmpty) {
        return UserProfile.fromDocument(phoneQuery.docs.first);
      }
      return null; // Si no encuentra nada
    } catch (e) {
      print('Error al buscar usuario: $e');
      return null;
    }
  }

  // MÉTODO AUXILIAR: Verifica si el chat ya existe y si no, lo crea
  Future<void> _createDirectChatIfNotExists(String uid1, String uid2) async {
    // Buscamos los chats donde el usuario actual ya sea participante
    final querySnapshot = await _db
        .collection('chats')
        .where('participants', arrayContains: uid1)
        .where('type', isEqualTo: 'direct')
        .get();

    bool chatExists = false;

    // Iteramos para ver si en alguno de esos chats también está el uid2
    for (var doc in querySnapshot.docs) {
      List<dynamic> participants = doc.data()['participants'] ?? [];
      if (participants.contains(uid2)) {
        chatExists = true;
        break;
      }
    }

    // Si el chat no existe, lo creamos usando el formato de tu base de datos
    if (!chatExists) {
      await _db.collection('chats').add({
        'type': 'direct',
        'participants': [uid1, uid2],
        'updatedAt': FieldValue.serverTimestamp(),
        // No agregamos el campo 'lastMessage' aún porque es un chat vacío.
        // Tu modelo (chat_model.dart) ya está preparado para manejar 'lastMessage' como null.
      });
    }
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
