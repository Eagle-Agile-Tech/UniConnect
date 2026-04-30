import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/data/service/api/token_refresher.dart';
import 'package:uniconnect/data/service/local/secure_token_storage.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import 'chat_session.dart';
import 'chat_viewmodels.dart';

class ConversationsView extends ConsumerStatefulWidget {
  const ConversationsView({super.key});

  @override
  ConsumerState<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends ConsumerState<ConversationsView> {
  final ChatConversationService _service = ChatConversationService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeChat());
    ref.listenManual(authNotifierProvider, (_, next) {
      final userId = next.value?.user?.id;
      if (userId != null && userId.isNotEmpty) {
        unawaited(_initializeChat());
      }
    });
  }

  Future<void> _initializeChat() async {
    await _bindChatSessionFromAuth();
    if (!mounted) {
      return;
    }
    if (ChatSession.instance.isAuthenticated) {
      await _service.initialize();
    }
  }

  Future<void> _bindChatSessionFromAuth() async {
    final userId = ref.read(authNotifierProvider).value?.user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final token = await SecureTokenStorage().read();
    ChatSession.instance.bind(
      userId: userId,
      token: token?.accessToken,
      dio: ref.read(dioProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _service.refresh,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_service.isLoading && _service.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_service.error != null && _service.conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.lg),
              child: Text(
                'Failed to load conversations\n${_service.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    final conversations = _service.conversations;
    if (conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: Text('No conversations yet')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: conversations.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final lastAt = conversation.lastMessageAt;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.xs,
          ),
          onTap: () {
            context.push(
              Routes.messaging,
              extra: {
                'receiverId': conversation.partnerId,
                'username': conversation.partnerName,
                'profileImage': conversation.partnerAvatarUrl,
                'chatId': conversation.chatId,
              },
            );
          },
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: Dimens.avatarSm,
                backgroundImage: conversation.partnerAvatarUrl != null
                    ? NetworkImage(conversation.partnerAvatarUrl!)
                    : null,
                child: conversation.partnerAvatarUrl == null
                    ? Text(
                        conversation.partnerName.isNotEmpty
                            ? conversation.partnerName[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              if (_service.isPartnerOnline(conversation.partnerId))
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conversation.partnerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _service.isTyping(conversation.chatId)
                ? 'typing...'
                : conversation.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _service.isTyping(conversation.chatId)
                ? TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  )
                : null,
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastAt != null)
                Text(
                  UCHelperFunctions.formatMessageDate(lastAt.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(height: Dimens.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(Dimens.radiusLg),
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: Dimens.fontXs,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
