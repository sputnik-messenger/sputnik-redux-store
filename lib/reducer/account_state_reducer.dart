import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:sputnik_redux_store/actions/account_state_actions.dart';
import 'package:built_collection/built_collection.dart';
import 'package:sputnik_redux_store/util/event_filter.dart';
import 'package:sputnik_redux_store/util/reactions_map_builder.dart';
import 'package:sputnik_redux_store/util/redeaction_util.dart';
import 'package:sputnik_redux_store/util/supported_state_event_util.dart';

class AccountStateReducer {
  static SputnikAppState onSycResponse(SputnikAppState state, OnSyncResponse action) {
    final userId = action.userId;
    final syncResponse = action.syncResponse;

    return state.rebuild((b) {
      b.accountSummaries.updateValue(userId, (v) => v.rebuild((b) => b.nextBatchSyncToken = syncResponse.next_batch));
      b.accountStates.updateValue(
          userId,
          (v) => v.rebuild((b) => b
            ..roomStates.update((b) => updateRoomStatesFromSyncResponse(b, syncResponse))
            ..roomSummaries.update((b) => updateRoomSummariesFromSyncResponse(b, syncResponse))));
    });
  }

  static SputnikAppState onAddRoomState(SputnikAppState state, AddRoomState action) {
    final userId = action.userId;
    final roomState = action.roomState;
    final roomId = roomState.roomId;

    return state.rebuild((stateBuilder) => stateBuilder.accountStates
        .updateValue(userId, (v) => v.rebuild((b) => b.roomStates.updateValue(roomId, (v) => roomState, ifAbsent: () => roomState))));
  }

  static SputnikAppState onUnloadRoomState(SputnikAppState state, UnloadRoomState action) {
    final userId = action.userId;
    final roomId = action.roomId;

    return state.rebuild(
      (stateBuilder) => stateBuilder.accountStates.updateValue(
        userId,
        (v) => v.rebuild((b) => b.roomStates.remove(roomId)),
      ),
    );
  }

  static SputnikAppState onRoomMessagesResponse(SputnikAppState state, OnRoomMessagesResponse action) {
    final userId = action.userId;
    final roomId = action.roomId;
    final messagesResponse = action.roomMessagesResponse;

    return state.rebuild((b) => b.accountStates.updateValue(
        userId,
        (v) => v.rebuild((b) {
              b.roomSummaries.updateValue(roomId, (v) => updateRoomSummaryFromRoomMessagesResponse(v, messagesResponse));
              if (b.roomStates[roomId] != null) {
                b.roomStates.updateValue(roomId, (v) => updateRoomStateFromRoomMessagesResponse(v, messagesResponse));
              }
            })));
  }

  static SputnikAppState onLoadedTimelineTailFromDb(SputnikAppState state, OnLoadedTimelineTailFromDb action) {
    final userId = action.userId;
    final roomId = action.roomId;
    final events = action.events;
    final members = action.members;

    final newEntries =
        events.where(EventFilter.onlyUserVisible).map((event) => TimelineEventState.fromEvent(event)).map((s) => MapEntry(s.event.event_id, s));
    return state.rebuild((b) => b.accountStates.updateValue(
        userId,
        (v) => v.rebuild((b) => b.roomStates.updateValue(
              roomId,
              (v) => v.rebuild((b) {
                b.timelineEventStates.addEntries(newEntries);
                b.roomMembers.addAll(members);
                updateReactionsFromEvents(b.reactions, events);
              }),
            ))));
  }

  static SputnikAppState onLoadedUserSummariesFromDb(SputnikAppState state, OnLoadedUserSummariesFromDb action) {
    final userId = action.userId;
    final roomId = action.roomId;
    final members = action.members;

    SputnikAppState newState = state;
    if (state.accountStates[userId].roomStates[roomId] != null) {
      newState = state.rebuild((b) => b.accountStates
          .updateValue(userId, (v) => v.rebuild((b) => b.roomStates.updateValue(roomId, (v) => v.rebuild((b) => b.roomMembers.addAll(members))))));
    }
    return newState;
  }

  static SputnikAppState onLoadedHeroUserSummariesFromDb(SputnikAppState state, OnLoadedHeroUserSummariesFromDb action) {
    final userId = action.userId;
    final heroes = action.heroes;

    SputnikAppState newState = state;
    if (state.accountStates[userId] != null) {
      newState = state.rebuild((b) => b.accountStates.updateValue(userId, (v) => v.rebuild((b) => b.heroes.addAll(heroes))));
    }
    return newState;
  }

