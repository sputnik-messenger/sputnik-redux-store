import 'package:built_collection/built_collection.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:matrix_rest_api/matrix_client_api_r0.dart';

import 'event_filter.dart';

class ReactionsMapBuilder {
  static TimelineAndReactions build(Iterable<RoomEvent> timeline) {
    final eventMap = MapBuilder<String, TimelineEventState>();
    final reactionEvents = List<RoomEvent>();

    for (final event in timeline) {
      if (EventFilter.isReaction(event)) {
        reactionEvents.add(event);
      } else {
        eventMap[event.event_id] = TimelineEventState.fromEvent(event);
      }
    }
    return TimelineAndReactions(eventMap, putReactions(ReactionsBuilder(), reactionEvents));
  }

  static ReactionsBuilder putReactions(ReactionsBuilder b, Iterable<RoomEvent> timeline) {
    final reactions = timeline
        .where(EventFilter.isReaction)
        .where((e) => !EventFilter.isRedacted(e))
        .map((e) => ReactionEvent.fromRoomEvent(e))
        .where(EventFilter.isValidReaction);
    return Reactions.putReactions(b, reactions);
  }
}

class TimelineAndReactions {
  final MapBuilder<String, TimelineEventState> timeline;
  final ReactionsBuilder reactions;

  TimelineAndReactions(this.timeline, this.reactions);
}
