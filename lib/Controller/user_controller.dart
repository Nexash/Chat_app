import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Service/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  UserModal? currentUser;
  AuthService authService = AuthService();

  static Stream<List<UserModal>>? _persistentStream;

  void clearPersistentStream() {
    _persistentStream = null;
  }

  Future<void> saveUserData(User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? 'Unknown User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge preserves existing fields
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots();
  }

  Stream<List<UserModal>> getUsersExcluding(String currentUserId) {
    _persistentStream ??= getAllUsers().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModal.fromDocument(doc))
          .toList();
    });

    return _persistentStream!;
  }

  Stream<UserModal> getUserStream(String uid) {
    return _firestore
        .collection('users') // Make sure this matches your collection name
        .doc(uid)
        .snapshots()
        .map((doc) => UserModal.fromDocument(doc));
  }

  Future<void> fetchCurrentuser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastSeen'] is Timestamp) {
          data['lastSeen'] =
              (data['lastSeen'] as Timestamp).toDate().toIso8601String();
        } else {
          data['lastSeen'] = "";
        }

        currentUser = UserModal.fromJson(data);
      }
    }
  }
}
