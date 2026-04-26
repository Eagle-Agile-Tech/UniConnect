import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/models/chat/chat_message_model.dart';
import 'service/api/routes/api_routes.dart';

class ChatRealtimeService {
  ChatRealtimeService();

  io.Socket? _socket;
  final _incomingController = StreamController<ChatMessageModel>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;
  Stream<ChatMessageModel> get incomingMessages => _incomingController.stream;

  Future<void> connect({required String token}) async {
    if (_socket != null) {
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

    _socket?.on('chat:message:new', (payload) {
      if (payload is Map<String, dynamic>) {
        _incomingController.add(ChatMessageModel.fromJson(payload));
      } else if (payload is Map) {
        _incomingController.add(
          ChatMessageModel.fromJson(Map<String, dynamic>.from(payload)),
        );
      }
    });
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

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _incomingController.close();
  }
}

