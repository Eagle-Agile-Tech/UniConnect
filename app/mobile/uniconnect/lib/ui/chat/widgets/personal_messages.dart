import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../config/assets.dart';
import '../../../data/service/socket/chat_service.dart';

class Messages extends ConsumerStatefulWidget {
  const Messages({super.key});

  @override
  ConsumerState<Messages> createState() => _MessagesState();
}

class _MessagesState extends ConsumerState<Messages>
    with WidgetsBindingObserver {
  final Map<String, int> _newMessageCount = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureChatConnection();
    });
    ChatPlugin.chatService.addEventListener(
      ChatEventType.custom,
      'direct_message_page_notification',
      (data) {
        if (data['eventName'] == 'new_message_notification') {
          _handleNewMessageNotification(data['data']);
        }
      },
    );
  }

  _handleNewMessageNotification(Map<String, dynamic> messageData) {
    final senderId = messageData['sender'];
    if (senderId != null) {
      _newMessageCount[senderId] = (_newMessageCount[senderId] ?? 0) + 1;
    }
  }

  void _navigateToChat(String userId, String username) {
    setState(() {
      _newMessageCount.remove(userId);
    });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching messages')));
      }
    } else {
      await chatServiceProviderInstance.initializeChatPlugin();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureChatConnection();
    } else if (state == AppLifecycleState.paused) {
      try {
        final chatService = ChatPlugin.chatService;
        chatService.updateUserStatus(false);
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatRooms = ChatPlugin.chatService.chatRooms;
    if (chatRooms.isEmpty) {
      return Expanded(
        child: Center(
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
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ChatPlugin.chatService.loadChatRooms(),
      child: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) => ListTile(
          onTap: () {
            _navigateToChat(chatRooms[index].userId, chatRooms[index].username);
            context.push(Routes.messaging,extra: {'userId':chatRooms[index].userId, 'username':chatRooms[index].username});
          },
          contentPadding: EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.sm,
          ),
          leading: CircleAvatar(
            radius: Dimens.avatarXs,
            backgroundImage: chatRooms[index].avatarUrl != null
                ? NetworkImage(chatRooms[index].avatarUrl!)
                : AssetImage(Assets.defaultAvatar),
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: Dimens.xs),
            child: Text(
              chatRooms[index].username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Dimens.fontMd,
                color: Colors.black87,
              ),
            ),
          ),
          subtitle: Text(
            chatRooms[index].latestMessage,
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
                  chatRooms[index].latestMessageTime.toLocal(),
                ),
                style: TextStyle(fontSize: Dimens.fontSm, color: Colors.grey),
              ),
              SizedBox(height: Dimens.xs),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  (_newMessageCount[chatRooms[index].userId] ?? 0) >
                          chatRooms[index].unreadCount
                      ? (_newMessageCount[chatRooms[index].userId] ?? 0)
                            .toString()
                      : (chatRooms[index].unreadCount).toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Dimens.fontXs,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
