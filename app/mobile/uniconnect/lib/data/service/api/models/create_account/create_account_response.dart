import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_account_response.freezed.dart';
part 'create_account_response.g.dart';


@freezed
abstract class CreateAccountResponse with _$CreateAccountResponse{
  factory CreateAccountResponse({
          required String userId,
          required String otpCode,
        }) = _CreateAccountResponse;

  factory CreateAccountResponse.fromJson(Map<String, dynamic> json) => _$CreateAccountResponseFromJson(json);
}