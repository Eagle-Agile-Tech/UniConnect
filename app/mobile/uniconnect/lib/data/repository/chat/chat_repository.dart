import 'package:uniconnect/domain/models/chat/chat_conversation_model.dart';
import 'package:uniconnect/domain/models/chat/chat_message_model.dart';
import 'package:uniconnect/utils/result.dart';

abstract class ChatRepository {
  Future<Result<List<ChatConversationModel>>> listConversations();

  Future<Result<(String chatId, List<ChatMessageModel> messages)>>
  getConversationMessagesByUser({
    required String otherUserId,
    required String currentUserId,
  });

  Future<Result<List<ChatMessageModel>>> listMessages({
    required String chatId,
    required String currentUserId,
    int limit,
    int offset,
  });

  Future<Result<ChatMessageModel>> sendMessage({
    required String chatId,
    required String content,
    required String currentUserId,
    required String clientMessageId,
  });
}

