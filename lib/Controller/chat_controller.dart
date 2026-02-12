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

  // 2. Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    //when we send the data we will not have message id yet so we store and get the message id here
    //it makes the data ready to send using doc() and we have generated the message id
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final newMessage = MessageModel(
      id: messageRef.id, // message id is used here
      senderId: senderId,
      text: text,
      timestamp:
          DateTime.now(), // Local time for now, Firestore handles the rest
      read: false,
      type: 'text',
    );

    // This ensures BOTH the message and the lastMessage update at the exact same time
    WriteBatch batch = _firestore.batch();

    // as messageRef is just and empty storage with only message id here newmessage is stored in the message ref
    batch.set(messageRef, newMessage.toJson());

    batch.set(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(newMessage.timestamp),
      'participants': chatId.split('_'),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // 3. Get Messages Stream
  // This listens to the sub-collection and returns a list of MessageModel
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
            .asBroadcastStream();
    _streamCache[chatId] = stream;
    return stream;
  }
}
