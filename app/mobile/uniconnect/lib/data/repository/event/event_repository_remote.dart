import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/event/event_repository.dart';
import 'package:uniconnect/domain/models/event/event.dart';
import 'package:uniconnect/utils/result.dart';

import '../../service/api/api_client.dart';

final eventRepoProvider = Provider<EventRepository>((ref) {
  return EventRepositoryRemote(ref.watch(apiClientProvider));
});

class EventRepositoryRemote extends EventRepository {
  final ApiClient _client;

  EventRepositoryRemote(this._client);

  @override
  Future<Result<List<Event>>> getAllEvents({
    String? search,
    String? university,
    DateTime? eventDay,
    String? authorId,
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _client.fetchAllEvents(
      search: search,
      university: university,
      eventDay: eventDay,
      authorId: authorId,
      page: page,
      limit: limit,
    );
    return result.fold(
      (data) => Result.ok(data.map((e) => Event.fromJson(e)).toList()),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<List<Event>>> getTrendingEvents({
    String? university,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _client.fetchTrendingEvents(
      university: university,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
    return result.fold(
      (data) => Result.ok(data.map((e) => Event.fromJson(e)).toList()),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<List<Event>>> getPublicUserEvents(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _client.fetchPublicUserEvents(
      userId,
      page: page,
      limit: limit,
    );
    return result.fold(
      (data) => Result.ok(data.map((e) => Event.fromJson(e)).toList()),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<List<Event>>> getMyEvents({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _client.fetchMyEvents(page: page, limit: limit);
    return result.fold(
      (data) => Result.ok(data.map((e) => Event.fromJson(e)).toList()),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<Event>> getEventById(String id) async {
    final result = await _client.fetchEventById(id);
    return result.fold(
      (data) => Result.ok(Event.fromJson(data)),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<void>> viewEvent(String id) async {
    return await _client.viewEvent(id);
  }

  @override
  Future<Result<void>> registerForEvent(String id) async {
    final result = await _client.registerForEvent(id);
    return result.fold(
      (_) => Result.ok(null),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<void>> cancelRegistration(String id) async {
    return await _client.cancelEventRegistration(id);
  }

  @override
  Future<Result<void>> createEvent(Event event) async {
    final result = await _client.createEvent(
      title: event.title,
      description: event.description,
      starts: event.starts,
      ends: event.ends,
      eventDay: event.eventDay,
      location: event.location,
      university: event.university,
    );
    return result.fold(
      (_) => Result.ok(null),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<void>> updateEvent(String id, Map<String, dynamic> updates) async {
    final result = await _client.updateEvent(
      id,
      title: updates['title'],
      description: updates['description'],
      starts: updates['starts'],
      ends: updates['ends'],
      eventDay: updates['eventDay'],
      location: updates['location'],
      university: updates['university'],
    );
    return result.fold(
      (_) => Result.ok(null),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }

  @override
  Future<Result<void>> deleteEvent(String id) async {
    return await _client.deleteEvent(id);
  }
}
