import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  final String receiverId;
  final String receiverName;

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textMessage = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatPlugin.chatService;
  final String listenerId = 'chat_screen_page';
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerEventListener();
    _chatInit();
    _textMessage.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _textMessage.dispose();
    _chatService.removeEventListener(ChatEventType.messagesChanged, '$listenerId-messages');
    _chatService.removeEventListener(ChatEventType.typingStatusChanged, '$listenerId-typing');
    _chatService.removeEventListener(ChatEventType.onlineStatusChanged, '$listenerId-online');
    _chatService.removeEventListener(ChatEventType.messageStatusChanged, '$listenerId-status');
    _chatService.removeEventListener(ChatEventType.error,'$listenerId-error');
    super.dispose();
  }

  Future<void> _chatInit() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _chatService.initChat(widget.receiverId);
      await _chatService.loadMessages();
      _chatService.updateUserStatus(true);
      _chatService.emitCustomEvent('get_user_status', {
        'userId': widget.receiverId,
      });
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTextChanged() {
    bool isCurrentlyTyping = _textMessage.text.isNotEmpty;
    if (_isTyping != isCurrentlyTyping) {
      _isTyping = isCurrentlyTyping;
      _chatService.sendTypingIndicator(_isTyping);
    }
  }

  void _registerEventListener() {
    _chatService.addEventListener(
      ChatEventType.messagesChanged,
      '$listenerId-messages',
      (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    );

    _chatService.addEventListener(
      ChatEventType.typingStatusChanged,
      '$listenerId-typing',
      (isTyping) {
        if (mounted) {
          setState(() {
            _isTyping = isTyping;
          });
        }
      },
    );
    _chatService.addEventListener(
      ChatEventType.onlineStatusChanged,
      '$listenerId-online',
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _chatService.addEventListener(
      ChatEventType.messageStatusChanged,
      '$listenerId-status',
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );

    _chatService.addEventListener(ChatEventType.error, '$listenerId-error', (
      error,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _chatService.updateUserStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _chatService.updateUserStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chatService.messages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[200]?.withValues(alpha: 0.6),
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(Assets.defaultAvatar),
          ),
          title: Text(
            widget.receiverName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: _chatService.isReceiverTyping
              ? Text('Typing...')
              : _chatService.isReceiverOnline
              ? Text('Online')
              : Text(
                  'Last Seen at ${MessageFormatter.formatTimestamp(_chatService.lastSeen ?? DateTime.now())}',
                ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: Dimens.spaceBtwSections),
            if (_isLoadingMore)
              Container(
                height: 40,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(child: Text('Say Hi'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.minScrollExtent) {
                          _loadMoreMessages();
                        }
                        return true;
                      },
                      child: ListView.builder(
                        itemCount: messages.length,
                        controller: _scrollController,
                        padding: EdgeInsets.all(10),
                        itemBuilder: (BuildContext context, int index) {
                          final message = messages[index];
                          final isMe = message.isMine;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(10),
                                margin: EdgeInsets.only(
                                  right: isMe ? 10 : 70,
                                  left: isMe ? 70 : 10,
                                ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    message.message,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        MessageFormatter.formatTimestamp(
                                          message.createdAt.toLocal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]?.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: Dimens.sm),
                                      if (isMe)
                                        _buildMessageStatus(message.status),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.emoji_emotions_outlined),
                    color: Colors.grey[600],
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textMessage,
                      decoration: InputDecoration().copyWith(
                        hintText: 'Type a message',
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: _isTyping
                        ? Icon(Icons.send_outlined)
                        : Icon(Icons.mic),
                    color: Colors.deepPurple[600]?.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _textMessage.text.trim();
    if (text.isEmpty) return;
    _textMessage.clear();
    try {
      await _chatService.sendMessage(text);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message')));
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_chatService.messages.isEmpty || _isLoadingMore || !_hasMoreMessages) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    int currentMessageCount = _chatService.messages.length;
    int nextPage = (currentMessageCount / 20).ceil() + 1;
    try {
      final newMessages = await _chatService.loadMessages(page: nextPage);
      if (newMessages.isEmpty) {
        _hasMoreMessages = false;
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildMessageStatus(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14, color: Colors.grey),
            Transform.translate(
              offset: Offset(-4, 0),
              child: Icon(Icons.check, size: 14, color: Colors.grey),
            ),
          ],
        );
      case 'read':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14, color: Theme.of(context).primaryColor),
            Transform.translate(
              offset: Offset(-4, 0),
              child: Icon(
                Icons.check,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }
}
