import 'dart:developer';

import 'package:chat_app/Modal/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Stream<List<MessageModel>>> _streamCache = {};

  Future<String> getOrCreateChat(String uid1, String uid2) async {
    List<String> ids = [uid1, uid2];
    ids.sort();
    String chatId = ids.join("_");
    await _firestore.collection('chats').doc(chatId).set({
      'participants': ids,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId;
  }

  Future<void> updateChatPresence(
    String chatId,
    String userId,
    bool isEntering,
  ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'activeParticipants':
          isEntering
              ? FieldValue.arrayUnion([userId])
              : FieldValue.arrayRemove([userId]),
    });
  }

  // 2. Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final List activeUsers = chatDoc.data()?['activeParticipants'] ?? [];

    // Get the recipient ID (the one who isn't the sender)
    final List participants = chatId.split('_');
    final String recipientId =
        participants.first == senderId ? participants.last : participants.first;

    // Logic: If recipient is in activeUsers, message is ALREADY read
    bool isReadByRecipient = activeUsers.contains(recipientId);

    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final newMessage = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      read: isReadByRecipient, // 🔥 Use the check here
      type: 'text',
    );

    WriteBatch batch = _firestore.batch();
    batch.set(messageRef, newMessage.toJson());

    batch.set(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(newMessage.timestamp),
      'lastMessageRead':
          isReadByRecipient, // 🔥 Also update the notification dot status
      'lastMassageSender': senderId,
      'participants': participants,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    if (_streamCache.containsKey(chatId)) {
      log("Returning Cached Stream for: $chatId");
      return _streamCache[chatId]!;
    }
    log("Creating NEW Stream for: $chatId");
    final stream =
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => MessageModel.fromDocument(doc))
                  .toList();
            })
            // 🔥 ADD THIS PART HERE:
            .distinct((prev, next) {
              if (prev.length != next.length) return false;

              if (prev.isEmpty && next.isEmpty) return true;

              return prev.first.id == next.first.id;
            })
            .asBroadcastStream();
    _streamCache[chatId] = stream;
    return stream;
  }

  Stream<DocumentSnapshot> getChatRoomData(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  Future<void> markAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageRead': true,
    });
  }
}
