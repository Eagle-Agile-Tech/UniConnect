import 'package:freezed_annotation/freezed_annotation.dart';

part 'typing_status.freezed.dart';
part 'typing_status.g.dart';

@freezed
abstract class TypingStatus with _$TypingStatus {
  const factory TypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
    required DateTime timestamp,
  }) = _TypingStatus;

  factory TypingStatus.fromJson(Map<String, dynamic> json) =>
      _$TypingStatusFromJson(json);
}