import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:quiver/collection.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';

enum SupportedStateEventEnum {
  aliases,
  canonical_alias,
  create,
  join_rule,
  name,
  topic,
  avatar,
  encryption,
  power_levels,
  member,
  redaction,
  history_visibility,
  guest_access,
  tombstone,
}

class SupportedStateEventTypes {
  final aliases = 'm.room.aliases';
  final canonical_alias = 'm.room.canonical_alias';
  final create = 'm.room.create';
  final join_rule = 'm.room.join_rules';
  final name = 'm.room.name';
  final topic = 'm.room.topic';
  final avatar = 'm.room.avatar';
  final encryption = 'm.room.encryption';
  final power_levels = 'm.room.power_levels';
  final member = 'm.room.member';
  final redaction = 'm.room.redaction';
  final history_visibility = 'm.room.history_visibility';
  final guest_access = 'm.room.guest_access';
  final tombstone = 'm.room.tombstone';
}

typedef JsonFactory<T> = T Function(Map<String, dynamic>);

class SupportedStateEventUtil {
  static SupportedStateEventUtil _instance;

  final Map<SupportedStateEventEnum, String> _enumToEventType;
  final Map<String, SupportedStateEventEnum> _eventTypeToEnum;
  final Map<Type, JsonFactory> typeToJsonFactory;
  final List<String> allSupportedTypes;
  final SupportedStateEventTypes types;

  SupportedStateEventUtil._(
    this._enumToEventType,
    this._eventTypeToEnum,
    this.allSupportedTypes,
    this.types,
    this.typeToJsonFactory,
  );

  factory SupportedStateEventUtil() {
    if (_instance == null) {
      final biMap = BiMap<SupportedStateEventEnum, String>();
      final types = SupportedStateEventTypes();
      biMap[SupportedStateEventEnum.aliases] = types.aliases;
      biMap[SupportedStateEventEnum.canonical_alias] = types.canonical_alias;
      biMap[SupportedStateEventEnum.create] = types.create;
      biMap[SupportedStateEventEnum.join_rule] = types.join_rule;
      biMap[SupportedStateEventEnum.name] = types.name;
      biMap[SupportedStateEventEnum.topic] = types.topic;
      biMap[SupportedStateEventEnum.avatar] = types.avatar;
      biMap[SupportedStateEventEnum.encryption] = types.encryption;
      biMap[SupportedStateEventEnum.power_levels] = types.power_levels;
      biMap[SupportedStateEventEnum.member] = types.member;
      biMap[SupportedStateEventEnum.redaction] = types.redaction;
      biMap[SupportedStateEventEnum.history_visibility] = types.history_visibility;
      biMap[SupportedStateEventEnum.guest_access] = types.guest_access;
      biMap[SupportedStateEventEnum.tombstone] = types.tombstone;

      final factoryMap = Map<Type, JsonFactory>();
      for (final stateEventEnum in biMap.keys) {
        switch (stateEventEnum) {
          case SupportedStateEventEnum.aliases:
            factoryMap[AliasesContent] = (json) => AliasesContent.fromJson(json);
            break;
          case SupportedStateEventEnum.canonical_alias:
            factoryMap[CanonicalAliasContent] = (json) => CanonicalAliasContent.fromJson(json);
            break;
          case SupportedStateEventEnum.create:
            factoryMap[CreateContent] = (json) => CreateContent.fromJson(json);
            break;
          case SupportedStateEventEnum.join_rule:
            factoryMap[JoinRuleContent] = (json) => JoinRuleContent.fromJson(json);
            break;
          case SupportedStateEventEnum.name:
            factoryMap[NameContent] = (json) => NameContent.fromJson(json);
            break;
          case SupportedStateEventEnum.topic:
            factoryMap[TopicContent] = (json) => TopicContent.fromJson(json);
            break;
          case SupportedStateEventEnum.avatar:
            factoryMap[AvatarContent] = (json) => AvatarContent.fromJson(json);
            break;
          case SupportedStateEventEnum.encryption:
            factoryMap[EncryptionContent] = (json) => EncryptionContent.fromJson(json);
            break;
          case SupportedStateEventEnum.power_levels:
            factoryMap[PowerLevels] = (json) => PowerLevels.fromJson(json);
            break;
          case SupportedStateEventEnum.member:
            factoryMap[MemberContent] = (json) => MemberContent.fromJson(json);
            break;
          case SupportedStateEventEnum.redaction:
            factoryMap[RedactionContent] = (json) => RedactionContent.fromJson(json);
            break;
          case SupportedStateEventEnum.history_visibility:
            factoryMap[HistoryVisibilityContent] = (json) => HistoryVisibilityContent.fromJson(json);
            break;
          case SupportedStateEventEnum.guest_access:
            factoryMap[GuestAccessContent] = (json) => GuestAccessContent.fromJson(json);
            break;
          case SupportedStateEventEnum.tombstone:
            factoryMap[TombstoneContent] = (json) => TombstoneContent.fromJson(json);
            break;
        }
      }

      _instance = SupportedStateEventUtil._(
        Map.unmodifiable(biMap),
        Map.unmodifiable(biMap.inverse),
        List.unmodifiable(biMap.values),
        types,
        Map.unmodifiable(factoryMap),
      );
    }

    return _instance;
  }

  bool isSupported(String eventType) {
    return allSupportedTypes.contains(eventType);
  }

  StateEventBuilder<T> stateEventBuilderFrom<T>(RoomEvent roomEvent) {
    final factory = typeToJsonFactory[T];
    assert(factory != null);
    assert(roomEvent != null);
    return StateEventBuilder()
      ..roomEvent = roomEvent
      ..content = factory(roomEvent.content);
  }

  StateEvent<T> stateEventFrom<T>(RoomEvent roomEvent) {
    return stateEventBuilderFrom<T>(roomEvent).build();
  }

  String eventTypeFrom(SupportedStateEventEnum typeEnum) {
    return _enumToEventType[typeEnum];
  }

  SupportedStateEventEnum typeEnumFrom(String type) {
    return _eventTypeToEnum[type];
  }
}
