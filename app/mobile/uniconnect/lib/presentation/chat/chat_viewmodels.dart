import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniconnect/data/chat_api.dart';
import 'package:uniconnect/data/chat_realtime_service.dart';
import 'package:uniconnect/data/repository/chat/chat_repository_remote.dart';
import 'package:uniconnect/domain/models/chat/chat_conversation_model.dart';
import 'package:uniconnect/domain/models/chat/chat_message_model.dart';

import 'chat_session.dart';

class ChatConversationService extends ChangeNotifier {
  ChatConversationService._();

  static final ChatConversationService instance = ChatConversationService._();

  ChatRealtimeService _realtime = ChatRealtimeService();
  ChatRepositoryRemote? _chatRepository;
  String? _currentUserId;

  final Map<String, bool> _onlineByUserId = {};
  final Map<String, DateTime?> _lastSeenByUserId = {};
  final Map<String, bool> _typingByChatId = {};

  final List<ChatConversationModel> _conversations = [];

  StreamSubscription<ChatMessageModel>? _incomingSub;
  StreamSubscription<ChatPresenceEvent>? _presenceSub;
  StreamSubscription<ChatTypingEvent>? _typingSub;
  StreamSubscription<ChatPresenceStateEvent>? _presenceStateSub;
  StreamSubscription<ChatTypingStateEvent>? _typingStateSub;
  StreamSubscription<Map<String, dynamic>>? _socketErrorSub;

  bool _initialized = false;
  bool _isLoading = true;
  String? _error;
  Future<void>? _initializing;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ChatConversationModel> get conversations => List.unmodifiable(_conversations);

  bool isPartnerOnline(String userId) => _onlineByUserId[userId] ?? false;
  bool isTyping(String chatId) => _typingByChatId[chatId] ?? false;
  DateTime? partnerLastSeen(String userId) => _lastSeenByUserId[userId];

