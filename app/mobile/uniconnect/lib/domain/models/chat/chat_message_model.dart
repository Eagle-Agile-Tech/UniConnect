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
        (json['senderId'] ?? sender?['id'] ?? sender?['userId'] ?? '')
            as String;
    final receipts = (json['receipts'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final isMine = senderId == currentUserId;
    final status = _deriveStatus(
      isMine: isMine,
      explicitStatus: json['status']?.toString(),
      receipts: receipts,
    );

    return ChatMessageModel(
      id: (json['id'] ?? json['messageId'] ?? json['clientMessageId'] ?? '')
          .toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: senderId,
      senderName: (sender?['username'] ?? sender?['name'])?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: status,
      clientMessageId: json['clientMessageId']?.toString(),
      isMine: isMine,
    );
  }
}

String _deriveStatus({
  required bool isMine,
  required String? explicitStatus,
  required List<Map<String, dynamic>> receipts,
}) {
  if (explicitStatus != null && explicitStatus.isNotEmpty) {
    return explicitStatus;
  }
  if (!isMine) {
    return 'received';
  }
  if (receipts.isEmpty) {
    return 'sent';
  }
  final allRead = receipts.every((receipt) => receipt['readAt'] != null);
  if (allRead) {
    return 'read';
  }
  final anyDelivered = receipts.any(
    (receipt) => receipt['deliveredAt'] != null,
  );
  if (anyDelivered) {
    return 'delivered';
  }
  return 'sent';
}
