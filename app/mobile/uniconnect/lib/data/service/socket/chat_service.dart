import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/local/secure_token_storage.dart';
import '../../../../ui/chat/viewmodels/chat_provider.dart';
import '../../../domain/models/chat/chat_message/chat_message.dart';
import '../../../domain/models/chat/chat_room/chat_room.dart';
import '../../../domain/models/chat/typing_status/typing_status.dart';
import '../../../domain/models/chat/user_status/user_status.dart';
import '../../../ui/auth/auth_state_provider.dart';
import '../api/routes/api_routes.dart';
import 'socket_service.dart';

class ChatService {
  final Dio _client;
  final Ref _ref;
  final SocketService _socketService = SocketService();
  final _storage = SecureTokenStorage();

  List<ChatMessage> _messages = [];
  List<ChatRoom> _chatRooms = [];
  Map<String, TypingStatus> _typingStatuses = {};
  Map<String, UserStatus> _userStatuses = {};

  final Map<String, List<Function>> _eventHandlers = {};

  String? _currentChatId;
  String? _currentReceiverId;
  bool _isInitialized = false;
  bool _isLoadingMessages = false;
  bool _hasMoreMessages = true;
  int _currentPage = 1;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatRoom> get chatRooms => List.unmodifiable(_chatRooms);
  bool get hasMoreMessages => _hasMoreMessages;
  int get currentPage => _currentPage;

  bool isReceiverTyping(String chatId) {
    return _typingStatuses[chatId]?.isTyping ?? false;
  }

  bool isReceiverOnline(String userId) {
    return _userStatuses[userId]?.isOnline ?? false;
  }

  DateTime? getLastSeen(String userId) {
    return _userStatuses[userId]?.lastSeen;
  }

