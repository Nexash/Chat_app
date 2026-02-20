import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Service/claudinart_service.dart';
import 'package:chat_app/Service/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {
  static final ChatController _instance = ChatController._internal();
  factory ChatController() => _instance;
  ChatController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription> _firestoreSubscriptions = {};
  final Map<String, StreamController<List<MessageModel>>> _controllers = {};
  final Map<String, List<MessageModel>> _dataCache = {};
  final Map<String, DocumentSnapshot?> _lastMessageDoc = {};
  final Map<String, bool> _hasMore = {};

  bool hasMore(String chatId) => _hasMore[chatId] ?? true;
  final Map<String, Timer> _disposeTimers = {};

  Stream<List<MessageModel>> getMessages(String chatId) {
    if (_disposeTimers.containsKey(chatId)) {
      _disposeTimers[chatId]!.cancel();
      _disposeTimers.remove(chatId);
      log('[$chatId] Dispose timer cancelled — user re-entered.');
    }
    if (_controllers.containsKey(chatId)) {
      log('[$chatId] Returning existing stream.');

      return _controllers[chatId]!.stream;
    }

    log('[$chatId] Setting up new stream + Firestore listener.');

    final controller = StreamController<List<MessageModel>>.broadcast();
    _controllers[chatId] = controller;
    // subscription works as the active phone call between app and google server
    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
          final List<MessageModel> liveMessages =
              snapshot.docs
                  .map((doc) => MessageModel.fromDocument(doc))
                  .toList();

          _lastMessageDoc[chatId] ??=
              snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

          final List<MessageModel> existing = _dataCache[chatId] ?? [];
          final Set<String> existingIds = existing.map((m) => m.id).toSet();
          final Set<String> liveIds = liveMessages.map((m) => m.id).toSet();

          // if new message arrives
          final List<MessageModel> brandNew =
              liveMessages.where((m) => !existingIds.contains(m.id)).toList();

          // Messages already in cache, but their 'read' status might have changed
          final List<MessageModel> updatedExisting =
              existing.map((cached) {
                if (!liveIds.contains(cached.id))
                  return cached; // Older message, keep as is
                return liveMessages.firstWhere(
                  (m) => m.id == cached.id,
                ); // Latest 20, use server version
              }).toList();

          _dataCache[chatId] = [...brandNew, ...updatedExisting];

          log(
            '[$chatId] Firestore update → ${_dataCache[chatId]!.length} msgs in cache',
          );

          if (!controller.isClosed) {
            controller.add(_dataCache[chatId]!);
          }
        });

    _firestoreSubscriptions[chatId] = subscription;
    return controller.stream;
  }

  /// Fetches older messages and pushes the updated cache to the stream.
  Future<void> fetchMoreMessages(String chatId) async {
    if (!(_hasMore[chatId] ?? true)) {
      log('[$chatId] No more messages.');
      return;
    }

    final cursor = _lastMessageDoc[chatId];
    if (cursor == null) {
      log('[$chatId] Cursor not ready, skipping fetchMore.');
      return;
    }

    log('[$chatId] Fetching older messages...');

    final snapshot =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .startAfterDocument(cursor)
            .get();

    if (snapshot.docs.length < 20) {
      _hasMore[chatId] = false;
      log('[$chatId] Reached beginning of conversation.');
    }

    if (snapshot.docs.isNotEmpty) {
      _lastMessageDoc[chatId] = snapshot.docs.last;
    }

    final List<MessageModel> older =
        snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();

    // Deduplicate and append to the END (they are older)
    final List<MessageModel> existing = _dataCache[chatId] ?? [];
    final Set<String> existingIds = existing.map((m) => m.id).toSet();
    final List<MessageModel> newOnes =
        older.where((m) => !existingIds.contains(m.id)).toList();

    if (newOnes.isEmpty) {
      log('[$chatId] No new older messages after dedup.');
      // Still push so UI can hide the spinner and show "start of conversation"
      final controller = _controllers[chatId];
      if (controller != null && !controller.isClosed) {
        controller.add(_dataCache[chatId]!);
      }
      return;
    }

    _dataCache[chatId] = [...existing, ...newOnes];
    log(
      '[$chatId] After fetchMore → ${_dataCache[chatId]!.length} msgs in cache',
    );

    // KEY FIX: manually push updated cache so StreamBuilder rebuilds
    final controller = _controllers[chatId];
    if (controller != null && !controller.isClosed) {
      controller.add(_dataCache[chatId]!);
    }
  }

  List<MessageModel>? getCachedMessages(String chatId) => _dataCache[chatId];

  void scheduleDispose(String chatId) {
    _disposeTimers[chatId]?.cancel();

    _disposeTimers[chatId] = Timer(const Duration(hours: 24), () {
      log('[$chatId] 5-min timer fired — disposing chat.');
      disposeChat(chatId);
    });
    log('[$chatId] Dispose timer started (5 min).');
  }

  void disposeChat(String chatId) {
    _disposeTimers[chatId]?.cancel();
    _disposeTimers.remove(chatId);
    _firestoreSubscriptions[chatId]?.cancel();
    _firestoreSubscriptions.remove(chatId);
    _controllers[chatId]?.close();
    _controllers.remove(chatId);
    _dataCache.remove(chatId);
    _lastMessageDoc.remove(chatId);
    _hasMore.remove(chatId);
    log('[$chatId] Fully disposed.');
  }

  void disposeAll() {
    for (final chatId in _controllers.keys.toList()) {
      disposeChat(chatId);
    }
    log('All chats disposed.');
  }

  // Chat Room

  Future<String> getOrCreateChat(String uid1, String uid2) async {
    final ids = [uid1, uid2]..sort();
    final chatId = ids.join('_');
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

  // add image
  Future<String?> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final List activeUsers = chatDoc.data()?['activeParticipants'] ?? [];

      final List participants = chatId.split('_');
      final String recipientId =
          participants.first == senderId
              ? participants.last
              : participants.first;
      final bool isReadByRecipient = activeUsers.contains(recipientId);

      // Upload to Cloudinary
      final String imageUrl = await CloudinaryService.uploadImage(
        imageFile: imageFile,
        chatId: chatId,
      );

      // Save message to Firestore
      final messageRef =
          _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc();

      final newMessage = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        text: '',
        timestamp: DateTime.now(),
        read: isReadByRecipient,
        type: 'image',
        imageUrl: imageUrl,
      );

      final batch = _firestore.batch();
      batch.set(messageRef, newMessage.toJson());
      batch.set(_firestore.collection('chats').doc(chatId), {
        'lastMessage': '📷 Photo',
        'lastMessageTime': Timestamp.fromDate(newMessage.timestamp),
        'lastMessageRead': isReadByRecipient,
        'lastMassageSender': senderId,
        'participants': participants,
      }, SetOptions(merge: true));
      await batch.commit();

      // Send FCM notification if recipient not active
      if (!isReadByRecipient) {
        final recipientDoc =
            await _firestore.collection('users').doc(recipientId).get();
        final recipientToken = recipientDoc.data()?['fcmToken'];
        final senderDoc =
            await _firestore.collection('users').doc(senderId).get();
        final senderName = senderDoc.data()?['name'] ?? 'Someone';

        if (recipientToken != null) {
          await FCMService.sendNotification(
            receiverToken: recipientToken,
            title: senderName,
            body: '📷 Photo',
            senderId: senderId,
          );
        }
      }

      return newMessage.id;
    } catch (e) {
      log("Can't send image: $e");
      return null;
    }
  }

  //  Send Message

  Future<String?> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final List activeUsers = chatDoc.data()?['activeParticipants'] ?? [];

      final List participants = chatId.split('_');
      final String recipientId =
          participants.first == senderId
              ? participants.last
              : participants.first;
      final bool isReadByRecipient = activeUsers.contains(recipientId);

      final messageRef =
          _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc();

      final newMessage = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        read: isReadByRecipient,
        type: 'text',
      );

      final batch = _firestore.batch();
      batch.set(messageRef, newMessage.toJson());
      batch.set(_firestore.collection('chats').doc(chatId), {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(newMessage.timestamp),
        'lastMessageRead': isReadByRecipient,
        'lastMassageSender': senderId,
        'participants': participants,
      }, SetOptions(merge: true));

      await batch.commit();
      // ✅ Only notify if recipient is NOT active in chat
      if (!isReadByRecipient) {
        final recipientDoc =
            await _firestore.collection('users').doc(recipientId).get();
        final recipientToken = recipientDoc.data()?['fcmToken'];
        final senderDoc =
            await _firestore.collection('users').doc(senderId).get();
        final senderName = senderDoc.data()?['name'] ?? 'Someone';

        if (recipientToken != null) {
          await FCMService.sendNotification(
            receiverToken: recipientToken,
            title: senderName,
            body: text,
            senderId: senderId,
          );
        }
        log('🔔 activeUsers: $activeUsers');
        log('🔔 recipientId: $recipientId');
        log('🔔 isReadByRecipient: $isReadByRecipient');
      }
      return newMessage.id;
    } catch (e) {
      log("Cant send message: $e");
      return null;
    }
  }

  // edit message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true});

    log('[$chatId] Message $messageId edited.');
  }

  // delete message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Remove from local cache immediately so UI updates instantly
    final existing = _dataCache[chatId] ?? [];
    _dataCache[chatId] = existing.where((m) => m.id != messageId).toList();

    // Push updated cache to stream
    final controller = _controllers[chatId];
    if (controller != null && !controller.isClosed) {
      controller.add(_dataCache[chatId]!);
    }

    log('[$chatId] Message $messageId deleted.');
  }

  //typing controller
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers':
          isTyping
              ? FieldValue.arrayUnion([userId])
              : FieldValue.arrayRemove([userId]),
    });
  }

  // Reaction
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final List activeUsers = chatDoc.data()?['activeParticipants'] ?? [];

    final List participants = chatId.split('_');
    final String recipientId =
        participants.first == userId ? participants.last : participants.first;
    final bool isReadByRecipient = activeUsers.contains(recipientId);
    final batch = _firestore.batch();

    batch.update(
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId),
      {'reactions.$userId': emoji},
    );

    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': ' Reacted $emoji a message',
      'lastMassageSender': userId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageRead': isReadByRecipient,
      'participants': participants,
    });

    await batch.commit();
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }

  //Read Receipts

  Stream<DocumentSnapshot> getChatRoomData(String chatId) =>
      _firestore.collection('chats').doc(chatId).snapshots();

  Future<void> markAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageRead': true,
    });
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final query =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('read', isEqualTo: false)
            .where('senderId', isNotEqualTo: currentUserId)
            .get();

    if (query.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessageRead': true,
    });
    await batch.commit();
  }
}
