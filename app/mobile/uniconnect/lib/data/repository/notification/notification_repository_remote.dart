import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/notification/notification_item.dart';
import '../../../utils/result.dart';
import '../../service/api/api_client.dart';
import 'notification_repository.dart';

final notificationRepoProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryRemote(ref.watch(apiClientProvider));
});

class NotificationRepositoryRemote implements NotificationRepository {
  const NotificationRepositoryRemote(this._client);

  final ApiClient _client;

  @override
  Future<Result<NotificationFeed>> getNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final result = await _client.fetchNotifications(
      limit: limit,
      unreadOnly: unreadOnly,
    );

    return result.fold((data) {
      final rawNotifications = (data['notifications'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((json) => NotificationItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      final unreadCountRaw = data['unreadCount'];
      final unreadCount = unreadCountRaw is num ? unreadCountRaw.toInt() : 0;

      return Result.ok(
        NotificationFeed(
          notifications: rawNotifications,
          unreadCount: unreadCount,
        ),
      );
    }, (error, stackTrace) => Result.error(error, stackTrace));
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    return _client.fetchUnreadNotificationCount();
  }

  @override
  Future<Result<NotificationItem>> markAsRead(String notificationId) async {
    final result = await _client.markNotificationAsRead(notificationId);
    return result.fold((data) {
      final rawNotification = data['notification'];
      if (rawNotification is Map) {
        return Result.ok(
          NotificationItem.fromJson(Map<String, dynamic>.from(rawNotification)),
        );
      }
      return Result.error(StateError('Invalid notification payload'));
    }, (error, stackTrace) => Result.error(error, stackTrace));
  }

  @override
  Future<Result<int>> markAllAsRead() async {
    return _client.markAllNotificationsAsRead();
  }
}
