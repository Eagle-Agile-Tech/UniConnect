import 'package:dio/dio.dart';
import 'package:uniconnect/data/chat_api.dart';
import 'package:uniconnect/data/repository/chat/chat_repository_remote.dart';
import 'package:uniconnect/data/service/api/routes/api_routes.dart';

class ChatSession {
  ChatSession._();

  static final ChatSession instance = ChatSession._();

  String? currentUserId;
  String? accessToken;

  bool get isAuthenticated =>
      currentUserId != null && currentUserId!.isNotEmpty &&
      accessToken != null && accessToken!.isNotEmpty;

  void bind({required String userId, required String token}) {
    currentUserId = userId;
    accessToken = token;
  }

  void clear() {
    currentUserId = null;
    accessToken = null;
  }

  Dio createAuthedDio() {
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

