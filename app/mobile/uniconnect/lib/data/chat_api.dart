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

      final dynamic responseData = response.data;
      List<dynamic> chatsRaw = [];

      if (responseData is List) {
        chatsRaw = responseData;
      } else if (responseData is Map) {
        chatsRaw = (responseData['chats'] ?? responseData['data'] ?? responseData['conversations'] ?? const []) as List<dynamic>;
      }

      return chatsRaw
          .whereType<Map>()
          .map((chat) => Map<String, dynamic>.from(chat))
          .toList();
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

      final dynamic responseData = response.data;
      List<dynamic> messagesRaw = [];

      if (responseData is List) {
        messagesRaw = responseData;
      } else if (responseData is Map) {
        messagesRaw = (responseData['messages'] ?? responseData['data'] ?? const []) as List<dynamic>;
      }

      return messagesRaw
          .whereType<Map>()
          .map((message) => Map<String, dynamic>.from(message))
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

  Future<Map<String, dynamic>> createChat({
    required String type,
    String? participantId,
    String? name,
    List<String>? participantIds,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/chats',
        data: {
          'type': type,
          if (participantId != null) 'participantId': participantId,
          if (name != null) 'name': name,
          if (participantIds != null) 'participantIds': participantIds,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<Map<String, dynamic>> updateGroupChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.patch(
        '/chats',
        data: {
          'chatId': chatId,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> addParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _dio.post(
        '/chats/participants',
        data: {'chatId': chatId, 'userId': userId},
      );
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _dio.delete(
        '/chats/participants',
        data: {'chatId': chatId, 'userId': userId},
      );
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _dio.patch(
        '/chats/messages',
        data: {'messageId': messageId, 'content': content},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _dio.delete(
        '/chats/messages',
        data: {'messageId': messageId},
      );
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<Map<String, dynamic>> reactToMessage({
    required String messageId,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '/chats/messages/reactions',
        data: {'messageId': messageId, 'type': type},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> markAsDelivered({required String chatId, String? messageId}) async {
    try {
      await _dio.post('/chats/delivered', data: {'chatId': chatId, 'messageId': messageId});
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }

  Future<void> sendTyping({required String chatId, required bool isTyping}) async {
    try {
      await _dio.post('/chats/typing', data: {'chatId': chatId, 'isTyping': isTyping});
    } catch (error) {
      throw ChatFailure.fromException(error);
    }
  }
}

