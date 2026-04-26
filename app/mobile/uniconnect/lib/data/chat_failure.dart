import 'package:dio/dio.dart';

class ChatFailure implements Exception {
  const ChatFailure({required this.message, this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory ChatFailure.fromException(Object error) {
    if (error is ChatFailure) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message =
          data is Map<String, dynamic> && data['message'] is String
              ? data['message'] as String
              : error.message ?? 'Network request failed';
      return ChatFailure(message: message, statusCode: statusCode, cause: error);
    }

    return ChatFailure(message: 'Unexpected chat error', cause: error);
  }

  @override
  String toString() => message;
}

