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
    String participantUserId(Map participant) {
      final rawUser = participant['user'];
      final nestedUser = rawUser is Map ? rawUser : null;
      return (participant['userId'] ?? nestedUser?['id'] ?? '').toString();
    }

    final participants = (json['participants'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList();

    final otherParticipant = participants.firstWhere(
      (item) => participantUserId(item) != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : const {},
    );
    final user = otherParticipant['user'] as Map?;
    final profile = user?['profile'] as Map?;

    final messages = (json['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList();

    final latest = messages.isNotEmpty ? messages.first : const {};

    final countMap = json['_count'] as Map<String, dynamic>?;
    final unreadCountRaw = countMap?['unreadMessages'] ?? countMap?['messages'];
    final unreadCount = unreadCountRaw is num ? unreadCountRaw.toInt() : 0;

    String partnerName =
        (user?['name'] ?? user?['username'])?.toString() ?? 'Unknown user';
    if (partnerName == 'Unknown user') {
      partnerName =
          (profile?['fullName'] ?? profile?['username'])?.toString() ??
          'Unknown user';
    }

    final conversationAvatar =
        (user?['avatarUrl'] ?? profile?['profileImage'] ?? user?['profilePic'])
            ?.toString();
    final partnerId = participantUserId(otherParticipant);

    return ChatConversationModel(
      chatId: (json['id'] ?? json['_id'] ?? '').toString(),
      partnerId: partnerId,
      partnerName: partnerName,
      partnerAvatarUrl: conversationAvatar,
      lastMessage: (latest['content'] ?? 'No messages yet').toString(),
      lastMessageAt: DateTime.tryParse((latest['createdAt'] ?? '').toString()),
      unreadCount: unreadCount,
    );
  }
}
