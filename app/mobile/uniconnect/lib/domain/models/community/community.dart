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
    required String profilePicture,
    required List<String> members,
  }) = _Community;

  factory Community.fromJson(Map<String, dynamic> json) => _$CommunityFromJson(json);
}