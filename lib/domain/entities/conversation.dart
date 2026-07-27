class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    this.listingId,
    this.lastMessageText = '',
    this.lastMessageAt,
  });

  final String id;
  final List<String> participantIds;
  final String? listingId;
  final String lastMessageText;
  final DateTime? lastMessageAt;

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String? ?? '',
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      listingId: map['listingId'] as String?,
      lastMessageText: map['lastMessageText'] as String? ?? '',
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.tryParse(map['lastMessageAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'listingId': listingId,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }
}
