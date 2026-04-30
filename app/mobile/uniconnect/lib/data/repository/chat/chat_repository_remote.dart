import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/chat_api.dart';
import 'package:uniconnect/data/chat_failure.dart';
import 'package:uniconnect/domain/models/chat/chat_conversation_model.dart';
import 'package:uniconnect/domain/models/chat/chat_message_model.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../utils/result.dart';
import 'chat_repository.dart';

final chatRepoProvider = Provider<ChatRepositoryRemote>((ref) {
  final currentUserId = ref.watch(authNotifierProvider).value?.user?.id ?? '';
  return ChatRepositoryRemote(
    ref.watch(chatApiProvider),
    currentUserId: currentUserId,
  );
});

class ChatRepositoryRemote implements ChatRepository {
  const ChatRepositoryRemote(this._chatApi, {required String currentUserId})
    : _currentUserId = currentUserId;

  final ChatApi _chatApi;
  final String _currentUserId;

  @override
  Future<Result<(String chatId, List<ChatMessageModel> messages)>>
  getConversationMessagesByUser({
    required String otherUserId,
    required String currentUserId,
  }) async {
    try {
      final data = await _chatApi.getOrCreateConversation(otherUserId);
      final messagesRaw = (data['messages'] as List<dynamic>? ?? const []);
      final messages = messagesRaw
          .whereType<Map>()
          .map(
            (item) => ChatMessageModel.fromApi(
              Map<String, dynamic>.from(item),
              currentUserId,
            ),
          )
          .toList()
          .reversed
          .toList();

      final chatId = (data['chatId'] ?? data['id'] ?? data['_id'] ?? '')
          .toString();
      return Result.ok((chatId, messages));
    } catch (error, stackTrace) {
      return Result.error(ChatFailure.fromException(error), stackTrace);
    }
  }

  @override
  Future<Result<List<ChatConversationModel>>> listConversations() async {
    try {
      final chats = await _chatApi.listConversations(type: 'DIRECT');
      final conversations = chats
          .map((chat) => ChatConversationModel.fromApi(chat, _currentUserId))
          .toList();
      return Result.ok(conversations);
    } catch (error, stackTrace) {
      return Result.error(ChatFailure.fromException(error), stackTrace);
    }
  }

  @override
  Future<Result<List<ChatMessageModel>>> listMessages({
    required String chatId,
    required String currentUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final messages = await _chatApi.listMessages(
        chatId: chatId,
        limit: limit,
        offset: offset,
      );
      final items = messages
          .map((item) => ChatMessageModel.fromApi(item, currentUserId))
          .toList()
          .reversed
          .toList();
      return Result.ok(items);
    } catch (error, stackTrace) {
      return Result.error(ChatFailure.fromException(error), stackTrace);
    }
  }

  @override
  Future<Result<ChatMessageModel>> sendMessage({
    required String chatId,
    required String content,
    required String currentUserId,
    required String clientMessageId,
  }) async {
    try {
      final data = await _chatApi.sendMessage(
        chatId: chatId,
        content: content,
        clientMessageId: clientMessageId,
      );
      return Result.ok(ChatMessageModel.fromApi(data, currentUserId));
    } catch (error, stackTrace) {
      return Result.error(ChatFailure.fromException(error), stackTrace);
    }
  }
}
