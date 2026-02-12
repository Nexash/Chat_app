import 'dart:developer';

import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final UserModal user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = ChatController();
  final UserController _userController = UserController();
  String? chatId;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  late Stream<List<MessageModel>> _messageStream;

  @override
  void initState() {
    super.initState();
    List<String> ids = [currentUserId, widget.user.uid];
    ids.sort();
    chatId = ids.join("_");
    _loadCurrentUser();
    _messageStream = _chatController.getMessages(chatId!);
  }

  void _loadCurrentUser() async {
    await _userController.fetchCurrentuser();
    if (mounted) {
      setState(() {}); // Redraw the screen once we have your photo
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.deepPurple[200],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple[400],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20, // Slightly larger for the AppBar
                backgroundImage:
                    (widget.user.photoUrl.isNotEmpty)
                        ? NetworkImage(widget.user.photoUrl)
                        : null,
                child:
                    (widget.user.photoUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
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
        body: Column(
          children: [
            if (chatId == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _messageStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    final messages = snapshot.data ?? [];
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                          messages[index],
                          messages[index].senderId == currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 3,
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
                    SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 10,
                          top: 10,
                          bottom: 10,
                        ),
                      ),
                      padding: EdgeInsets.only(left: 5),

                      onPressed: () {
                        sendMessage();
                      },
                      icon: Icon(
                        Icons.send,
                        size: 25,
                        color: Colors.deepPurple[400],
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ),
            ),

            // SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final String? myUrl = _userController.currentUser?.photoUrl;
    final String theirUrl = widget.user.photoUrl;
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
                radius: 16,
                backgroundImage:
                    (theirUrl.isNotEmpty) ? NetworkImage(theirUrl) : null,
                child:
                    (theirUrl.isEmpty)
                        ? const Icon(Icons.person, size: 18)
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
                    Text(
                      formatMessageTime(message.timestamp.toString()),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
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
                    (myUrl != null && myUrl.isNotEmpty)
                        ? NetworkImage(myUrl)
                        : null,
                child:
                    (myUrl == null || myUrl.isEmpty)
                        ? const Icon(Icons.person, size: 18)
                        : null,
              ),
            ),
        ],
      ),
    );
  }
}
