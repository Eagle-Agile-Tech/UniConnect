import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final activeRoomProvider = StateProvider<String?>((ref) => null);

final chatIdProvider = StateProvider<List<String>?>((ref) => null);

// Use a StateProvider or Notifier to manage unread counts globally
final unreadCountProvider = StateProvider<Map<String, int>>((ref) => {});

// Helper to update specific counts
extension UnreadCountExtension on WidgetRef {
  void incrementUnread(String senderId) {
    final current = read(unreadCountProvider);
    read(unreadCountProvider.notifier).state = {
      ...current,
      senderId: (current[senderId] ?? 0) + 1,
    };
  }

  void clearUnread(String senderId) {
    final current = read(unreadCountProvider);
    final next = Map<String, int>.from(current);
    next.remove(senderId);
    read(unreadCountProvider.notifier).state = next;
  }
}