import '../../../domain/models/event/event.dart';
import '../../../utils/result.dart';

abstract class EventRepository{
  Future<Result<List<Event>>> getEvents(String userId);
}