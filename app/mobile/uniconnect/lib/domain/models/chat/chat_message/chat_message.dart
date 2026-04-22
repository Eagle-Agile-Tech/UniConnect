import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._(); // for custom getters if needed

  const factory ChatMessage({
    required String messageId,
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    required DateTime createdAt,
    @Default('sent') String status,
    @Default(false) bool isMine,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// 🔥 Custom mapper (handles nested API + isMine logic)
  factory ChatMessage.fromMap(Map<String, dynamic> map, String currentUserId) {
    final senderId = map['senderId'] ?? map['sender']?['id'] ?? '';

    final receiverId = map['receiverId'] ?? map['receiver']?['id'] ?? '';

    return ChatMessage(
      messageId: map['id'] ?? map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: senderId,
      receiverId: receiverId,
      content: map['content'] ?? map['message'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ??
            map['timestamp'] ??
            DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'sent',
      isMine: senderId == currentUserId,
    );
  }
}
