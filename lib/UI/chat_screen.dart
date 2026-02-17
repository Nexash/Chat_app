import 'dart:async';
import 'dart:developer';

import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/widget/chat_bubble.dart';
import 'package:chat_app/UI/widget/typing_indicator.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ScrollController _scrollController = ScrollController();

  String? chatId;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  late Stream<List<MessageModel>> _messageStream;

  bool _isLoadingMore = false;
  bool _userHasScrolled = false;
  Timer? _typingTimer;
  bool _otherIsTyping = false;

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

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_userHasScrolled) {
      setState(() => _userHasScrolled = true);
    }

    final pos = _scrollController.position;

    final bool canPaginate =
        _userHasScrolled &&
        pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _chatController.hasMore(chatId!);

    if (canPaginate) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await _chatController.fetchMoreMessages(chatId!);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _chatController.scheduleDispose(chatId!);
    _chatController.updateChatPresence(chatId!, currentUserId, false);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onTyping() {
    // Tell Firestore user is typing
    _chatController.setTyping(chatId!, currentUserId, true);

    // Reset the 1-second countdown on every keystroke
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _chatController.setTyping(chatId!, currentUserId, false);
    });
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
        log("✅ Message Sent: $chatId → $messageText");
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          // backgroundColor: Colors.deepPurple[400],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (isKeyboardVisible) {
                FocusManager.instance.primaryFocus?.unfocus();
                await Future.delayed(const Duration(milliseconds: 500));
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
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(5), // Adds 10 pixels of extra height
            child: SizedBox(), // Just empty space
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (chatId == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        padding: EdgeInsets.only(
                          bottom: keyboardHeight > 0 ? keyboardHeight : 0,
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final messages = snapshot.data ?? [];

                            if (messages.isNotEmpty) {
                              final latestMessage = messages.first;
                              if (latestMessage.senderId != currentUserId &&
                                  !latestMessage.read) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _chatController.markMessagesAsRead(
                                    chatId!,
                                    currentUserId,
                                  );
                                });
                              }
                            }

                            return Column(
                              children: [
                                if (!_chatController.hasMore(chatId!) &&
                                    messages.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    // child: Text(
                                    //   "Start of conversation",
                                    //   style: TextStyle(
                                    //     color: Colors.white70,
                                    //     fontSize: 12,
                                    //   ),
                                    // ),
                                  ),
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),

                                Expanded(
                                  child: Stack(
                                    children: [
                                      ListView.builder(
                                        controller: _scrollController,
                                        padding: EdgeInsets.only(
                                          bottom: _otherIsTyping ? 50 : 0,
                                        ),
                                        reverse: true,
                                        itemCount: messages.length,
                                        itemBuilder: (context, index) {
                                          return ChatBubble(
                                            message: messages[index],
                                            user: widget.user,
                                            currentUser: widget.currentUser,
                                            isMe:
                                                messages[index].senderId ==
                                                currentUserId,
                                            chatId: chatId!,
                                          );
                                        },
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: _chatController
                                              .getChatRoomData(chatId!),
                                          builder: (context, snap) {
                                            if (!snap.hasData) {
                                              return const SizedBox.shrink();
                                            }
                                            final data =
                                                snap.data!.data()
                                                    as Map<String, dynamic>?;
                                            final typingUsers =
                                                List<String>.from(
                                                  data?['typingUsers'] ?? [],
                                                );
                                            final isTyping = typingUsers.any(
                                              (id) => id != currentUserId,
                                            );

                                            // Update state so ListView padding reacts
                                            if (isTyping != _otherIsTyping) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    if (mounted) {
                                                      setState(
                                                        () =>
                                                            _otherIsTyping =
                                                                isTyping,
                                                      );
                                                    }
                                                  });
                                            }

                                            return isTyping
                                                ? const TypingIndicator()
                                                : const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 70),
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
                            onChanged: (_) => _onTyping(),
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
