import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/enums.dart';
import '../user.dart';

part 'institution.freezed.dart';
part 'institution.g.dart';

@freezed
abstract class Institution with _$Institution {
  const factory Institution({
    // required String id,
    // make the firstname -> name and the lastname empty
    // required String name,
    // make this bio
    // String? description,
    required InstitutionType type,
    String? website,
    // give me this as a profileimage
    // String? logoUri,
    required InstitutionVerificationStatus verificationStatus,
    String? secretCode,
    // honestly unnecessary for me
    // required DateTime createdAt,
    required List<User> affiliatedExperts,
  }) = _Institution;

  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);
}