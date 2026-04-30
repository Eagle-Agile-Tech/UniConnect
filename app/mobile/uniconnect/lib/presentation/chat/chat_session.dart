import 'package:dio/dio.dart';
import 'package:uniconnect/data/chat_api.dart';
import 'package:uniconnect/data/repository/chat/chat_repository_remote.dart';
import 'package:uniconnect/data/service/api/routes/api_routes.dart';

class ChatSession {
  ChatSession._();

  static final ChatSession instance = ChatSession._();

  String? currentUserId;
  String? accessToken;
  Dio? _dio;

  bool get isAuthenticated =>
      currentUserId != null && currentUserId!.isNotEmpty;

  void bind({required String userId, String? token, Dio? dio}) {
    currentUserId = userId;
    accessToken = token;
    if (dio != null) _dio = dio;
  }

  void clear() {
    currentUserId = null;
    accessToken = null;
    _dio = null;
  }

  Dio createAuthedDio() {
    if (_dio != null) return _dio!;

    final token = accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Chat session is not authenticated');
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  ChatApi createChatApi() => ChatApi(createAuthedDio());

  ChatRepositoryRemote createChatRepository() {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Chat session has no active user');
    }
    return ChatRepositoryRemote(createChatApi(), currentUserId: userId);
  }
}