  Future<void> initialize() async {
    final inFlight = _initializing;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _initializeInternal();
    _initializing = future;
    try {
      await future;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeInternal() async {
    if (_initialized && _chatRepository != null) {
      return;
    }

    await _bindRepository();
    if (_chatRepository == null || _currentUserId == null) {
      _error = 'Chat session is not ready';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _connectRealtime();
      final conversations = await _loadConversations();
      _replaceConversations(conversations);
      _initialized = true;
      _isLoading = false;
      notifyListeners();
      _queryPresenceAndTyping(conversations);
    } catch (error, stackTrace) {
      debugPrint('Chat conversation init error: $error\n$stackTrace');
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final inFlight = _initializing;
    if (inFlight != null) {
      await inFlight;
    }

    if (_chatRepository == null) {
      await initialize();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversations = await _loadConversations();
      _replaceConversations(conversations);
      _queryPresenceAndTyping(conversations);
      _isLoading = false;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Chat conversation refresh error: $error\n$stackTrace');
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markConversationRead(String chatId) async {
    final index = _conversations.indexWhere((conversation) => conversation.chatId == chatId);
    if (index == -1) {
      return;
    }

    _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void applyMessageUpdate({
    required ChatMessageModel message,
    required String currentUserId,
    String? fallbackPartnerId,
    String? fallbackPartnerName,
    String? fallbackPartnerAvatarUrl,
    bool markAsRead = false,
  }) {
    final index = _conversations.indexWhere((item) => item.chatId == message.chatId);
    if (index == -1) {
      final partnerId = message.senderId == currentUserId
          ? (fallbackPartnerId ?? '')
          : message.senderId;
      final partnerName = message.senderId == currentUserId
          ? (fallbackPartnerName ?? 'Unknown user')
          : (message.senderName ?? fallbackPartnerName ?? 'Unknown user');
      if (partnerId.isEmpty || message.chatId.isEmpty) {
        unawaited(refresh());
        return;
      }

      final createdConversation = ChatConversationModel(
        chatId: message.chatId,
        partnerId: partnerId,
        partnerName: partnerName,
        partnerAvatarUrl: fallbackPartnerAvatarUrl,
        lastMessage: message.content,
        lastMessageAt: message.createdAt,
        unreadCount: markAsRead || message.senderId == currentUserId ? 0 : 1,
      );
      _conversations.insert(0, createdConversation);
      _sortConversations();
      notifyListeners();
      return;
    }

    final previous = _conversations[index];
    final unreadCount = markAsRead
        ? 0
        : (message.senderId == currentUserId
              ? previous.unreadCount
              : previous.unreadCount + 1);

    _conversations[index] = previous.copyWith(
      lastMessage: message.content,
      lastMessageAt: message.createdAt,
      unreadCount: unreadCount,
    );
    _sortConversations();
    notifyListeners();
  }

  Future<void> shutdown() async {
    await _incomingSub?.cancel();
    await _presenceSub?.cancel();
    await _typingSub?.cancel();
    await _presenceStateSub?.cancel();
    await _typingStateSub?.cancel();
    await _socketErrorSub?.cancel();
    _incomingSub = null;
    _presenceSub = null;
    _typingSub = null;
    _presenceStateSub = null;
    _typingStateSub = null;
    _socketErrorSub = null;
    _conversations.clear();
    _onlineByUserId.clear();
    _lastSeenByUserId.clear();
    _typingByChatId.clear();
    _chatRepository = null;
    _currentUserId = null;
    _initialized = false;
    _isLoading = true;
    _error = null;
    _realtime.dispose();
    _realtime = ChatRealtimeService();
    notifyListeners();
  }

  Future<void> _bindRepository() async {
    final userId = ChatSession.instance.currentUserId;
    if (userId == null || userId.isEmpty) {
      _currentUserId = null;
      _chatRepository = null;
      return;
    }

    _currentUserId = userId;
    _chatRepository = ChatSession.instance.createChatRepository();
  }

  Future<List<ChatConversationModel>> _loadConversations() async {
    final repository = _chatRepository;
    if (repository == null) {
      throw StateError('Chat repository is not ready');
    }

    final result = await repository.listConversations();
    return result.fold(
      (data) => data,
      (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }

  Future<void> _connectRealtime() async {
    final token = ChatSession.instance.accessToken;
    final currentUserId = _currentUserId;
    if (token == null || token.isEmpty || currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    await _realtime.connect(token: token, currentUserId: currentUserId);

    _incomingSub ??= _realtime.incomingMessages.listen(_handleIncomingMessage);
    _presenceSub ??= _realtime.presenceUpdates.listen(_handlePresenceUpdate);
    _typingSub ??= _realtime.typingUpdates.listen(_handleTypingUpdate);
    _presenceStateSub ??= _realtime.presenceState.listen(_handlePresenceState);
    _typingStateSub ??= _realtime.typingState.listen(_handleTypingState);
    _socketErrorSub ??= _realtime.errors.listen((payload) {
      debugPrint('[realtime] chat error: $payload');
    });
  }

  void _queryPresenceAndTyping(List<ChatConversationModel> conversations) {
    for (final conversation in conversations) {
      _realtime.queryPresence(chatId: conversation.chatId);
      _realtime.queryTyping(chatId: conversation.chatId);
    }
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }

    if (_isLoading && _conversations.isEmpty) {
      unawaited(refresh());
      return;
    }

    applyMessageUpdate(message: message, currentUserId: currentUserId);
  }

  void _handlePresenceUpdate(ChatPresenceEvent event) {
    if (event.userId == _currentUserId) {
      return;
    }
    _onlineByUserId[event.userId] = event.status == 'ONLINE';
    _lastSeenByUserId[event.userId] = event.lastSeenAt;
    notifyListeners();
  }

  void _handleTypingUpdate(ChatTypingEvent event) {
    if (event.userId == _currentUserId) {
      return;
    }
    _typingByChatId[event.chatId] = event.isTyping;
    notifyListeners();
  }

  void _handlePresenceState(ChatPresenceStateEvent event) {
    for (final userState in event.users) {
      if (userState.userId == _currentUserId) {
        continue;
      }
      _onlineByUserId[userState.userId] = userState.status == 'ONLINE';
      _lastSeenByUserId[userState.userId] = userState.lastSeenAt;
    }
    notifyListeners();
  }

  void _handleTypingState(ChatTypingStateEvent event) {
    final isTyping = event.users.any((userId) => userId != _currentUserId);
    _typingByChatId[event.chatId] = isTyping;
    notifyListeners();
  }

  void _replaceConversations(List<ChatConversationModel> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
    _sortConversations();
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final left = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  }
}


