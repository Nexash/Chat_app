import 'dart:developer';

import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/widget/chat_bubble.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final UserModal user;
  final String chatId;
  final UserModal currentUser;
  final String currentUserId;
  const ChatScreen({
    super.key,
    required this.user,
    required this.chatId,
    required this.currentUser,

    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = ChatController();
  late ImageProvider userImage;
  late ImageProvider currentUserImage;

  String? chatId;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  late Stream<List<MessageModel>> _messageStream;

  final double _textFieldHeight = 0;

  @override
  void initState() {
    super.initState();
    List<String> ids = [currentUserId, widget.user.uid];
    ids.sort();
    chatId = ids.join("_");
    userImage =
        widget.user.photoUrl.isNotEmpty
            ? NetworkImage(widget.user.photoUrl)
            : const AssetImage('assets/default_user.png') as ImageProvider;

    currentUserImage =
        widget.currentUser.photoUrl.isNotEmpty
            ? NetworkImage(widget.currentUser.photoUrl)
            : const AssetImage('assets/default_user.png');

    _messageStream = _chatController.getMessages(chatId!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.markMessagesAsRead(chatId!, currentUserId);
    });
    _chatController.updateChatPresence(chatId!, currentUserId, true);
  }

  @override
  void dispose() {
    // Mark myself as inactive when I leave
    _chatController.updateChatPresence(chatId!, currentUserId, false);

    super.dispose();
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String messageText = _messageController.text.trim();

      _messageController.clear();

      try {
        await _chatController.sendMessage(
          chatId: chatId!,
          senderId: currentUserId,
          text: messageText,
        );
        log("✅ Message Sent Successfully to Chat: $chatId");
        log("Content: $messageText");
      } catch (e) {
        log(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.deepPurple[200],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple[400],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (isKeyboardVisible) {
                FocusManager.instance.primaryFocus?.unfocus();
                await Future.delayed(Duration(milliseconds: 500));
                if (context.mounted) Navigator.pop(context);
              } else {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                url: widget.user.photoUrl,
                size: 22,
                isonline: widget.user.isOnline,
              ),

              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (chatId == null)
                    Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 400),
                        curve:
                            Curves
                                .fastEaseInToSlowEaseOut, // Changed from bounceIn for smoother flow
                        padding: EdgeInsets.only(
                          bottom:
                              keyboardHeight > 0
                                  ? keyboardHeight + _textFieldHeight
                                  : 0,
                        ),
                        child: StreamBuilder<List<MessageModel>>(
                          stream: _messageStream,
                          initialData: _chatController.getCachedMessages(
                            chatId!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }

                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final messages = snapshot.data ?? [];

                            if (messages.isNotEmpty) {
                              log(
                                "Stream updated! Message count: ${snapshot.data!.length}",
                              );
                              log(
                                "Latest message read status: ${snapshot.data!.first.read}",
                              );
                              final latestMessage = messages.first;

                              if (latestMessage.senderId != currentUserId &&
                                  !latestMessage.read) {
                                _chatController.markMessagesAsRead(
                                  chatId!,
                                  currentUserId,
                                );
                              }
                            }
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              reverse: true,

                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return ChatBubble(
                                  message: messages[index],
                                  user: widget.user,
                                  currentUser: widget.currentUser,
                                  isMe:
                                      messages[index].senderId == currentUserId,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: 70),
                ],
              ),
            ),
            AnimatedPositioned(
              height: 70,
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastEaseInToSlowEaseOut,
              left: 0,
              right: 0,
              bottom: keyboardHeight,
              child: ClipRRect(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      top: BorderSide(color: Colors.transparent, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: TextField(
                            minLines: 1,
                            maxLines: 2,
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple[400],
                        child: IconButton(
                          onPressed: sendMessage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
