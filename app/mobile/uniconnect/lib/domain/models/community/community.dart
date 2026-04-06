import 'package:freezed_annotation/freezed_annotation.dart';

part 'community.freezed.dart';
part 'community.g.dart';

@freezed
abstract class Community with _$Community {
  factory Community({
    required String id,
    required String communityName,
    required String ownerId,
    required String description,
    String? profilePicture,
    required int members,
    required String university,

    @Default(false) bool isMember,
  }) = _Community;

  factory Community.fromJson(Map<String, dynamic> json) => _$CommunityFromJson(json);
}