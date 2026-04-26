import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_failure.dart';
import 'service/api/token_refresher.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(dioProvider));
});

class ChatApi {
  const ChatApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    try {
      final response = await _dio.get('/chats/$otherUserId');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<List<Map<String, dynamic>>> listConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/chats',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final chats = (data['chats'] as List<dynamic>? ?? const []);
      return chats.map((chat) => Map<String, dynamic>.from(chat as Map)).toList();
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<List<Map<String, dynamic>>> listMessages({
    required String chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/chats/messages',
        queryParameters: {'chatId': chatId, 'limit': limit, 'offset': offset},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final messages = (data['messages'] as List<dynamic>? ?? const []);
      return messages
          .map((message) => Map<String, dynamic>.from(message as Map))
          .toList();
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    required String clientMessageId,
  }) async {
    try {
      final response = await _dio.post(
        '/chats/messages',
        data: {
          'chatId': chatId,
          'content': content,
          'clientMessageId': clientMessageId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> markAsRead({required String chatId, String? messageId}) async {
    try {
      await _dio.post('/chats/read', data: {'chatId': chatId, 'messageId': messageId});
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }
}

