import 'package:uniconnect/domain/models/chat/chat_message_model.dart';

class ChatThreadArgs {
  const ChatThreadArgs({
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    this.chatId,
  });

  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String? chatId;
}

class ChatThreadState {
  const ChatThreadState({
    required this.args,
    required this.chatId,
    required this.messages,
    this.isSending = false,
    this.isPartnerOnline = false,
    this.isPartnerTyping = false,
    this.partnerLastSeenAt,
    this.errorMessage,
  });

  final ChatThreadArgs args;
  final String chatId;
  final List<ChatMessageModel> messages;
  final bool isSending;
  final bool isPartnerOnline;
  final bool isPartnerTyping;
  final DateTime? partnerLastSeenAt;
  final String? errorMessage;

  ChatThreadState copyWith({
    ChatThreadArgs? args,
    String? chatId,
    List<ChatMessageModel>? messages,
    bool? isSending,
    bool? isPartnerOnline,
    bool? isPartnerTyping,
    DateTime? partnerLastSeenAt,
    bool clearLastSeen = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatThreadState(
      args: args ?? this.args,
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      partnerLastSeenAt: clearLastSeen
          ? null
          : (partnerLastSeenAt ?? this.partnerLastSeenAt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
