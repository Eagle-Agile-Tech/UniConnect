import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
abstract class Event with _$Event {
  factory Event({
    required String title,
    required String description,
    required DateTime starts,
    required DateTime ends,
    required String authorId,
    required DateTime eventDay,
    required String location,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
