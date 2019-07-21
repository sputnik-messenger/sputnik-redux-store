import 'package:matrix_rest_api/matrix_client_api_r0.dart';

class EventFilter {
  static bool onlyUserVisible(RoomEvent event) {
    return event.type != 'm.reaction' && event.redacts == null;
  }

  static bool isRelevant(RoomEvent event) {
    return event.type.startsWith('m.');
  }
}