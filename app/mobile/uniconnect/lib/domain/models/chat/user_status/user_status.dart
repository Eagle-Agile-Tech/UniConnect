import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_status.freezed.dart';
part 'user_status.g.dart';

@freezed
abstract class UserStatus with _$UserStatus {
  const factory UserStatus({
    required String userId,
    required bool isOnline,
    DateTime? lastSeen,
  }) = _UserStatus;

  factory UserStatus.fromJson(Map<String, dynamic> json) =>
      _$UserStatusFromJson(json);
}