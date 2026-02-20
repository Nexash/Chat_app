import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
  final DateTime timestamp;
  final bool read;
  final String type;
  final Map<String, String> reactions;
  final bool isEdited;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
    this.type = 'text',
    this.reactions = const {},
    this.isEdited = false,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromDocument(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MessageModel.fromJson(data);
  }

  static DateTime timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now();
  }

  static dynamic timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
