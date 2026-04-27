import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/event/event_repository.dart';
import 'package:uniconnect/data/repository/event/event_repository_remote.dart';

import '../../../domain/models/event/event.dart';

final eventProvider =
    AsyncNotifierProvider.family<EventViewModel, List<Event>, String>(
      EventViewModel.new,
    );

class EventViewModel extends AsyncNotifier<List<Event>> {
  EventViewModel(this.userId);

  final String userId;
  late EventRepository _repo;

  @override
  FutureOr<List<Event>> build() async {
    _repo = ref.watch(eventRepoProvider);
    final eventData = await _repo.getPublicUserEvents(userId);
    return eventData.fold((events) => events, (error, stackTrace) => throw error);
  }
}
