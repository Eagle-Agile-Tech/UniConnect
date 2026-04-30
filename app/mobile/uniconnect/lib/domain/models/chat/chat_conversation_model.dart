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
        .whereType<Map>()
        .toList();

    final otherParticipant = participants.firstWhere(
      (item) => item['userId']?.toString() != currentUserId,
      orElse: () =>
          participants.isNotEmpty ? participants.first : const {},
    );
    final user = otherParticipant['user'] as Map?;
    final profile = user?['profile'] as Map?;

    final messages = (json['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList();

    final latest = messages.isNotEmpty
        ? messages.first
        : const {};

    final unreadCount = messages.where((message) {
      final senderId = (message['senderId'] ?? '').toString();
      if (senderId == currentUserId) {
        return false;
      }
      final receipts = (message['receipts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .toList();
      final myReceipt = receipts.firstWhere(
        (receipt) => receipt['userId']?.toString() == currentUserId,
        orElse: () => const {},
      );
      return myReceipt.isNotEmpty && myReceipt['readAt'] == null;
    }).length;

    String partnerName = (user?['name'] ?? user?['username'])?.toString() ?? 'Unknown user';
    if (partnerName == 'Unknown user') {
      partnerName = (profile?['fullName'] ?? profile?['username'])?.toString() ?? 'Unknown user';
    }

    return ChatConversationModel(
      chatId: (json['id'] ?? json['_id'] ?? '').toString(),
      partnerId: (otherParticipant['userId'] ?? otherParticipant['id'] ?? '').toString(),
      partnerName: partnerName,
      partnerAvatarUrl:
          (user?['avatarUrl'] ?? profile?['profileImage'] ?? user?['profilePic'])
              ?.toString(),
      lastMessage: (latest['content'] ?? 'No messages yet').toString(),
      lastMessageAt: DateTime.tryParse((latest['createdAt'] ?? '').toString()),
      unreadCount: unreadCount,
    );
  }
}
