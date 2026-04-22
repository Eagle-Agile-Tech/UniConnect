import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/api/api_client.dart';
import 'package:uniconnect/domain/models/chat/chat_message/chat_message.dart';

import '../../../utils/result.dart';

final chatRepoProvider = Provider((ref) => ChatRepositoryRemote(ref.watch(apiClientProvider)));

class ChatRepositoryRemote {
  ChatRepositoryRemote(this._apiClient);
  final ApiClient _apiClient;

  Future<Result<Map<String, dynamic>>> getChatId(String receiverId, String userId) async {
    final result = await _apiClient.getChatId(receiverId);
    return result.fold(
          (data) {
        final List messages = data['messages'].map((message) => ChatMessage.fromMap(message, userId)).toList();
        return Result.ok({
          'chatId': data['chatId'],
          'messages': messages
        });
      }, (error, stackTrace) => Result.error(error),
    );
  }
}