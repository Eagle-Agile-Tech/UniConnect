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
    final socketUrl = baseUrl.replaceFirst('/api', '');
    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build()
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      debugPrint("Socket connected");
      _isConnected = true;
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

    _socket?.on('chat:message:new', (data) {
      _notifyListeners('message:received', data);
    });

    _socket?.on('chat:message:updated', (data) {
      _notifyListeners('message:sent', data);
    });

    _socket?.on('chat:typing', (data) {
      _notifyListeners('typing:update', data);
    });

    _socket?.on('chat:presence', (data) {
      final status = (data is Map ? data['status'] : null)?.toString().toUpperCase();
      if (status == 'ONLINE') {
        _notifyListeners('user:online', data);
      } else if (status == 'OFFLINE') {
        _notifyListeners('user:offline', data);
      }
    });

    _socket?.on('chat:read', (data) {
      _notifyListeners('message:read', data);
    });

    _socket?.on('chat:messages:delivered', (data) {
      _notifyListeners('message:delivered', data);
    });

    // Server may emit single-message delivery events as well.
    _socket?.on('chat:message:delivered', (data) {
      _notifyListeners('message:delivered', data);
    });

    _socket?.on('notification', (data) {
      _notifyListeners('notification:received', data);
    });

    _socket?.on('notification:unread-count', (data) {
      _notifyListeners('notification:unread-count', data);
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
    String? clientMessageId,
  }) {
    _emitEvent('chat:send', {
      'chatId': chatId,
      'content': content,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  void sendTypingIndicator(String chatId, bool isTyping) {
    _emitEvent('chat:typing', {
      'chatId': chatId,
      'isTyping': isTyping,
    });
  }

  void markMessageAsRead(String messageId, String chatId) {
    _emitEvent('chat:read', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  void markMessageAsDelivered(String messageId, String chatId) {
    _emitEvent('chat:delivered', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  void updateUserStatus(bool isOnline) {
    // Presence is managed by backend connect/disconnect and chat join/leave.
    if (!isOnline) return;
  }

  void joinChatRoom(String chatId) {
    _emitEvent('chat:join', {'chatId': chatId});
  }

  void leaveChatRoom(String chatId) {
    _emitEvent('chat:leave', {'chatId': chatId});
  }

  void disconnect() {
    if (_socket != null) {
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