  ChatService(this._client, this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final userId = _ref.read(authNotifierProvider).value!.user!.id;
      final token = await _storage.read();
      if(token == null){
        throw Exception('No token found');
      }
      _socketService.initialize(userId, token.accessToken);
      _setupSocketListeners();
      _isInitialized = true;

      await loadChatRooms();
    } catch (e) {
      debugPrint("Chat initialization error: $e");
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _socketService.addEventListener('message:received', (data) {
      _handleNewMessage(data);
    });

    _socketService.addEventListener('message:sent', (data) {
      _handleMessageSent(data);
    });

    _socketService.addEventListener('typing:start', (data) {
      _handleTypingStart(data);
    });

    _socketService.addEventListener('typing:stop', (data) {
      _handleTypingStop(data);
    });

    _socketService.addEventListener('user:online', (data) {
      _handleUserOnline(data);
    });

    _socketService.addEventListener('user:offline', (data) {
      _handleUserOffline(data);
    });

    _socketService.addEventListener('message:read', (data) {
      _handleMessageRead(data);
    });

    _socketService.addEventListener('message:delivered', (data) {
      _handleMessageDelivered(data);
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final userId = _ref.read(authNotifierProvider).value!.user!.id;
    final message = ChatMessage.fromMap(data, userId);

    if (_currentChatId == message.chatId) {
      _messages.add(message);
      _notifyListeners('messagesChanged', null);

      if (!message.isMine) {
        _socketService.markMessageAsRead(message.messageId, message.chatId);
      }
    }

    _updateChatRoomWithNewMessage(message);
    _notifyListeners('newMessage', message);
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    final userId = _ref.read(authNotifierProvider).value!.user!.id;
    final message = ChatMessage.fromMap(data, userId);

    final index = _messages.indexWhere((m) => m.messageId == message.messageId);
    if (index != -1) {
      _messages[index] = message;
      _notifyListeners('messagesChanged', null);
    }
  }

  void _handleTypingStart(Map<String, dynamic> data) {
    if (data['senderId'] == _currentReceiverId) {
      _typingStatuses[data['chatId']] = TypingStatus(
        chatId: data['chatId'],
        userId: data['senderId'],
        isTyping: true,
        timestamp: DateTime.now(),
      );
      _notifyListeners('typingStatusChanged', true);
    }
  }

  void _handleTypingStop(Map<String, dynamic> data) {
    if (data['senderId'] == _currentReceiverId) {
      _typingStatuses[data['chatId']] = TypingStatus(
        chatId: data['chatId'],
        userId: data['senderId'],
        isTyping: false,
        timestamp: DateTime.now(),
      );
      _notifyListeners('typingStatusChanged', false);
    }
  }

  void _handleUserOnline(Map<String, dynamic> data) {
    _userStatuses[data['userId']] = UserStatus(
      userId: data['userId'],
      isOnline: true,
      lastSeen: null,
    );
    if (data['userId'] == _currentReceiverId) {
      _notifyListeners('onlineStatusChanged', true);
    }
  }

  void _handleUserOffline(Map<String, dynamic> data) {
    _userStatuses[data['userId']] = UserStatus(
      userId: data['userId'],
      isOnline: false,
      lastSeen: DateTime.parse(data['lastSeen']),
    );
    if (data['userId'] == _currentReceiverId) {
      _notifyListeners('onlineStatusChanged', false);
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    final messageIndex = _messages.indexWhere((m) => m.messageId == data['messageId']);
    if (messageIndex != -1 && _messages[messageIndex].status != 'read') {
      _messages[messageIndex] = ChatMessage(
        messageId: _messages[messageIndex].messageId,
        chatId: _messages[messageIndex].chatId,
        senderId: _messages[messageIndex].senderId,
        receiverId: _messages[messageIndex].receiverId,
        content: _messages[messageIndex].content,
        createdAt: _messages[messageIndex].createdAt,
        status: 'read',
        isMine: _messages[messageIndex].isMine,
      );
      _notifyListeners('messageStatusChanged', null);
    }
  }

  void _handleMessageDelivered(Map<String, dynamic> data) {
    final messageIndex = _messages.indexWhere((m) => m.messageId == data['messageId']);
    if (messageIndex != -1 && _messages[messageIndex].status == 'sent') {
      _messages[messageIndex] = ChatMessage(
        messageId: _messages[messageIndex].messageId,
        chatId: _messages[messageIndex].chatId,
        senderId: _messages[messageIndex].senderId,
        receiverId: _messages[messageIndex].receiverId,
        content: _messages[messageIndex].content,
        createdAt: _messages[messageIndex].createdAt,
        status: 'delivered',
        isMine: _messages[messageIndex].isMine,
      );
      _notifyListeners('messageStatusChanged', null);
    }
  }

  void _updateChatRoomWithNewMessage(ChatMessage message) {
    final roomIndex = _chatRooms.indexWhere((r) => r.chatId == message.chatId);
    if (roomIndex != -1) {
      final updatedRoom = ChatRoom(
        chatId: _chatRooms[roomIndex].chatId,
        userId: _chatRooms[roomIndex].userId,
        username: _chatRooms[roomIndex].username,
        avatarUrl: _chatRooms[roomIndex].avatarUrl,
        latestMessage: message.content,
        latestMessageTime: message.createdAt,
        unreadCount: message.isMine ? _chatRooms[roomIndex].unreadCount : _chatRooms[roomIndex].unreadCount + 1,
      );
      _chatRooms[roomIndex] = updatedRoom;
      _chatRooms.sort((a, b) => b.latestMessageTime.compareTo(a.latestMessageTime));
      _notifyListeners('chatRoomsChanged', null);
    }
  }

  Future<void> loadChatRooms() async {
    try {
      final userId = _ref.read(authNotifierProvider).value!.user!.id;
      final response = await _client.get("$baseUrl/chats/");

      if (response.statusCode == 200) {
        final roomsList = response.data['chats'] as List;
        final List<ChatRoom> loadedRooms = [];

        for (var room in roomsList) {
          final participants = room['participants'] as List;
          final otherParticipant = participants.firstWhere(
                (p) => p['userId'] != userId,
            orElse: () => participants.first,
          );

          loadedRooms.add(ChatRoom(
            chatId: room['id'],
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
          ));
        }

        _chatRooms = loadedRooms;
        _notifyListeners('chatRoomsChanged', null);
      }
    } catch (e) {
      debugPrint("Load chat rooms error: $e");
      rethrow;
    }
  }

  Future<void> initChat(String receiverId) async {
    _currentReceiverId = receiverId;

    try {
      final userId = _ref.read(authNotifierProvider).value!.user!.id;

      final response = await _client.post(
        "$baseUrl/chats/",
        data: {
          'participantIds': [userId, receiverId],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentChatId = response.data['id'];
        _socketService.joinChatRoom(_currentChatId!);
        _currentPage = 1;
        _hasMoreMessages = true;
        await loadMessages();
      }
    } catch (e) {
      debugPrint("Init chat error: $e");
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadMessages({int page = 1, int limit = 20}) async {
    if (_currentChatId == null || _isLoadingMessages) return [];

    _isLoadingMessages = true;

    try {
      final offset = (page - 1) * limit;
      final response = await _client.get(
        "$baseUrl/chats/messages",
        queryParameters: {
          'chatId': _currentChatId,
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final userId = _ref.read(authNotifierProvider).value!.user!.id;
        final List messagesList = response.data['messages'];
        final List<ChatMessage> loadedMessages = messagesList
            .map((msg) => ChatMessage.fromMap(msg, userId))
            .toList();

        if (page == 1) {
          _messages = loadedMessages.reversed.toList();
        } else {
          _messages.insertAll(0, loadedMessages.reversed.toList());
        }

        _hasMoreMessages = loadedMessages.length == limit;
        _currentPage = page;
        _notifyListeners('messagesChanged', null);

        return loadedMessages;
      }
      return [];
    } catch (e) {
      debugPrint("Load messages error: $e");
      return [];
    } finally {
      _isLoadingMessages = false;
    }
  }

  Future<void> sendMessage(String content) async {
    if (_currentChatId == null || _currentReceiverId == null) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = _ref.read(authNotifierProvider).value!.user!.id;

    final tempMessage = ChatMessage(
      messageId: messageId,
      chatId: _currentChatId!,
      senderId: userId,
      receiverId: _currentReceiverId!,
      content: content,
      createdAt: DateTime.now(),
      status: 'sent',
      isMine: true,
    );

    _messages.add(tempMessage);
    _notifyListeners('messagesChanged', null);

    try {
      final response = await _client.post(
        "$baseUrl/chats/messages",
        data: {
          'chatId': _currentChatId,
          'content': content,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _socketService.sendMessage(
          chatId: _currentChatId!,
          content: content,
          receiverId: _currentReceiverId!,
          messageId: messageId,
        );
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      debugPrint("Send message error: $e");
      final errorIndex = _messages.indexWhere((m) => m.messageId == messageId);
      if (errorIndex != -1) {
        _messages.removeAt(errorIndex);
        _notifyListeners('messagesChanged', null);
      }
      rethrow;
    }
  }

  void markMessageAsRead(String messageId, String chatId){
    _socketService.markMessageAsRead(messageId, chatId);
  }

  void sendTypingIndicator(bool isTyping) {
    if (_currentChatId != null && _currentReceiverId != null) {
      _socketService.sendTypingIndicator(_currentChatId!, _currentReceiverId!, isTyping);
    }
  }

  void updateUserStatus(bool isOnline) {
    _socketService.updateUserStatus(isOnline);
  }

  void addEventListener(String event, Function callback) {
    if (!_eventHandlers.containsKey(event)) {
      _eventHandlers[event] = [];
    }
    _eventHandlers[event]!.add(callback);
  }

  void removeEventListener(String event, Function callback) {
    if (_eventHandlers.containsKey(event)) {
      _eventHandlers[event]!.remove(callback);
    }
  }

  void _notifyListeners(String event, dynamic data) {
    if (_eventHandlers.containsKey(event)) {
      for (var callback in _eventHandlers[event]!) {
        callback(data);
      }
    }
  }

  void dispose() {
    if (_currentChatId != null) {
      _socketService.leaveChatRoom(_currentChatId!);
    }
    _socketService.disconnect();
    _eventHandlers.clear();
  }
}