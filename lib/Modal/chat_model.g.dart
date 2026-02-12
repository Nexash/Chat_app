// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  id: json['id'] as String,
  participants:
      (json['participants'] as List<dynamic>).map((e) => e as String).toList(),
  lastMessage: json['lastMessage'] as String?,
  lastMessageTime: ChatModel.nullableTimestampFromJson(json['lastMessageTime']),
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'id': instance.id,
  'participants': instance.participants,
  'lastMessage': instance.lastMessage,
  'lastMessageTime': ChatModel.nullableTimestampToJson(
    instance.lastMessageTime,
  ),
};
