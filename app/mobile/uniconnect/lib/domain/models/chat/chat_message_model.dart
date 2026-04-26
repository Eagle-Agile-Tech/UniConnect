import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required String chatId,
    required String senderId,
    String? senderName,
    required String content,
    required DateTime createdAt,
    @Default('sent') String status,
    String? clientMessageId,
    @Default(false) bool isMine,
    @Default(false) bool isPending,
    @Default(false) bool isFailed,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  factory ChatMessageModel.fromApi(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderId =
        (json['senderId'] ?? sender?['id'] ?? sender?['userId'] ?? '') as String;

    return ChatMessageModel(
      id: (json['id'] ?? json['messageId'] ?? json['clientMessageId'] ?? '')
          .toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: senderId,
      senderName: (sender?['username'] ?? sender?['name'])?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: (json['status'] ?? 'sent').toString(),
      clientMessageId: json['clientMessageId']?.toString(),
      isMine: senderId == currentUserId,
    );
  }
}

