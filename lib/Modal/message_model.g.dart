// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  senderId: json['senderId'] as String,
  text: json['text'] as String,
  timestamp: MessageModel.timestampFromJson(json['timestamp']),
  read: json['read'] as bool? ?? false,
  type: json['type'] as String? ?? 'text',
  reactions:
      (json['reactions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'text': instance.text,
      'timestamp': MessageModel.timestampToJson(instance.timestamp),
      'read': instance.read,
      'type': instance.type,
      'reactions': instance.reactions,
    };
