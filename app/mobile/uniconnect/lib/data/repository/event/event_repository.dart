import '../../../domain/models/event/event.dart';
import '../../../utils/result.dart';

abstract class EventRepository {
  Future<Result<List<Event>>> getAllEvents({
    String? search,
    String? university,
    DateTime? eventDay,
    String? authorId,
    int page = 1,
    int limit = 10,
  });

  Future<Result<List<Event>>> getTrendingEvents({
    String? university,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 10,
  });

  Future<Result<List<Event>>> getPublicUserEvents(
    String userId, {
    int page = 1,
    int limit = 10,
  });

  Future<Result<List<Event>>> getMyEvents({
    int page = 1,
    int limit = 10,
  });

  Future<Result<Event>> getEventById(String id);

  Future<Result<void>> viewEvent(String id);

  Future<Result<void>> registerForEvent(String id);

  Future<Result<void>> cancelRegistration(String id);

  Future<Result<void>> createEvent(Event event);

  Future<Result<void>> updateEvent(String id, Map<String, dynamic> updates);

  Future<Result<void>> deleteEvent(String id);
}
