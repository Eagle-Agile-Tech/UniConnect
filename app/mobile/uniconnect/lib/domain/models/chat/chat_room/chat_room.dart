import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
abstract class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String chatId,
    required String userId,
    required String username,
    String? avatarUrl,
    required String latestMessage,
    required DateTime latestMessageTime,
    @Default(0) int unreadCount,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
}