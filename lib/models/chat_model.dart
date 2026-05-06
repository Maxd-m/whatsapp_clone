class LastMessage {
  final String text;
  final String senderId;
  final String type; // "text", "image", etc.
  final DateTime timestamp;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.type,
    required this.timestamp,
  });
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
}

class Chat {
  final String id;
  final String type; // "direct" o "group"
  final List<String> participants;
  final DateTime updatedAt;
  final LastMessage lastMessage;
  final GroupDetails? groupDetails;

  Chat({
    required this.id,
    required this.type,
    required this.participants,
    required this.updatedAt,
    required this.lastMessage,
    this.groupDetails,
  });
}
