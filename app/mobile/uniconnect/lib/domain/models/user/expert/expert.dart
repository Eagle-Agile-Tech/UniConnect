import 'package:freezed_annotation/freezed_annotation.dart';

part 'expert.freezed.dart';
part 'expert.g.dart';

@freezed
abstract class Expert with _$Expert{
  const factory Expert({
    required String expertise,
    String? honor,
})  = _Expert;

  factory Expert.fromJson(Map<String,dynamic> json) => _$ExpertFromJson(json);
}