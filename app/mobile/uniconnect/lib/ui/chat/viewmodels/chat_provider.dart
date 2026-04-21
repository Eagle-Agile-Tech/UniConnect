import 'dart:async';

import 'package:chat_plugin/chat_plugin.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uniconnect/data/repository/chat/chat_repository_remote.dart';
import 'package:uniconnect/data/service/api/token_refresher.dart';
import 'package:uniconnect/data/service/socket/chat_service.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

final chatIdProvider =
    AsyncNotifierProvider.family<ChatIdViewModel, (String chatId, List<ChatMessage>), String>(
      ChatIdViewModel.new,
    );

class ChatIdViewModel extends AsyncNotifier<(String chatId, List<ChatMessage>)> {
  ChatIdViewModel(this.receiverId);

  final String receiverId;

  @override
  FutureOr<(String chatId, List<ChatMessage>)> build() async {
    final userId = ref.read(authNotifierProvider).value!.user!.id;
    final result = await ref.read(chatRepoProvider).getChatId(receiverId, userId);
    return result.fold(
      (data) => (data['chatId'] as String, data['messages'] as List<ChatMessage>),
        (error, stackTrace) => throw error,
    );
  }
}

// final chatServiceProvider = Provider((ref) {
//   final dio = ref.watch(dioProvider);
//   final chatService = ChatService(dio, ref);
//   return chatService;
// });

final activeRoomProvider = StateProvider<String?>((ref) => null);
final activeChatIdProvider = StateProvider<List<String>?>((ref) => null);
final unreadCountProvider = StateProvider<Map<String, int>>((ref) => {});

extension UnreadCountExtension on WidgetRef {
  void incrementUnread(String senderId) {
    final current = read(unreadCountProvider);
    read(unreadCountProvider.notifier).state = {
      ...current,
      senderId: (current[senderId] ?? 0) + 1,
    };
  }

  void clearUnread(String senderId) {
    final current = read(unreadCountProvider);
    final next = Map<String, int>.from(current);
    next.remove(senderId);
    read(unreadCountProvider.notifier).state = next;
  }
}
