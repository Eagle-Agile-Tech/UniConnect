import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/data/chat_api.dart';
import 'package:uniconnect/data/chat_realtime_service.dart';
import 'package:uniconnect/data/repository/chat/chat_repository.dart';
import 'package:uniconnect/data/repository/chat/chat_repository_remote.dart';
import 'package:uniconnect/domain/models/chat/chat_message_model.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../data/service/local/secure_token_storage.dart';
import 'chat_session.dart';
import 'chat_thread_state.dart';
import 'chat_viewmodels.dart';

class ChatThreadView extends StatefulWidget {
  const ChatThreadView({super.key, required this.args});

  final ChatThreadArgs args;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRealtimeService _realtime = ChatRealtimeService();
  final List<ChatMessageModel> _pendingMessages = [];

  late final ChatRepository _chatRepository;
  late final ChatApi _chatApi;

  StreamSubscription<ChatMessageModel>? _incomingSub;
  StreamSubscription<ChatPresenceEvent>? _presenceSub;
  StreamSubscription<ChatTypingEvent>? _typingSub;
  StreamSubscription<ChatReadEvent>? _readSub;
  StreamSubscription<ChatDeliveredEvent>? _deliveredSub;
  StreamSubscription<ChatPresenceStateEvent>? _presenceStateSub;
  StreamSubscription<ChatTypingStateEvent>? _typingStateSub;
  StreamSubscription<Map<String, dynamic>>? _socketErrorSub;
  Timer? _typingDebounceTimer;

  ChatThreadState? _thread;
  String? _currentUserId;
  String? _activeChatId;
  bool _isLoading = true;
  bool _typingEmitted = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _currentUserId = ChatSession.instance.currentUserId;
    if (!ChatSession.instance.isAuthenticated) {
      _isLoading = false;
      _loadError = 'Not authenticated';
      return;
    }
    _chatRepository = ChatSession.instance.createChatRepository();
    _chatApi = ChatSession.instance.createChatApi();

    if (widget.args.chatId != null && widget.args.chatId!.isNotEmpty) {
      _activeChatId = widget.args.chatId;
      unawaited(_connectRealtime(widget.args.chatId!));
    }

