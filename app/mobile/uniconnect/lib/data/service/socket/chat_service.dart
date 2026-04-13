import 'package:chat_plugin/chat_plugin.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/api/token_refresher.dart';

import '../../../ui/auth/auth_state_provider.dart';
import '../api/routes/api_routes.dart';

final chatServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ChatService(dio, ref: ref);
});

class ChatService {
  ChatService(Dio client, {required Ref ref}) : _ref = ref, _client = client;
  final Dio _client;
  final Ref _ref;

  Future<void> initializeChatPlugin([String? userId]) async {
    try {
      userId ??= _ref.watch(authNotifierProvider).value!.user!.id;
      await ChatPlugin.initialize(
        config: ChatConfig(
          apiUrl: baseUrl,
          userId: userId,
          enableTypingIndicators: true,
          enableReadReceipts: true,
          enableOnlineStatus: true,
          autoMarkAsRead: true,
          maxReconnectionAttempts: 5,
          debugMode: true,
        ),
      );
      await _setUpChatApiHandlers(userId, 'token');
      await ChatPlugin.chatService.initialize();
      await ChatPlugin.chatService.loadChatRooms();
    } catch (e) {}
  }

  Future<void> _setUpChatApiHandlers(String userId, String token) async {
    final apiHandlers = ChatApiHandlers(
      loadMessagesHandler: ({page = 1, limit = 20, searchText = ""}) async {
        final receiverId = ChatPlugin.chatService.receiverId;
        if (receiverId.isEmpty) return [];
        try {
          var url =
              "$baseUrl/chat/messages?senderId=$userId&receiverId=$receiverId&page=$page&limit=$limit";
          if (searchText.isNotEmpty) {
            url += '&searchText=${Uri.encodeComponent(searchText)}';
          }
          final response = await _client.get(url);
          if (response.statusCode == 200) {
            return response.data
                .map((msg) => ChatMessage.fromMap(msg, userId))
                .toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      },
      loadChatRoomsHandler: () async {
        try {
          var url = "$baseUrl/chat";
          final response = await _client.get(url);
          if (response.statusCode == 200) {
            return response.data.map((room) => ChatRoom.fromMap(room)).toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      },
    );
    ChatPlugin.chatService.setApiHandlers(apiHandlers);
  }
}
