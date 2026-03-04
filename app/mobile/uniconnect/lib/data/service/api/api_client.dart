import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uniconnect/utils/result.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Result<dynamic>> fetchUserPost(String id) async {
    try {
      final response = await _client.get(Uri.parse('/posts/$id'));
      if (response.statusCode == 200) {
        return Result.ok(response.body);
      } else {
        return Result.error(Exception('Couldn\'t fetch post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }
}
