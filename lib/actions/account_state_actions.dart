
import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';

import 'sputnik_action.dart';


class AddRoomSummary extends SputnikAction {
  final String userId;
  final ExtendedRoomSummary roomSummary;

  AddRoomSummary(this.userId, this.roomSummary);
}

class AddRoomState extends SputnikAction {
  final String userId;
  final RoomState roomState;

  AddRoomState(this.userId, this.roomState);
}

class UnloadRoomState extends SputnikAction {
  final String userId;
  final String roomId;

  UnloadRoomState(this.userId, this.roomId);
}

class OnSyncResponse extends SputnikAction {
  final String userId;
  final SyncResponse syncResponse;

  OnSyncResponse(this.userId, this.syncResponse);
}

class OnRoomMessagesResponse extends SputnikAction {
  final String userId;
  final String roomId;
  final RoomMessagesResponse roomMessagesResponse;

  OnRoomMessagesResponse(
    this.userId,
    this.roomId,
    this.roomMessagesResponse,
  );
}

class OnLoadedTimelineTailFromDb extends SputnikAction {
  final String userId;
  final String roomId;
  final List<RoomEvent> events;
  final Map<String, UserSummary> members;

  OnLoadedTimelineTailFromDb(
    this.userId,
    this.roomId,
    this.events,
    this.members,
  );
}

class OnLoadedUserSummariesFromDb extends SputnikAction {
  final String userId;
  final String roomId;
  final Map<String, UserSummary> members;

  OnLoadedUserSummariesFromDb(
    this.userId,
    this.roomId,
    this.members,
  );
}

class OnLoadedHeroUserSummariesFromDb extends SputnikAction {
  final String userId;
  final Map<String, UserSummary> heroes;

  OnLoadedHeroUserSummariesFromDb(
    this.userId,
    this.heroes,
  );
}
