// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  id: json['id'] as String,
  participants:
      (json['participants'] as List<dynamic>).map((e) => e as String).toList(),
  activeParticipants:
      (json['activeParticipants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  lastMessage: json['lastMessage'] as String?,
  lastMessageTime: ChatModel.nullableTimestampFromJson(json['lastMessageTime']),
  lastMassageSender: json['lastMassageSender'] as String?,
  lastMessageRead: json['lastMessageRead'] as bool?,
  typingUsers:
      (json['typingUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  deletedForA: json['deletedForA'] as bool? ?? false,
  deletedForB: json['deletedForB'] as bool? ?? false,
  deletedForAAfter: ChatModel.nullableTimestampFromJson(
    json['deletedForAAfter'],
  ),
  deletedForBAfter: ChatModel.nullableTimestampFromJson(
    json['deletedForBAfter'],
  ),
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'id': instance.id,
  'lastMessageRead': instance.lastMessageRead,
  'lastMassageSender': instance.lastMassageSender,
  'participants': instance.participants,
  'activeParticipants': instance.activeParticipants,
  'typingUsers': instance.typingUsers,
  'lastMessage': instance.lastMessage,
  'deletedForA': instance.deletedForA,
  'deletedForB': instance.deletedForB,
  'deletedForAAfter': ChatModel.nullableTimestampToJson(
    instance.deletedForAAfter,
  ),
  'deletedForBAfter': ChatModel.nullableTimestampToJson(
    instance.deletedForBAfter,
  ),
  'lastMessageTime': ChatModel.nullableTimestampToJson(
    instance.lastMessageTime,
  ),
};
