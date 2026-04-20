import 'package:chat_plugin/chat_plugin.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/api/token_refresher.dart';
import 'package:uniconnect/ui/chat/viewmodels/chat_provider.dart';

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

      await _setUpChatApiHandlers(userId);
      await ChatPlugin.chatService.initialize();
      await ChatPlugin.chatService.loadChatRooms();
    } catch (e) {
      debugPrint("Chat Initialization Error: $e");
    }
  }

  Future<void> _setUpChatApiHandlers(String userId) async {
    final apiHandlers = ChatApiHandlers(
      loadMessagesHandler: ({page = 1, limit = 20, searchText = ""}) async {
        final chatId = _ref.read(activeRoomProvider.notifier).state;
        if (chatId == null || chatId.isEmpty) return [];
        try {
          final offset = (page - 1) * limit;

          final response = await _client.get(
            "$baseUrl/chats/messages",
            queryParameters: {
              'chatId': chatId,
              'offset': offset,
              'limit': limit,
            },
          );
          if (response.statusCode == 200) {
            final List messages = response.data['messages'];
            return messages
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
          final response = await _client.get("$baseUrl/chats/");
          if (response.statusCode == 200) {
            final roomsList = response.data['chats'] as List;
            final Map<String, int> initialCounts = {};

            final chatIds = <String>[];

            final chatRooms = roomsList.map((room) {
              chatIds.add(room['id']);

              final participants = room['participants'] as List;
              final otherParticipant = participants.firstWhere(
                    (p) => p['userId'] != userId,
                orElse: () => participants.first,
              );

              // todo: message count isn't right
              final count = room['_count']?['messages'] ?? 0;
              initialCounts[otherParticipant['user']['id']] = count;

              //todo: messages are sent

              return ChatRoom(
                userId: otherParticipant['user']['id'],
                username: otherParticipant['user']['name'],
                avatarUrl: otherParticipant['user']['avatarUrl'],
                latestMessage: room['messages']?.isNotEmpty == true
                    ? room['messages'][0]['content']
                    : 'No messages yet',
                latestMessageTime: room['messages']?.isNotEmpty == true
                    ? DateTime.parse(room['messages'][0]['createdAt'])
                    : DateTime.now(),
                unreadCount: room['_count']?['messages'] ?? 0,
              );
            }).toList();

            _ref.read(chatIdProvider.notifier).state = chatIds;
            _ref.read(unreadCountProvider.notifier).state = initialCounts;
            return chatRooms;
          }
          return [];
        } catch (e) {
          return [];
        }
      },
      //todo: api handler to handle users chatUsers
    );
    ChatPlugin.chatService.setApiHandlers(apiHandlers);
  }
}
