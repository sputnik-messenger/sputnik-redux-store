import 'package:matrix_rest_api/matrix_client_api_r0.dart';

class RedactionUtil {
  static RoomEvent redact(RoomEvent roomEvent, RoomEvent redaction) {
    final map = roomEvent.toJson();
    map.putIfAbsent('unsigned', () => <String, dynamic>{});
    map['content'] = const <String, dynamic>{};
    map['unsigned']['redacted_because'] = redaction.toJson();
    return RoomEvent.fromJson(map);
  }
}
