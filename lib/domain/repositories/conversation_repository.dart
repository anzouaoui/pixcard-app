import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/domain/entities/message.dart';

abstract interface class ConversationRepository {
  Future<Conversation> createConversation(Conversation conversation);
  Future<Conversation> getConversationById(String id);
  Future<List<Conversation>> getConversationsByUser(String userId);
  Stream<List<Conversation>> watchConversationsByUser(String userId);
  Future<void> sendMessage(String conversationId, Message message);
  Future<List<Message>> getMessages(String conversationId, {int limit});
  Stream<List<Message>> watchMessages(String conversationId);
}
