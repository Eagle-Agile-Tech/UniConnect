import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../config/assets.dart';
import '../../../data/service/socket/chat_service.dart';
import '../viewmodels/chat_provider.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key});

  @override
  ConsumerState<DirectChatScreen> createState() => _MessagesState();
}

class _MessagesState extends ConsumerState<DirectChatScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeRoomProvider.notifier).state = null;
      _ensureChatConnection();
    });

    ChatPlugin.chatService.addEventListener(
      ChatEventType.custom,
      'direct_message_page_notification',
      (data) {
        if (data['eventName'] == 'new_message_notification') {
          final senderId = data['data']['sender'];
          final activeId = ref.read(activeRoomProvider.notifier).state;

          if (senderId != null && senderId != activeId) {
            ref
                .read(unreadCountProvider.notifier)
                .update(
                  (state) => {...state, senderId: (state[senderId] ?? 0) + 1},
                );
          }
        }
      },
    );
  }

  void _ensureChatConnection() async {
    final chatServiceProviderInstance = ref.read(chatServiceProvider);
    if (ChatConfig.instance.userId != null) {
      try {
        final chatService = ChatPlugin.chatService;
        if (!chatService.isSocketConnected) {
          await chatService.initGlobalConnection();
        } else {
          chatService.refreshGlobalConnection();
        }
        chatService.updateUserStatus(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to chat')),
        );
      }
    } else {
      await chatServiceProviderInstance.initializeChatPlugin();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _ensureChatConnection();
    } else if (state == AppLifecycleState.paused) {
      try {
        ChatPlugin.chatService.updateUserStatus(false);
      } catch (e) {
        debugPrint("Error updating status: $e");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRooms = ChatPlugin.chatService.chatRooms;
    final unreadCounts = ref.watch(unreadCountProvider);

    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: Dimens.iconLg,
              color: Colors.grey,
            ),
            const SizedBox(height: Dimens.md),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: Dimens.fontMd,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ChatPlugin.chatService.loadChatRooms(),
      child: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          final count = unreadCounts[room.userId] ?? 0;

          return ListTile(
            onTap: () {
              ref.read(unreadCountProvider.notifier).update((state) {
                final newState = Map<String, int>.from(state);
                newState.remove(room.userId);
                return newState;
              });


              context.push(
                Routes.messaging,
                extra: {'receiverId': room.userId, 'username': room.username, 'chatId': ref.read(chatIdProvider.notifier).state![index]},
              );
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimens.md,
              vertical: Dimens.sm,
            ),
            leading: CircleAvatar(
              radius: Dimens.avatarXs,
              backgroundImage: room.avatarUrl != null
                  ? NetworkImage(room.avatarUrl!)
                  : const AssetImage(Assets.defaultAvatar) as ImageProvider,
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: Dimens.xs),
              child: Text(
                room.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Dimens.fontMd,
                  color: Colors.black87,
                ),
              ),
            ),
            subtitle: Text(
              room.latestMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MessageFormatter.formatTimestamp(
                    room.latestMessageTime.toLocal(),
                  ),
                  style: const TextStyle(
                    fontSize: Dimens.fontSm,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: Dimens.xs),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: Dimens.fontXs,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
