import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/service/api/api_client.dart';
import '../../../data/service/socket/socket_service.dart';
import '../../../domain/models/notification/notification_item.dart';

class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;

  const NotificationState({
    required this.items,
    required this.unreadCount,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

final notificationViewModelProvider =
    AsyncNotifierProvider<NotificationViewModel, NotificationState>(
  NotificationViewModel.new,
);

class NotificationViewModel extends AsyncNotifier<NotificationState> {
  late final ApiClient _api;
  final SocketService _socket = SocketService();

  StreamSubscription? _socketSub;

  @override
  FutureOr<NotificationState> build() async {
    _api = ref.read(apiClientProvider);

    // Load inbox.
    final initial = await _fetch();

    // Attach socket listeners (best-effort).
    _attachSocketListeners();

    ref.onDispose(() {
      _detachSocketListeners();
    });

    return initial;
  }

  Future<NotificationState> _fetch() async {
    final result = await _api.fetchNotifications(limit: 20, unreadOnly: false);
    return result.fold((data) {
      final payload = data;
      final rawNotifications = payload['notifications'];
      final rawUnread = payload['unreadCount'];

      final items = (rawNotifications is List ? rawNotifications : const [])
          .map(NotificationItem.fromJson)
          .whereType<NotificationItem>()
          .toList();

      final unreadCount = rawUnread is int
          ? rawUnread
          : rawUnread is num
              ? rawUnread.toInt()
              : 0;

      return NotificationState(items: items, unreadCount: unreadCount);
    }, (error, _) => throw error);
  }

  void _attachSocketListeners() {
    // SocketService is a singleton; listeners are additive, so be careful to remove.
    void onNotification(dynamic payload) {
      final item = NotificationItem.fromJson(payload);
      if (item == null) return;

      final current = state.valueOrNull;
      if (current == null) return;

      // Deduplicate if we already have it.
      final exists = current.items.any((n) => n.id == item.id);
      final nextItems = exists ? current.items : [item, ...current.items];
      final nextUnread = item.isRead ? current.unreadCount : current.unreadCount + (exists ? 0 : 1);
      state = AsyncValue.data(current.copyWith(items: nextItems, unreadCount: nextUnread));
    }

    void onUnreadCount(dynamic payload) {
      final current = state.valueOrNull;
      if (current == null) return;

      int? next;
      if (payload is Map) {
        final v = payload['unreadCount'];
        if (v is int) next = v;
        if (v is num) next = v.toInt();
      }
      if (next == null) return;

      state = AsyncValue.data(current.copyWith(unreadCount: next));
    }

    _socket.addEventListener('notification:received', onNotification);
    _socket.addEventListener('notification:unread-count', onUnreadCount);

    // Track detach closures via a StreamSubscription-like shim.
    _socketSub = _SocketDetach(() {
      _socket.removeEventListener('notification:received', onNotification);
      _socket.removeEventListener('notification:unread-count', onUnreadCount);
    });
  }

  void _detachSocketListeners() {
    _socketSub?.cancel();
    _socketSub = null;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _fetch());
  }

  Future<void> markAsRead(String notificationId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update.
    final nextItems = current.items
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    final unreadCount = nextItems.where((n) => !n.isRead).length;
    state = AsyncValue.data(current.copyWith(items: nextItems, unreadCount: unreadCount));

    await _api.markNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final nextItems = current.items.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncValue.data(current.copyWith(items: nextItems, unreadCount: 0));

    await _api.markAllNotificationsAsRead();
  }
}

class _SocketDetach implements StreamSubscription<void> {
  final void Function() _onCancel;
  bool _isCanceled = false;

  _SocketDetach(this._onCancel);

  @override
  Future<void> cancel() async {
    if (_isCanceled) return;
    _isCanceled = true;
    _onCancel();
  }

  @override
  void onData(void Function(void data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  bool get isPaused => false;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}

