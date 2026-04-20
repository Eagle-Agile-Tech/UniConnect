import 'package:flutter_riverpod/legacy.dart';

import '../../domain/models/event/event.dart';

final selectedEventProvider = StateProvider<Event?>((ref) => null);