  static SputnikAppState reduce(SputnikAppState oldState, dynamic action) {
    var newState = oldState;
    if (action is OnSyncResponse) {
      newState = onSycResponse(oldState, action);
    } else if (action is AddRoomState) {
      newState = onAddRoomState(oldState, action);
    } else if (action is UnloadRoomState) {
      newState = onUnloadRoomState(oldState, action);
    } else if (action is OnRoomMessagesResponse) {
      newState = onRoomMessagesResponse(oldState, action);
    } else if (action is OnLoadedTimelineTailFromDb) {
      newState = onLoadedTimelineTailFromDb(oldState, action);
    } else if (action is OnLoadedUserSummariesFromDb) {
      newState = onLoadedUserSummariesFromDb(oldState, action);
    } else if (action is OnLoadedHeroUserSummariesFromDb) {
      newState = onLoadedHeroUserSummariesFromDb(oldState, action);
    }
    return newState;
  }

  static int sortTimelineEventStates(TimelineEventState a, TimelineEventState b) {
    return b.event.origin_server_ts.compareTo(a.event.origin_server_ts);
  }

  static void updateRoomSummariesFromSyncResponse(MapBuilder<String, ExtendedRoomSummary> b, SyncResponse syncResponse) {
    syncResponse.rooms.join.forEach((roomId, room) {
      ExtendedRoomSummaryBuilder newRoomSummary = b[roomId]?.toBuilder();
      if (newRoomSummary == null) {
        newRoomSummary = ExtendedRoomSummaryBuilder()
          ..roomId = roomId
          ..roomStateValues = RoomStateValuesBuilder()
          ..roomSummary = room.summary;
      }

      updateRoomSummaryFromEvents(newRoomSummary, room.state.events, room.timeline.events, room.timeline.prev_batch,
          unreadNotificationCounts: room.unread_notifications, roomSummary: room.summary);

      b.updateValue(roomId, (v) => newRoomSummary.build(), ifAbsent: () => newRoomSummary.build());
    });
  }

  static void updateRoomStatesFromSyncResponse(MapBuilder<String, RoomState> b, SyncResponse syncResponse) {
    syncResponse.rooms.join.forEach((roomId, room) {
      if (b[roomId] != null) {
        b.updateValue(roomId, (v) => v.rebuild((b) => updateRoomStateFromEvents(b, room.state.events, room.timeline.events)));
      }
    });
  }

  static RoomState updateRoomStateFromRoomMessagesResponse(RoomState roomState, RoomMessagesResponse roomMessagesResponse) {
    final b = roomState.toBuilder();
    updateRoomStateFromEvents(b, roomMessagesResponse.state ?? const [], roomMessagesResponse.chunk);
    return b.build();
  }

  static ExtendedRoomSummary updateRoomSummaryFromRoomMessagesResponse(ExtendedRoomSummary roomSummary, RoomMessagesResponse roomMessagesResponse) {
    final b = roomSummary.toBuilder();
    updateRoomSummaryFromEvents(b, roomMessagesResponse.state ?? const [], roomMessagesResponse.chunk, roomMessagesResponse.end);
    return b.build();
  }

  static void updateRoomSummaryFromEvents(
    ExtendedRoomSummaryBuilder b,
    List<RoomEvent> state,
    List<RoomEvent> timeline,
    String previousBatchToken, {
    UnreadNotificationCounts unreadNotificationCounts,
    RoomSummary roomSummary,
  }) {
    b.previousBatchToken = previousBatchToken;

    if (unreadNotificationCounts != null) {
      b..unreadNotificationCounts = unreadNotificationCounts;
    }

    if (roomSummary != null) {
      if (b.roomSummary != null) {
        b.roomSummary = b.roomSummary.merge(roomSummary);
      } else {
        b.roomSummary = roomSummary;
      }
    }

    final newLastRelevant = timeline.lastWhere((e) => e.type == 'm.room.message', orElse: () => null);
    if (b.lastRelevantRoomEvent == null ||
        (newLastRelevant != null && newLastRelevant.origin_server_ts >= b.lastRelevantRoomEvent.origin_server_ts)) {
      b.lastRelevantRoomEvent = newLastRelevant;
    }

    final timelineStateEvents = timeline.where((e) => e.isStateEvent);

    b.roomStateValues.update((b) => updateRoomStateValues(b, state));
    b.roomStateValues.update((b) => updateRoomStateValues(b, timelineStateEvents));
  }

