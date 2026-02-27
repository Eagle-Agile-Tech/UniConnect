import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';
import 'package:uniconnect/utils/result.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  final http.Client client;
  ApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      var response = await client.post(
        Uri.http('localhost:8080', '/createAccount'),
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return Result.ok(
          CreateAccountResponse.fromJson(jsonDecode(response.body)),
        );
      } else {
        return Result.error(Exception('Failed to create account'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }
}
