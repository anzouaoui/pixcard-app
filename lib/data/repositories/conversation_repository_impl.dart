import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/domain/entities/message.dart';
import 'package:pixcard/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _conversations =>
      _firestore.collection('conversations');

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    final docRef = _conversations.doc();
    final newConversation = Conversation(
      id: docRef.id,
      participantIds: conversation.participantIds,
      listingId: conversation.listingId,
      lastMessageText: conversation.lastMessageText,
      lastMessageAt: conversation.lastMessageAt,
    );
    await docRef.set(newConversation.toMap());
    return newConversation;
  }

  @override
  Future<Conversation> getConversationById(String id) async {
    final doc = await _conversations.doc(id).get();
    if (!doc.exists) throw Exception('Conversation not found');
    return Conversation.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<List<Conversation>> getConversationsByUser(String userId) async {
    final snapshot = await _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Conversation.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Stream<List<Conversation>> watchConversationsByUser(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Conversation.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList(),
        );
  }

  @override
  Future<void> sendMessage(String conversationId, Message message) async {
    final messagesRef =
        _conversations.doc(conversationId).collection('messages');
    final docRef = messagesRef.doc();

    final newMessage = Message(
      id: docRef.id,
      senderId: message.senderId,
      type: message.type,
      text: message.text,
      offerId: message.offerId,
      createdAt: DateTime.now(),
    );

    await docRef.set(newMessage.toMap());

    // Update conversation metadata
    await _conversations.doc(conversationId).update({
      'lastMessageText': message.text ?? '',
      'lastMessageAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 30,
  }) async {
    final snapshot = await _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Message.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Message.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }

  @override
  Future<Conversation?> getConversationByListing(String listingId, List<String> participantIds) async {
    final snapshot = await _conversations
        .where('listingId', isEqualTo: listingId)
        .where('participantIds', arrayContains: participantIds.first)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Conversation.fromMap({
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data() as Map<String, dynamic>,
    });
  }
}
