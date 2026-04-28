// import 'dart:async';
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../data/repository/notification/notification_repository.dart';
// import '../../../data/repository/notification/notification_repository_remote.dart';
// import '../../../data/service/local/secure_token_storage.dart';
// import '../../../data/service/socket/socket_service.dart';
// import '../../../domain/models/notification/notification_item.dart';
// import '../../auth/auth_state_provider.dart';
//
// class NotificationState {
//   const NotificationState({
//     required this.items,
//     required this.unreadCount,
//   });
//
//   final List<NotificationItem> items;
//   final int unreadCount;
//
//   NotificationState copyWith({
//     List<NotificationItem>? items,
//     int? unreadCount,
//   }) {
//     return NotificationState(
//       items: items ?? this.items,
//       unreadCount: unreadCount ?? this.unreadCount,
//     );
//   }
// }
//
// final notificationViewModelProvider =
//     AsyncNotifierProvider<NotificationViewModel, NotificationState>(
//       NotificationViewModel.new,
//     );
//
// class NotificationViewModel extends AsyncNotifier<NotificationState> {
//   late NotificationRepository _repo;
//   final SocketService _socketService = SocketService();
//   final SecureTokenStorage _tokenStorage = SecureTokenStorage();
//
//   void Function(dynamic data)? _notificationHandler;
//   void Function(dynamic data)? _unreadCountHandler;
//   bool _socketBound = false;
//
//   @override
//   FutureOr<NotificationState> build() async {
//     _repo = ref.watch(notificationRepoProvider);
//     ref.onDispose(_disposeSocketListeners);
//
//     await _initSocketBridge();
//     final result = await _repo.getNotifications(limit: 50);
//     return result.fold(
//       (feed) => NotificationState(
//         items: feed.notifications,
//         unreadCount: feed.unreadCount,
//       ),
//       (error, stackTrace) =>
//           Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
//     );
//   }
//
//   Future<void> refresh() async {
//     final result = await _repo.getNotifications(limit: 50);
//     result.fold((feed) {
//       state = AsyncData(
//         NotificationState(
//           items: feed.notifications,
//           unreadCount: feed.unreadCount,
//         ),
//       );
//     }, (error, stackTrace) {
//       state = AsyncError(error, stackTrace ?? StackTrace.current);
//     });
//   }
//
//   Future<void> markAsRead(String notificationId) async {
//     final current = state.value;
//     if (current == null) {
//       return;
//     }
//
//     final target = current.items.where((item) => item.id == notificationId);
//     if (target.isEmpty || target.first.isRead) {
//       return;
//     }
//
//     final result = await _repo.markAsRead(notificationId);
//     result.fold((updatedItem) {
//       final updated = current.items.map((item) {
//         if (item.id == notificationId) {
//           return item.copyWith(isRead: updatedItem.isRead);
//         }
//         return item;
//       }).toList();
//
//       final nextUnread = (current.unreadCount - 1).clamp(0, 1 << 30);
//       state = AsyncData(current.copyWith(items: updated, unreadCount: nextUnread));
//     }, (_, _) {});
//   }
//
//   Future<void> markAllAsRead() async {
//     final current = state.value;
//     if (current == null) {
//       return;
//     }
//
//     final result = await _repo.markAllAsRead();
//     result.fold((_) {
//       final updatedItems = current.items
//           .map((item) => item.isRead ? item : item.copyWith(isRead: true))
//           .toList();
//       state = AsyncData(current.copyWith(items: updatedItems, unreadCount: 0));
//     }, (_, _) {});
//   }
//
//   Future<void> _initSocketBridge() async {
//     if (_socketBound) {
//       return;
//     }
//
//     final authState = ref.read(authNotifierProvider).value;
//     final userId = authState?.user?.id;
//     final token = await _tokenStorage.read();
//
//     if (userId == null || token?.accessToken == null) {
//       return;
//     }
//
//     _socketService.initialize(userId, token!.accessToken);
//     _notificationHandler = _onRealtimeNotification;
//     _unreadCountHandler = _onRealtimeUnreadCount;
//     _socketService.addEventListener('notification:received', _notificationHandler!);
//     _socketService.addEventListener(
//       'notification:unread-count',
//       _unreadCountHandler!,
//     );
//     _socketBound = true;
//   }
//
//   void _onRealtimeNotification(dynamic payload) {
//     final current = state.value;
//     if (current == null) {
//       return;
//     }
//
//     final map = _asMap(payload);
//     if (map == null) {
//       return;
//     }
//
//     final incoming = NotificationItem.fromJson(map);
//     final existingIndex = current.items.indexWhere((item) => item.id == incoming.id);
//     final updatedItems = List<NotificationItem>.from(current.items);
//
//     if (existingIndex >= 0) {
//       updatedItems[existingIndex] = incoming;
//       state = AsyncData(current.copyWith(items: updatedItems));
//       return;
//     }
//
//     updatedItems.insert(0, incoming);
//     final unreadCount = incoming.isRead
//         ? current.unreadCount
//         : current.unreadCount + 1;
//     state = AsyncData(current.copyWith(items: updatedItems, unreadCount: unreadCount));
//   }
//
//   void _onRealtimeUnreadCount(dynamic payload) {
//     final current = state.value;
//     if (current == null) {
//       return;
//     }
//     final map = _asMap(payload);
//     if (map == null) {
//       return;
//     }
//     final unreadCountRaw = map['unreadCount'];
//     if (unreadCountRaw is! num) {
//       return;
//     }
//
//     state = AsyncData(current.copyWith(unreadCount: unreadCountRaw.toInt()));
//   }
//
//   Map<String, dynamic>? _asMap(dynamic payload) {
//     if (payload is Map<String, dynamic>) {
//       return payload;
//     }
//     if (payload is Map) {
//       return Map<String, dynamic>.from(payload);
//     }
//     return null;
//   }
//
//   void _disposeSocketListeners() {
//     if (_notificationHandler != null) {
//       _socketService.removeEventListener(
//         'notification:received',
//         _notificationHandler!,
//       );
//     }
//     if (_unreadCountHandler != null) {
//       _socketService.removeEventListener(
//         'notification:unread-count',
//         _unreadCountHandler!,
//       );
//     }
//     _socketBound = false;
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';

import '../../../domain/models/user/user.dart';

final notificationViewModelProvider =
AsyncNotifierProvider<NotificationViewModel, List<(User user, String requestId)>>(
  NotificationViewModel.new,
);

class NotificationViewModel
    extends AsyncNotifier<List<(User user, String requestId)>> {

  late UserRepositoryRemote _userRepo;

  @override
  Future<List<(User user, String requestId)>> build() async {
    _userRepo = ref.read(userRepoProvider);

    final result = await _userRepo.getIncomingNetworks();

    return result.fold(
          (data) => data,
          (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }
}



