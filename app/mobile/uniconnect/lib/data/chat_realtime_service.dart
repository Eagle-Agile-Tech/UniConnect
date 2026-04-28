import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/models/chat/chat_message_model.dart';
import 'service/api/routes/api_routes.dart';

class ChatPresenceEvent {
  const ChatPresenceEvent({
    required this.chatId,
    required this.userId,
    required this.status,
    this.lastSeenAt,
  });

  final String chatId;
  final String userId;
  final String status;
  final DateTime? lastSeenAt;
}

class ChatTypingEvent {
  const ChatTypingEvent({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  final String chatId;
  final String userId;
  final bool isTyping;
}

class ChatReadEvent {
  const ChatReadEvent({
    required this.chatId,
    required this.userId,
    this.messageId,
  });

  final String chatId;
  final String userId;
  final String? messageId;
}

class ChatDeliveredEvent {
  const ChatDeliveredEvent({
    required this.chatId,
    required this.userId,
    required this.messageIds,
    this.deliveredAt,
  });

  final String chatId;
  final String userId;
  final List<String> messageIds;
  final DateTime? deliveredAt;
}

class ChatPresenceUserState {
  const ChatPresenceUserState({
    required this.userId,
    required this.status,
    this.lastSeenAt,
  });

  final String userId;
  final String status;
  final DateTime? lastSeenAt;
}

class ChatPresenceStateEvent {
  const ChatPresenceStateEvent({required this.chatId, required this.users});

  final String? chatId;
  final List<ChatPresenceUserState> users;
}

class ChatTypingStateEvent {
  const ChatTypingStateEvent({required this.chatId, required this.users});

  final String chatId;
  final List<String> users;
}

class ChatRealtimeService {
  ChatRealtimeService();

  io.Socket? _socket;
  String? _currentUserId;
  final _incomingController = StreamController<ChatMessageModel>.broadcast();
  final _presenceController = StreamController<ChatPresenceEvent>.broadcast();
  final _typingController = StreamController<ChatTypingEvent>.broadcast();
  final _readController = StreamController<ChatReadEvent>.broadcast();
  final _deliveredController = StreamController<ChatDeliveredEvent>.broadcast();
  final _presenceStateController =
      StreamController<ChatPresenceStateEvent>.broadcast();
  final _typingStateController =
      StreamController<ChatTypingStateEvent>.broadcast();
  final _errorController = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;
  Stream<ChatMessageModel> get incomingMessages => _incomingController.stream;
  Stream<ChatPresenceEvent> get presenceUpdates => _presenceController.stream;
  Stream<ChatTypingEvent> get typingUpdates => _typingController.stream;
  Stream<ChatReadEvent> get readUpdates => _readController.stream;
  Stream<ChatDeliveredEvent> get deliveredUpdates =>
      _deliveredController.stream;
  Stream<ChatPresenceStateEvent> get presenceState =>
      _presenceStateController.stream;
  Stream<ChatTypingStateEvent> get typingState => _typingStateController.stream;
  Stream<Map<String, dynamic>> get errors => _errorController.stream;

  Future<void> connect({
    required String token,
    required String currentUserId,
  }) async {
    _currentUserId = currentUserId;
    if (_socket != null) {
      if (!_connected) {
        _socket?.connect();
      }
      return;
    }

    final socketUrl = baseUrl.replaceFirst('/api', '');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      _connected = true;
      debugPrint('Chat socket connected');
    });

    _socket?.onDisconnect((_) {
      _connected = false;
    });

    // Socket-level errors and server emitted chat errors
    _socket?.onConnectError((err) {
      try {
        _errorController.add({
          'type': 'connect_error',
          'message': err?.toString() ?? 'connect_error',
        });
      } catch (_) {}
    });

    _socket?.on('connect_error', (err) {
      try {
        _errorController.add({
          'type': 'connect_error',
          'message': err?.toString() ?? 'connect_error',
        });
      } catch (_) {}
    });

    _socket?.on('chat:error', (payload) {
      final map = _asMap(payload) ?? {'message': payload?.toString()};
      try {
        _errorController.add(Map<String, dynamic>.from(map));
      } catch (_) {
        _errorController.add({'message': payload?.toString()});
      }
    });

    _socket?.on('chat:message:new', (payload) => _onMessage(payload));
    _socket?.on('chat:presence', (payload) => _onPresence(payload));
    _socket?.on('chat:typing', (payload) => _onTyping(payload));
    _socket?.on('chat:read', (payload) => _onRead(payload));
    _socket?.on('chat:messages:delivered', (payload) => _onDelivered(payload));
    _socket?.on('chat:presence:state', (payload) => _onPresenceState(payload));
    _socket?.on('chat:typing:state', (payload) => _onTypingState(payload));
  }

