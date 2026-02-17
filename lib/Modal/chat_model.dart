import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatModel {
  final String id;
  final bool? lastMessageRead;
  final String? lastMassageSender;
  final List<String> participants;
  final List<String> activeParticipants;
  final List<String> typingUsers;
  final String? lastMessage;
  @JsonKey(
    fromJson: ChatModel.nullableTimestampFromJson,
    toJson: ChatModel.nullableTimestampToJson,
  )
  final DateTime? lastMessageTime;

  ChatModel({
    required this.id,
    required this.participants,
    this.activeParticipants = const [],
    this.lastMessage,
    this.lastMessageTime,
    this.lastMassageSender,
    this.lastMessageRead,
    this.typingUsers = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  static DateTime? nullableTimestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  static dynamic nullableTimestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
