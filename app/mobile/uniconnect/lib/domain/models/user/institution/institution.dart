import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/enums.dart';
import '../user.dart';

part 'institution.freezed.dart';
part 'institution.g.dart';

@freezed
abstract class Institution with _$Institution {
  const factory Institution({
    String? description,
    required InstitutionType type,
    String? website,
    String? logoUri,
    required InstitutionVerificationStatus verificationStatus,
    String? secretCode,
    required DateTime createdAt,
    required List<User> affiliatedExperts,
  }) = _Institution;

  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);
}