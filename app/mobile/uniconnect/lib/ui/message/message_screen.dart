import 'package:flutter/material.dart';

import '../../presentation/chat/chat_thread_state.dart';
import '../../presentation/chat/chat_thread_view.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.profileImage,
    this.chatId,
  });

  final String receiverId;
  final String receiverName;
  final String? profileImage;
  final String? chatId;

  @override
  Widget build(BuildContext context) {
    return ChatThreadView(
      args: ChatThreadArgs(
        receiverId: receiverId,
        receiverName: receiverName,
        receiverAvatar: profileImage,
        chatId: chatId,
      ),
    );
  }
}
