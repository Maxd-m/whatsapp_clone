import 'package:cloud_firestore/cloud_firestore.dart';

class LastMessage {
  final String text;
  final String senderId;
  final String type;
  final DateTime timestamp;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.type,
    required this.timestamp,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class GroupDetails {
  final String name;
  final String photoUrl;
  final List<String> admins;
  final bool hidePhoneNumbers;

  GroupDetails({
    required this.name,
    required this.photoUrl,
    required this.admins,
    required this.hidePhoneNumbers,
  });

  factory GroupDetails.fromMap(Map<String, dynamic> map) {
    return GroupDetails(
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      admins: List<String>.from(map['admins'] ?? []),
      hidePhoneNumbers: map['hidePhoneNumbers'] ?? false,
    );
  }
}

class Chat {
  final String id;
  final String type;
  final List<String> participants;
  final DateTime updatedAt;
  final LastMessage? lastMessage; // Puede ser null si el chat es nuevo
  final GroupDetails? groupDetails;

  Chat({
    required this.id,
    required this.type,
    required this.participants,
    required this.updatedAt,
    this.lastMessage,
    this.groupDetails,
  });

  factory Chat.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      type: map['type'] ?? 'direct',
      participants: List<String>.from(map['participants'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] != null
          ? LastMessage.fromMap(map['lastMessage'])
          : null,
      groupDetails: map['groupDetails'] != null
          ? GroupDetails.fromMap(map['groupDetails'])
          : null,
    );
  }
}

// NUEVO MODELO PARA LOS MENSAJES INDIVIDUALES
class Message {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback por si hay delay en el servidor
    );
  }
}

class UserModel {
  final String uid;
  final List<String> contacts;

  UserModel({required this.uid, required this.contacts});

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      contacts: List<String>.from(map['contacts'] ?? []),
    );
  }
}

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String photoUrl;
  final bool createGroup;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    this.createGroup = false,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: map['displayName'] ?? 'Usuario',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? 'https://via.placeholder.com/150',
      createGroup: map['createGroup'] ?? false,
    );
  }
}
