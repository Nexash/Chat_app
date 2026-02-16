import 'dart:developer';

import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final UserModal user;
  final UserModal currentUser;
  const ChatScreen({super.key, required this.user, required this.currentUser});

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
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    widget.user.photoUrl.isNotEmpty ? userImage : null,
                child:
                    widget.user.photoUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
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
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              reverse: true,

                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageBubble(
                                  messages[index],
                                  messages[index].senderId == currentUserId,
                                  widget.user,
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

  Widget _buildMessageBubble(MessageModel message, bool isMe, UserModal user) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 5),
              child: CircleAvatar(
                radius: 16, // Slightly larger for the AppBar
                backgroundImage:
                    widget.user.photoUrl.isNotEmpty ? userImage : null,
                child:
                    widget.user.photoUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        )
                        : null,
              ),
            ),
          Flexible(
            child: Padding(
              padding:
                  isMe ? EdgeInsets.only(left: 32) : EdgeInsets.only(right: 32),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple[400] : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft:
                        isMe
                            ? const Radius.circular(12)
                            : const Radius.circular(0),
                    bottomRight:
                        isMe
                            ? const Radius.circular(0)
                            : const Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMessageTime(message.timestamp.toString()),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.done_all, size: 15),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    widget.currentUser.photoUrl.isNotEmpty
                        ? currentUserImage
                        : null,
                child:
                    widget.user.photoUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        )
                        : null,
              ),
            ),
        ],
      ),
    );
  }
}
