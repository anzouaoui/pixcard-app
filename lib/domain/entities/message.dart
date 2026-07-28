enum MessageType { text, offer, system }

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.offerId,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? offerId;
  final DateTime? createdAt;

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      text: map['text'] as String?,
      offerId: map['offerId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'type': type.name,
      'text': text,
      'offerId': offerId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
