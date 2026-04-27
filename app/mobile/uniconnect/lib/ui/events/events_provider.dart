import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repository/event/event_repository_remote.dart';
import '../../domain/models/event/event.dart';

final selectedEventProvider = StateProvider<Event?>((ref) => null);

final allEventsProvider = FutureProvider.family.autoDispose<List<Event>, String?>((ref, query) async {
  final repo = ref.watch(eventRepoProvider);
  if(query == null) {
    final result = await repo.getAllEvents(university: query);
    return result.fold(
          (events) => events,
          (error, _) => throw error,
    );
  } else {
    final result = await repo.getAllEvents();
    return result.fold(
          (events) => events,
          (error, _) => throw error,
    );
  }
});

final trendingEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repo = ref.watch(eventRepoProvider);
  final result = await repo.getTrendingEvents();
  return result.fold(
    (events) => events,
    (error, _) => throw error,
  );
});

final myEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repo = ref.watch(eventRepoProvider);
  final result = await repo.getMyEvents();
  return result.fold(
    (events) => events,
    (error, _) => throw error,
  );
});

final eventDetailsProvider = FutureProvider.autoDispose.family<Event, String>((ref, id) async {
  final repo = ref.watch(eventRepoProvider);
  final result = await repo.getEventById(id);
  return result.fold(
    (event) => event,
    (error, _) => throw error,
  );
});
