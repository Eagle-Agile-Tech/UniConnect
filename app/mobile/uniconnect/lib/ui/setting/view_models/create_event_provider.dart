import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/event/event_repository.dart';
import 'package:uniconnect/data/repository/event/event_repository_remote.dart';
import 'package:uniconnect/domain/models/event/event.dart';

import 'event_provider.dart';

final createEventProvider = AsyncNotifierProvider<CreateEventViewModel, void>(
  CreateEventViewModel.new,
);

class CreateEventViewModel extends AsyncNotifier<void> {
  late final EventRepository _eventRepo;

  @override
  FutureOr<void> build() {
    _eventRepo = ref.watch(eventRepoProvider);
    return null;
  }

  Future<void> createEvent({
    required Event event,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    final result = await _eventRepo.createEvent(event);
    state = result.fold(
      (_) {
        ref.invalidate(eventProvider(userId));
        return const AsyncValue.data(null);
      },
      (error, stackTrace) =>
          AsyncError(error, stackTrace ?? StackTrace.current),
    );
  }
}
