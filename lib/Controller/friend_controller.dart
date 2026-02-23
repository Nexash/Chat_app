import 'dart:developer';

import 'package:chat_app/Modal/user_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send friend request
  Future<void> sendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _firestore.collection('users').doc(targetUserId).set({
        'friendRequests': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true)); // ✅ creates field if missing
      log('✅ Friend request sent to $targetUserId');
    } catch (e) {
      log('❌ sendFriendRequest error: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String requesterId,
  }) async {
    final batch = _firestore.batch();

    // Add each other as friends
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayUnion([requesterId]),
      'friendRequests': FieldValue.arrayRemove([requesterId]),
    });
    batch.update(_firestore.collection('users').doc(requesterId), {
      'friends': FieldValue.arrayUnion([currentUserId]),
    });

    await batch.commit();
  }

  // Decline friend request
  Future<void> declineFriendRequest({
    required String currentUserId,
    required String requesterId,
  }) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([requesterId]),
    });
  }

  // Remove friend
  Future<void> removeFriend({
    required String currentUserId,
    required String friendId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayRemove([friendId]),
    });
    batch.update(_firestore.collection('users').doc(friendId), {
      'friends': FieldValue.arrayRemove([currentUserId]),
    });
    await batch.commit();
  }

  // Search users by name (exclude self)
  Future<List<UserModal>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.trim().toLowerCase();

    final snapshot =
        await _firestore
            .collection('users')
            .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
            .where('nameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .get();

    return snapshot.docs
        .map((doc) => UserModal.fromDocument(doc))
        .where((user) => user.uid != currentUserId)
        .toList();
  }

  // Get friend status between two users
  Future<String> getFriendStatus({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    final data = doc.data()!;
    final List friends = data['friends'] ?? [];
    final List requests = data['friendRequests'] ?? [];

    if (friends.contains(targetUserId)) return 'friends';
    if (requests.contains(targetUserId)) return 'incoming';

    // Check if we sent a request to them
    final targetDoc =
        await _firestore.collection('users').doc(targetUserId).get();
    final List targetRequests = targetDoc.data()?['friendRequests'] ?? [];
    if (targetRequests.contains(currentUserId)) return 'sent';

    return 'none';
  }
}
