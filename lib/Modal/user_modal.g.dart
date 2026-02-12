// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_modal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModal _$UserModalFromJson(Map<String, dynamic> json) => UserModal(
  uid: json['uid'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  isOnline: json['isOnline'] as bool? ?? false,
  photoUrl: json['photoUrl'] as String? ?? "",
  lastSeen: json['lastSeen'] as String? ?? "",
);

Map<String, dynamic> _$UserModalToJson(UserModal instance) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'email': instance.email,
  'isOnline': instance.isOnline,
  'lastSeen': instance.lastSeen,
  'photoUrl': instance.photoUrl,
};
