import 'package:built_collection/built_collection.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:matrix_rest_api/matrix_client_api_r0.dart';

class ReactionsMapBuilder {
  static TimelineAndReactions build(Iterable<RoomEvent> timeline) {
    final eventMap = MapBuilder<String, TimelineEventState>();
    final reactionsMap = MapBuilder<String, MapBuilder<String, ListBuilder<RoomEvent>>>();

    for (final event in timeline) {
      if (event.type == 'm.reaction') {
        final relatesTo = event.content['m.relates_to'];
        if (relatesTo != null) {
          final toEventId = relatesTo['event_id'];
          final key = relatesTo['key'];
          if (toEventId != null && key != null) {
            final reactionsByKey = reactionsMap.putIfAbsent(toEventId, () => MapBuilder<String, ListBuilder<RoomEvent>>());
            final reactions = reactionsByKey.putIfAbsent(key, () => ListBuilder<RoomEvent>());
            reactions.add(event);
          }
        }
      } else {
        eventMap[event.event_id] = TimelineEventState.fromEvent(event);
      }
    }

    final reactionsMapBuilder = reactionsMap.build().map((k, v) => MapEntry(k, v.build().map((k, v) => MapEntry(k, v.build())))).toBuilder();

    return TimelineAndReactions(eventMap, reactionsMapBuilder);
  }

  static void update(MapBuilder<String, BuiltMap<String, BuiltList<RoomEvent>>> mapBuilder, Iterable<RoomEvent> timeline) {
    for (final event in timeline) {
      if (event.type == 'm.reaction') {
        final relatesTo = event.content['m.relates_to'];
        if (relatesTo != null) {
          final toEventId = relatesTo['event_id'];
          final key = relatesTo['key'];
          if (toEventId != null && key != null) {
            mapBuilder.updateValue(
                toEventId,
                (v) => v.rebuild(
                      (b) => b.updateValue(key, (v) => v.contains(event) ? v : v.rebuild((b) => b.add(event)),
                          ifAbsent: () => BuiltList<RoomEvent>.from([event])),
                    ),
                ifAbsent: () => BuiltMap<String, BuiltList<RoomEvent>>.build((b) => b[key] = BuiltList<RoomEvent>.from([event])));
          }
        }
      }
    }
  }
}

class TimelineAndReactions {
  final MapBuilder<String, TimelineEventState> timeline;
  final MapBuilder<String, BuiltMap<String, BuiltList<RoomEvent>>> reactionsMap;

  TimelineAndReactions(this.timeline, this.reactionsMap);
}