  static void updateRoomStateFromEvents(RoomStateBuilder b, Iterable<RoomEvent> state, Iterable<RoomEvent> timeline) {
    final mappedTimeline = timeline.where(EventFilter.onlyUserVisible).map((e) => TimelineEventState.fromEvent(e));

    b.timelineEventStates.addIterable(mappedTimeline, key: (TimelineEventState s) => s.event.event_id);
    for (RoomEvent redaction in timeline.where((e) => e.redacts != null)) {
      if (b.timelineEventStates[redaction.redacts] != null) {
        b.timelineEventStates.updateValue(
          redaction.redacts,
          (v) => v.rebuild((b) => b.event = RedactionUtil.redact(b.event, redaction)),
        );
      }
    }

    final mapBuilder = b.roomMembers;
    updateRoomMembersFromStateEvents(mapBuilder, state);
    updateRoomMembersFromStateEvents(mapBuilder, timeline.where((e) => e.isStateEvent));
    updateReactionsFromEvents(b.reactions, timeline);
  }

  static updateRoomMembersFromStateEvents(MapBuilder<String, UserSummary> members, Iterable<RoomEvent> state) {
    for (final memberEvent in state.where((e) => e.type == 'm.room.member')) {
      final eventTimestamp = memberEvent.origin_server_ts;

      final memberContent = MemberContent.fromJson(memberEvent.content);
      final userId = memberEvent.state_key;

      UserSummaryBuilder userSummaryBuilder = members[userId]?.toBuilder();
      if (userSummaryBuilder == null) {
        userSummaryBuilder = UserSummaryBuilder();
        userSummaryBuilder.userId = userId;
      }

      if (memberContent.displayname != null) {
        if (userSummaryBuilder.displayName?.timestamp == null || userSummaryBuilder.displayName.timestamp <= eventTimestamp) {
          userSummaryBuilder.displayName = TimestampedBuilder()
            ..value = memberContent.displayname
            ..timestamp = eventTimestamp;
        }
      }
      if (memberContent.avatar_url != null) {
        if (userSummaryBuilder.avatarUrl?.timestamp == null || userSummaryBuilder.avatarUrl.timestamp <= eventTimestamp) {
          userSummaryBuilder.avatarUrl = TimestampedBuilder()
            ..value = memberContent.avatar_url
            ..timestamp = eventTimestamp;
        }
      }

      final newUserSummary = userSummaryBuilder.build();
      members.updateValue(userId, (b) => newUserSummary, ifAbsent: () => newUserSummary);
    }
  }

  static updateReactionsFromEvents(MapBuilder<String, BuiltMap<String, BuiltList<RoomEvent>>> reactionMap, Iterable<RoomEvent> reactions) {
    ReactionsMapBuilder.update(reactionMap, reactions);
  }

  static void updateRoomStateValues(RoomStateValuesBuilder b, Iterable<RoomEvent> stateEvents) {
    final util = SupportedStateEventUtil();

    final supportedStateEvents = stateEvents.where((e) => util.isSupported(e.type));
    final stateMap = Map<String, RoomEvent>.fromIterable(supportedStateEvents, key: (e) => e.type);

    b.aliases = getLatestOf(b.aliases ?? null, stateMap[util.types.aliases], util);
    b.name = getLatestOf(b.name, stateMap[util.types.name], util);
    b.encryption = getLatestOf(b.encryption, stateMap[util.types.encryption], util);
    b.avatar = getLatestOf(b.avatar, stateMap[util.types.avatar], util);
    b.topic = getLatestOf(b.topic, stateMap[util.types.topic], util);
    b.joinRule = getLatestOf(b.joinRule, stateMap[util.types.join_rule], util);
    b.create = getLatestOf(b.create, stateMap[util.types.create], util);
    b.canonicalAlias = getLatestOf(b.canonicalAlias, stateMap[util.types.canonical_alias], util);
    b.powerLevels = getLatestOf(b.powerLevels, stateMap[util.types.power_levels], util);
    b.tombstone = getLatestOf(b.tombstone, stateMap[util.types.tombstone], util);
  }

  static StateEventBuilder<T> getLatestOf<T>(
    StateEventBuilder<T> current,
    RoomEvent candidate,
    SupportedStateEventUtil util,
  ) {
    StateEventBuilder<T> latest = null;
    if (candidate != null && (current?.roomEvent == null || candidate.origin_server_ts >= current.roomEvent.origin_server_ts)) {
      latest = util.stateEventBuilderFrom<T>(candidate);
    } else if (current?.roomEvent != null) { {
      latest = current;
    }}
    return latest;
  }
}
