import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_conversation_model.freezed.dart';
part 'chat_conversation_model.g.dart';

@freezed
abstract class ChatConversationModel with _$ChatConversationModel {
  const factory ChatConversationModel({
    required String chatId,
    required String partnerId,
    required String partnerName,
    String? partnerAvatarUrl,
    @Default('No messages yet') String lastMessage,
    DateTime? lastMessageAt,
    @Default(0) int unreadCount,
  }) = _ChatConversationModel;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationModelFromJson(json);

  factory ChatConversationModel.fromApi(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final participants = (json['participants'] as List<dynamic>? ?? const [])
        .cast<Map<dynamic, dynamic>>();
    final otherParticipant = participants.cast<Map>().firstWhere(
      (item) => item['userId'] != currentUserId,
      orElse: () =>
          participants.isNotEmpty ? participants.first : <dynamic, dynamic>{},
    );
    final user = otherParticipant['user'] as Map<dynamic, dynamic>?;

    final messages = (json['messages'] as List<dynamic>? ?? const [])
        .cast<Map>();
    final latest = messages.isNotEmpty
        ? messages.first
        : const <dynamic, dynamic>{};
    final unreadCount = messages.where((message) {
      final senderId = (message['senderId'] ?? '').toString();
      if (senderId == currentUserId) {
        return false;
      }
      final receipts = (message['receipts'] as List<dynamic>? ?? const [])
          .cast<Map>();
      final myReceipt = receipts.cast<Map>().firstWhere(
        (receipt) => receipt['userId']?.toString() == currentUserId,
        orElse: () => const <dynamic, dynamic>{},
      );
      return myReceipt.isNotEmpty && myReceipt['readAt'] == null;
    }).length;

    return ChatConversationModel(
      chatId: (json['id'] ?? '').toString(),
      partnerId: (otherParticipant['userId'] ?? '').toString(),
      partnerName: (user?['username'] ?? user?['name'] ?? 'Unknown user')
          .toString(),
      partnerAvatarUrl:
          (user?['avatarUrl'] ?? user?['profilePic'] ?? user?['profileImage'])
              ?.toString(),
      lastMessage: (latest['content'] ?? 'No messages yet').toString(),
      lastMessageAt: DateTime.tryParse((latest['createdAt'] ?? '').toString()),
      unreadCount: unreadCount,
    );
  }
}
