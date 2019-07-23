import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';

class EventFilter {
  static bool onlyUserVisible(RoomEvent event) {
    return event.type != 'm.reaction' && event.redacts == null;
  }

  static bool isRelevant(RoomEvent event) {
    return event.type.startsWith('m.');
  }

  static bool isReaction(RoomEvent event) {
    return event.type == 'm.reaction';
  }

  static bool isValidReaction(ReactionEvent reactionEvent) {
    return  reactionEvent.relatesTo?.event_id != null &&
        reactionEvent.relatesTo?.key != null;
  }

  static bool isRedacted(RoomEvent event) {
    return event.unsigned.containsKey('redacted_because');
  }
}
