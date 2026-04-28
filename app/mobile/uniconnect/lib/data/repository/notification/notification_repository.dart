import '../../../domain/models/notification/notification_item.dart';
import '../../../utils/result.dart';

abstract class NotificationRepository {
  Future<Result<NotificationFeed>> getNotifications({
    int limit = 20,
    bool unreadOnly = false,
  });

  Future<Result<int>> getUnreadCount();

  Future<Result<NotificationItem>> markAsRead(String notificationId);

  Future<Result<int>> markAllAsRead();
}
