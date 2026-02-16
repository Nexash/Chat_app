import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_modal.g.dart';

//to generate -> dart run build_runner build
//if there is conflict -> dart run build_runner build --delete-conflicting-outputs
// to watch -> dart run build_runner watch
@JsonSerializable()
class UserModal {
  final String uid;
  final String name;
  final String email;
  final bool isOnline;
  final String lastSeen;
  final String photoUrl;
  UserModal({
    required this.uid,
    required this.name,
    required this.email,
    this.isOnline = false,
    this.photoUrl = "",
    this.lastSeen = "",
  });
  factory UserModal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = doc.id; // Add document ID
    if (data['lastSeen'] is Timestamp) {
      data['lastSeen'] = (data['lastSeen'] as Timestamp).toDate().toString();
    } else {
      data['lastSeen'] = "";
    }
    return UserModal.fromJson(data);
  }
  factory UserModal.fromJson(Map<String, dynamic> json) =>
      _$UserModalFromJson(json);
  Map<String, dynamic> toJson() => _$UserModalToJson(this);
}