    unawaited(_loadInitialThread());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingDebounceTimer?.cancel();
    final chatId = _activeChatId;
    if (_typingEmitted && chatId != null && chatId.isNotEmpty) {
      _realtime.sendTyping(chatId: chatId, isTyping: false);
    }
    if (chatId != null && chatId.isNotEmpty) {
      _realtime.leaveChat(chatId);
    }
    _incomingSub?.cancel();
    _presenceSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _deliveredSub?.cancel();
    _presenceStateSub?.cancel();
    _typingStateSub?.cancel();
    _socketErrorSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    if (thread != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Dimens.sm,
        title: Row(
          children: [
            CircleAvatar(
              radius: Dimens.avatarSm / 2,
              backgroundImage: widget.args.receiverAvatar != null
                  ? NetworkImage(widget.args.receiverAvatar!)
                  : null,
              child: widget.args.receiverAvatar == null
                  ? Text(
                      widget.args.receiverName.isNotEmpty
                          ? widget.args.receiverName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: Dimens.sm),
            Expanded(
              child: thread == null
                  ? Text(
                      widget.args.receiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.args.receiverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _headerPresenceText(thread),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: thread.isPartnerTyping
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.lg),
          child: Text(
            'Unable to load chat\n$_loadError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final thread = _thread;
    if (thread == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(Dimens.md),
            itemCount: thread.messages.length,
            itemBuilder: (context, index) {
              final message = thread.messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
        if (thread.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(
              left: Dimens.md,
              right: Dimens.md,
              bottom: Dimens.xs,
            ),
            child: Text(
              thread.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: Dimens.fontSm,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.md,
              Dimens.xs,
              Dimens.md,
              Dimens.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    onChanged: _onComposerChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.radiusLg),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Dimens.md,
                        vertical: Dimens.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimens.sm),
                IconButton.filled(
                  onPressed: thread.isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadInitialThread() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Not authenticated';
      });
      return;
    }

    final result = await _chatRepository.getConversationMessagesByUser(
      otherUserId: widget.args.receiverId,
      currentUserId: currentUserId,
    );

    ChatThreadState? loadedThread;
    Object? loadError;
    result.fold(
      (data) {
        final mergedMessages = _mergeMessages(data.$2, _pendingMessages);
        _pendingMessages.clear();
        loadedThread = ChatThreadState(
          args: widget.args,
          chatId: data.$1,
          messages: mergedMessages,
        );
      },
      (error, stackTrace) {
        loadError = error;
      },
    );

    if (!mounted) {
      return;
    }

    if (loadError != null) {
      setState(() {
        _isLoading = false;
        _loadError = loadError.toString();
      });
      return;
    }

    final thread = loadedThread!;
    setState(() {
      _thread = thread;
      _activeChatId = thread.chatId;
      _isLoading = false;
      _loadError = null;
    });

    await _connectRealtime(thread.chatId);
    await _markChatAsRead(thread.chatId);
    unawaited(ChatConversationService.instance.markConversationRead(thread.chatId));
  }

  Future<void> _connectRealtime(String chatId) async {
    if (chatId.isEmpty) {
      return;
    }

    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    final token = await SecureTokenStorage().read();
    final accessToken = token?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    await _realtime.connect(token: accessToken, currentUserId: currentUserId);

    _incomingSub ??= _realtime.incomingMessages.listen(_handleIncomingMessage);
    _presenceSub ??= _realtime.presenceUpdates.listen(_handlePresenceUpdate);
    _typingSub ??= _realtime.typingUpdates.listen(_handleTypingUpdate);
    _readSub ??= _realtime.readUpdates.listen(_handleReadUpdate);
    _deliveredSub ??= _realtime.deliveredUpdates.listen(_handleDeliveredUpdate);
    _presenceStateSub ??= _realtime.presenceState.listen(_handlePresenceState);
    _typingStateSub ??= _realtime.typingState.listen(_handleTypingState);
    _socketErrorSub ??= _realtime.errors.listen((payload) {
      final thread = _thread;
      final message = payload['message']?.toString() ?? 'Chat socket error';
      if (thread != null && mounted) {
        setState(() {
          _thread = thread.copyWith(errorMessage: message);
        });
      }
    });

    if (_activeChatId != null && _activeChatId != chatId) {
      _realtime.leaveChat(_activeChatId!);
    }
    _activeChatId = chatId;

    _realtime.joinChat(chatId);
    _realtime.queryPresence(chatId: chatId);
    _realtime.queryTyping(chatId: chatId);
    _realtime.markDelivered(chatId: chatId);
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final thread = _thread;
    if (thread == null) {
      if (_activeChatId != null && message.chatId == _activeChatId) {
        _addPendingMessage(message);
      }
      return;
    }

    if (message.chatId != thread.chatId || _messageExists(thread.messages, message)) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _thread = thread.copyWith(messages: [...thread.messages, message]);
    });

    final currentUserId = _currentUserId;
    if (currentUserId != null) {
      ChatConversationService.instance.applyMessageUpdate(
            message: message,
            currentUserId: currentUserId,
            fallbackPartnerId: widget.args.receiverId,
            fallbackPartnerName: widget.args.receiverName,
            fallbackPartnerAvatarUrl: widget.args.receiverAvatar,
            markAsRead: !message.isMine,
          );
    }

    if (!message.isMine) {
      _realtime.markDelivered(chatId: thread.chatId, messageId: message.id);
      _realtime.markRead(chatId: thread.chatId, messageId: message.id);
      unawaited(_markChatAsRead(thread.chatId, messageId: message.id));
      unawaited(ChatConversationService.instance.markConversationRead(thread.chatId));
    }
  }

  void _handlePresenceUpdate(ChatPresenceEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId || event.userId != widget.args.receiverId) {
      return;
    }
    setState(() {
      _thread = thread.copyWith(
        isPartnerOnline: event.status == 'ONLINE',
        isPartnerTyping: event.status == 'ONLINE' ? thread.isPartnerTyping : false,
        partnerLastSeenAt: event.lastSeenAt,
      );
    });
  }

  void _handleTypingUpdate(ChatTypingEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId || event.userId != widget.args.receiverId) {
      return;
    }
    setState(() {
      _thread = thread.copyWith(isPartnerTyping: event.isTyping);
    });
  }

  void _handleReadUpdate(ChatReadEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId || event.userId != widget.args.receiverId) {
      return;
    }

    final messageIndex = event.messageId == null
        ? thread.messages.length - 1
        : thread.messages.indexWhere((message) => message.id == event.messageId);
    if (messageIndex < 0) {
      return;
    }

    final next = [...thread.messages];
    for (var i = 0; i <= messageIndex; i++) {
      if (next[i].isMine) {
        next[i] = next[i].copyWith(
          status: 'read',
          isPending: false,
          isFailed: false,
        );
      }
    }

    setState(() {
      _thread = thread.copyWith(messages: next);
    });
  }