  void joinChat(String chatId) {
    _socket?.emit('chat:join', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _socket?.emit('chat:leave', {'chatId': chatId});
  }

  void sendTyping({required String chatId, required bool isTyping}) {
    _socket?.emit('chat:typing', {'chatId': chatId, 'isTyping': isTyping});
  }

  void markRead({required String chatId, String? messageId}) {
    _socket?.emit('chat:read', {'chatId': chatId, 'messageId': messageId});
  }

  void markDelivered({required String chatId, String? messageId}) {
    _socket?.emit('chat:delivered', {'chatId': chatId, 'messageId': messageId});
  }

  void queryPresence({required String chatId}) {
    _socket?.emit('chat:presence:query', {'chatId': chatId});
  }

  void queryTyping({required String chatId}) {
    _socket?.emit('chat:typing:query', {'chatId': chatId});
  }

  void _onMessage(dynamic payload) {
    final data = _extractPayloadMap(payload);
    final currentUserId = _currentUserId;
    if (data == null || currentUserId == null || currentUserId.isEmpty) {
      return;
    }
    _incomingController.add(ChatMessageModel.fromApi(data, currentUserId));
  }

  void _onPresence(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    _presenceController.add(
      ChatPresenceEvent(
        chatId: (data['chatId'] ?? '').toString(),
        userId: (data['userId'] ?? '').toString(),
        status: (data['status'] ?? 'OFFLINE').toString(),
        lastSeenAt: _parseDate(data['lastSeenAt']),
      ),
    );
  }

  void _onTyping(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    _typingController.add(
      ChatTypingEvent(
        chatId: (data['chatId'] ?? '').toString(),
        userId: (data['userId'] ?? '').toString(),
        isTyping: data['isTyping'] == true,
      ),
    );
  }

  void _onRead(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    _readController.add(
      ChatReadEvent(
        chatId: (data['chatId'] ?? '').toString(),
        userId: (data['userId'] ?? '').toString(),
        messageId: data['messageId']?.toString(),
      ),
    );
  }

  void _onDelivered(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    final rawMessageIds = (data['messageIds'] as List<dynamic>? ?? const []);
    _deliveredController.add(
      ChatDeliveredEvent(
        chatId: (data['chatId'] ?? '').toString(),
        userId: (data['userId'] ?? '').toString(),
        messageIds: rawMessageIds.map((id) => id.toString()).toList(),
        deliveredAt: _parseDate(data['deliveredAt']),
      ),
    );
  }

  void _onPresenceState(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    final rawUsers = (data['users'] as List<dynamic>? ?? const []);
    final users = rawUsers.map((entry) {
      final map = Map<String, dynamic>.from(entry as Map);
      return ChatPresenceUserState(
        userId: (map['userId'] ?? '').toString(),
        status: (map['status'] ?? 'OFFLINE').toString(),
        lastSeenAt: _parseDate(map['lastSeenAt']),
      );
    }).toList();
    _presenceStateController.add(
      ChatPresenceStateEvent(chatId: data['chatId']?.toString(), users: users),
    );
  }

  void _onTypingState(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }
    final rawUsers = (data['users'] as List<dynamic>? ?? const []);
    _typingStateController.add(
      ChatTypingStateEvent(
        chatId: (data['chatId'] ?? '').toString(),
        users: rawUsers.map((userId) => userId.toString()).toList(),
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  Map<String, dynamic>? _extractPayloadMap(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) {
      return null;
    }

    final nestedMessage = _asMap(root['message']);
    if (nestedMessage != null) {
      return nestedMessage;
    }
    final nestedData = _asMap(root['data']);
    if (nestedData != null) {
      return nestedData;
    }
    return root;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _incomingController.close();
    _presenceController.close();
    _typingController.close();
    _readController.close();
    _deliveredController.close();
    _presenceStateController.close();
    _typingStateController.close();
    _errorController.close();
  }
}
