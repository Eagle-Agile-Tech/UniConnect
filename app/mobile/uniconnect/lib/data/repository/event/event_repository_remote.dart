import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/event/event_repository.dart';
import 'package:uniconnect/domain/models/event/event.dart';
import 'package:uniconnect/utils/result.dart';

import '../../service/api/api_client.dart';

final eventRepoProvider = Provider((ref) {
  return EventRepositoryRemote(ref.watch(apiClientProvider));
});

class EventRepositoryRemote extends EventRepository {
  final ApiClient _client;

  EventRepositoryRemote(this._client);

  @override
  Future<Result<List<Event>>> getEvents(String userId) async {
    final result = await _client.fetchEvents(userId);
    return result.fold((data) {
      final events = data.map((event) => Event.fromJson(event)).toList();
      return Result.ok(events);
    }, (error, stackTrace) => Result.error(error));
  }
}