  void _handleDeliveredUpdate(ChatDeliveredEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId) {
      return;
    }

    final targets = event.messageIds.toSet();
    if (targets.isEmpty) {
      return;
    }

    final next = thread.messages.map((message) {
      if (!message.isMine || !targets.contains(message.id) || message.status == 'read') {
        return message;
      }
      return message.copyWith(status: 'delivered');
    }).toList();

    setState(() {
      _thread = thread.copyWith(messages: next);
    });
  }

  void _handlePresenceState(ChatPresenceStateEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId) {
      return;
    }

    final partner = event.users.firstWhere(
      (userState) => userState.userId == widget.args.receiverId,
      orElse: () => const ChatPresenceUserState(userId: '', status: 'OFFLINE'),
    );
    if (partner.userId.isEmpty) {
      return;
    }

    setState(() {
      _thread = thread.copyWith(
        isPartnerOnline: partner.status == 'ONLINE',
        partnerLastSeenAt: partner.lastSeenAt,
      );
    });
  }

  void _handleTypingState(ChatTypingStateEvent event) {
    final thread = _thread;
    if (thread == null || event.chatId != thread.chatId) {
      return;
    }

    setState(() {
      _thread = thread.copyWith(
        isPartnerTyping: event.users.contains(widget.args.receiverId),
      );
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final thread = _thread;
    final currentUserId = _currentUserId;
    if (thread == null || currentUserId == null) {
      return;
    }

    _messageController.clear();
    _onComposerChanged('');

    final clientMessageId = DateTime.now().microsecondsSinceEpoch.toString();
    final optimisticMessage = ChatMessageModel(
      id: clientMessageId,
      chatId: thread.chatId,
      senderId: currentUserId,
      senderName: null,
      content: content,
      createdAt: DateTime.now(),
      status: 'pending',
      clientMessageId: clientMessageId,
      isMine: true,
      isPending: true,
    );

    setState(() {
      _thread = thread.copyWith(
        isSending: true,
        clearError: true,
        messages: [...thread.messages, optimisticMessage],
      );
    });

    final result = await _chatRepository.sendMessage(
      chatId: thread.chatId,
      content: content,
      currentUserId: currentUserId,
      clientMessageId: clientMessageId,
    );

    ChatMessageModel? serverMessage;
    Object? sendError;
    result.fold(
      (data) => serverMessage = data,
      (error, _) => sendError = error,
    );

    if (!mounted) {
      return;
    }

    final snapshot = _thread;
    if (snapshot == null) {
      return;
    }

    if (serverMessage != null) {
      final nextMessages = snapshot.messages.map((message) {
        final sameOptimistic =
            message.clientMessageId == clientMessageId || message.id == clientMessageId;
        return sameOptimistic
            ? serverMessage!.copyWith(
                isMine: true,
                isPending: false,
                isFailed: false,
              )
            : message;
      }).toList();

      setState(() {
        _thread = snapshot.copyWith(
          isSending: false,
          clearError: true,
          messages: nextMessages,
        );
      });

      ChatConversationService.instance.applyMessageUpdate(
            message: serverMessage!.copyWith(isMine: true),
            currentUserId: currentUserId,
            fallbackPartnerId: widget.args.receiverId,
            fallbackPartnerName: widget.args.receiverName,
            fallbackPartnerAvatarUrl: widget.args.receiverAvatar,
            markAsRead: true,
          );
      return;
    }

    final nextMessages = snapshot.messages.map((message) {
      final sameOptimistic =
          message.clientMessageId == clientMessageId || message.id == clientMessageId;
      return sameOptimistic
          ? message.copyWith(
              isPending: false,
              isFailed: true,
              status: 'failed',
            )
          : message;
    }).toList();

    setState(() {
      _thread = snapshot.copyWith(
        isSending: false,
        errorMessage: sendError?.toString(),
        messages: nextMessages,
      );
    });
  }

  void _onComposerChanged(String value) {
    final thread = _thread;
    if (thread == null) {
      return;
    }

    final hasText = value.trim().isNotEmpty;
    if (hasText && !_typingEmitted) {
      _typingEmitted = true;
      _realtime.sendTyping(chatId: thread.chatId, isTyping: true);
    }

    _typingDebounceTimer?.cancel();
    if (hasText) {
      _typingDebounceTimer = Timer(const Duration(milliseconds: 1800), () {
        final latestThread = _thread;
        if (latestThread == null) {
          return;
        }
        _typingEmitted = false;
        _realtime.sendTyping(chatId: latestThread.chatId, isTyping: false);
      });
    } else if (_typingEmitted) {
      _typingEmitted = false;
      _realtime.sendTyping(chatId: thread.chatId, isTyping: false);
    }
  }

  Future<void> _markChatAsRead(String chatId, {String? messageId}) async {
    try {
      await _chatApi.markAsRead(chatId: chatId, messageId: messageId);
    } catch (_) {
      // Keep UI responsive even if read sync fails.
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _addPendingMessage(ChatMessageModel message) {
    if (_messageExists(_pendingMessages, message)) {
      return;
    }
    _pendingMessages.add(message);
  }

  bool _messageExists(List<ChatMessageModel> messages, ChatMessageModel candidate) {
    return messages.any(
      (message) =>
          message.id == candidate.id ||
          (message.clientMessageId != null &&
              message.clientMessageId == candidate.clientMessageId),
    );
  }

  List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> base,
    Iterable<ChatMessageModel> extra,
  ) {
    final merged = [...base];
    for (final message in extra) {
      if (!_messageExists(merged, message)) {
        merged.add(message);
      }
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  String _headerPresenceText(ChatThreadState thread) {
    if (thread.isPartnerTyping) {
      return 'typing...';
    }
    if (thread.isPartnerOnline) {
      return 'online';
    }
    if (thread.partnerLastSeenAt != null) {
      return 'last seen at ${DateFormat('HH:mm').format(thread.partnerLastSeenAt!.toLocal())}';
    }
    return 'off for a bit';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final align = message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = message.isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: Dimens.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(Dimens.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(message.content, style: TextStyle(color: textColor)),
              const SizedBox(height: 2),
              Text(
                _metaText(message),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: Dimens.fontXs,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _metaText(ChatMessageModel message) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    if (message.isFailed) {
      return '$time - failed';
    }
    if (message.isPending) {
      return '$time - sending';
    }
    if (message.isMine) {
      final status = message.status.toLowerCase();
      if (status == 'read') {
        return '$time - read';
      }
      if (status == 'delivered') {
        return '$time - delivered';
      }
      return '$time - sent';
    }
    return time;
  }
}
