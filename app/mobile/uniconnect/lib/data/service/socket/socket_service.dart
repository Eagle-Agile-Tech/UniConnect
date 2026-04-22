import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

import '../api/routes/api_routes.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final Map<String, List<Function>> _eventListeners = {};
  String? _currentUserId;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  void initialize(String userId, String token) {
    if (_socket != null && _isConnected) {
      debugPrint("Socket already initialized");
      return;
    }
    _currentUserId = userId;
    _socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'userId': userId, 'token': token})
        .enableAutoConnect()
        .build()
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      debugPrint("Socket connected");
      _isConnected = true;
      _emitEvent('user:online', {'userId': _currentUserId, 'status': true});
      _notifyListeners('connected', null);
    });

    _socket?.onDisconnect((_) {
      debugPrint("Socket disconnected");
      _isConnected = false;
      _notifyListeners('disconnected', null);
    });

    _socket?.onConnectError((error) {
      debugPrint("Socket connection error: $error");
      _isConnected = false;
      _notifyListeners('error', error);
    });

    _socket?.onError((error) {
      debugPrint("Socket error: $error");
      _notifyListeners('error', error);
    });

    _socket?.on('message:received', (data) {
      _notifyListeners('message:received', data);
    });

    _socket?.on('message:sent', (data) {
      _notifyListeners('message:sent', data);
    });

    _socket?.on('typing:start', (data) {
      _notifyListeners('typing:start', data);
    });

    _socket?.on('typing:stop', (data) {
      _notifyListeners('typing:stop', data);
    });

    _socket?.on('user:online', (data) {
      _notifyListeners('user:online', data);
    });

    _socket?.on('user:offline', (data) {
      _notifyListeners('user:offline', data);
    });

    _socket?.on('message:read', (data) {
      _notifyListeners('message:read', data);
    });

    _socket?.on('message:delivered', (data) {
      _notifyListeners('message:delivered', data);
    });
  }

  void addEventListener(String event, Function callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  void removeEventListener(String event, Function callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }

  void _notifyListeners(String event, dynamic data) {
    if (_eventListeners.containsKey(event)) {
      for (var callback in _eventListeners[event]!) {
        callback(data);
      }
    }
  }

  void _emitEvent(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket?.emit(event, data);
    }
  }

  void sendMessage({
    required String chatId,
    required String content,
    required String receiverId,
    String? messageId,
  }) {
    final messageData = {
      'messageId': messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'chatId': chatId,
      'senderId': _currentUserId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sent',
    };
    _emitEvent('message:send', messageData);
  }

  void sendTypingIndicator(String chatId, String receiverId, bool isTyping) {
    _emitEvent('typing:indicator', {
      'chatId': chatId,
      'senderId': _currentUserId,
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  void markMessageAsRead(String messageId, String chatId) {
    _emitEvent('message:markRead', {
      'messageId': messageId,
      'chatId': chatId,
      'userId': _currentUserId,
    });
  }

  void markMessageAsDelivered(String messageId, String chatId) {
    _emitEvent('message:markDelivered', {
      'messageId': messageId,
      'chatId': chatId,
      'userId': _currentUserId,
    });
  }

  void updateUserStatus(bool isOnline) {
    _emitEvent('user:status', {
      'userId': _currentUserId,
      'status': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  void joinChatRoom(String chatId) {
    _emitEvent('chat:join', {'chatId': chatId, 'userId': _currentUserId});
  }

  void leaveChatRoom(String chatId) {
    _emitEvent('chat:leave', {'chatId': chatId, 'userId': _currentUserId});
  }

  void disconnect() {
    if (_socket != null) {
      updateUserStatus(false);
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
    _isConnected = false;
    _eventListeners.clear();
  }

  void reconnect() {
    if (_socket != null && !_isConnected) {
      _socket?.connect();
    }
  }
}