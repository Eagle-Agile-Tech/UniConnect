import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';
import 'package:uniconnect/utils/result.dart';

final authApiClientProvider = Provider((ref) => AuthApiClient());

class AuthApiClient {
  final http.Client client;

  AuthApiClient({http.Client? client}) : client = client ?? http.Client();

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

  Future<Result<String>> createUserProfile({
    required String id,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    required DateTime createdAt,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.http('localhost:8080', '/createProfile'),
      );
      request.fields['id'] = id;
      request.fields['university'] = university;
      request.fields['degree'] = degree;
      request.fields['currentYear'] = currentYear;
      request.fields['expectedGraduationYear'] = expectedGraduationYear
          .toIso8601String();
      request.fields['createdAt'] = createdAt.toIso8601String();
      if (bio != null) request.fields['bio'] = bio;
      if (interests != null) {
        request.fields['interests'] = jsonEncode(interests);
      }
      if (profilePicture != null) {
        final stream = http.ByteStream(profilePicture.openRead());
        final length = await profilePicture.length();
        final image = http.MultipartFile(
          'profilePicture',
          stream,
          length,
          filename: profilePicture.path,
        );
        request.files.add(image);
      }
      var streamResponse = await client.send(request);
      final response = await http.Response.fromStream(streamResponse);
      // The API is expected to return the URL of the uploaded profile picture on success
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return Result.ok(responseBody['profilePicture'] as String);
      } else {
        return Result.error(Exception('Failed to create profile'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }
}
