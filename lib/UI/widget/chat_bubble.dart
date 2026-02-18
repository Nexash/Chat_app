import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/widget/build_clickable_text.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final UserModal user;
  final UserModal currentUser;
  final bool isMe;
  final String chatId;
  final String currentUserId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.user,
    required this.currentUser,
    required this.isMe,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showEmojiBar = false;
  ChatController chatController = ChatController();
  final TextEditingController _messageController = TextEditingController();

  void _toggleEmojiBar() {
    setState(() => _showEmojiBar = !_showEmojiBar);
  }

  void _showEditBox(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      builder:
          (context) => Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Edit message",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            padding: const EdgeInsets.all(12),
                            splashRadius: 28,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                onPressed: () async {
                                  try {
                                    await chatController.editMessage(
                                      chatId: widget.chatId,
                                      messageId: widget.message.id,
                                      newText: _messageController.text,
                                    );
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    debugPrint("Error editing: $e");
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Failed to edit message",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
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
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      routeSettings: const RouteSettings(name: 'options'),
      builder:
          (context) => Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (widget.isMe)
                          _buildOptionBtn(
                            icon: Icons.edit_note,
                            label: "Edit",
                            color: Colors.black87,
                            onTap: () {
                              _messageController.text = widget.message.text;
                              _messageController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: _messageController.text.length,
                                ),
                              );
                              Navigator.pop(context);
                              _showEditBox(context);
                            },
                          ),
                        _buildOptionBtn(
                          icon: Icons.copy,
                          label: "Copy",
                          color: Colors.black87,
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.message.text),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Copied to clipboard"),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(
                                    right: 20,
                                    left: 20,
                                    bottom:
                                        MediaQuery.of(context).size.height *
                                        0.07,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (widget.isMe)
                          _buildOptionBtn(
                            icon: Icons.delete_outline,
                            label: "Delete",
                            color: Colors.black87,
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                await ChatController().deleteMessage(
                                  chatId: widget.chatId,
                                  messageId: widget.message.id,
                                );
                              } catch (e) {
                                debugPrint("Delete failed: $e");
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showEmojiBar = false;
        });
      }
    });
  }

  Widget _buildOptionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String photoUrl =
        widget.isMe ? widget.currentUser.photoUrl : widget.user.photoUrl;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding:
            widget.message.reactions.isNotEmpty
                ? const EdgeInsets.only(bottom: 8.0)
                : EdgeInsets.zero,
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe) UserAvatar(url: photoUrl),
            Flexible(
              child: GestureDetector(
                onLongPress: () {
                  _toggleEmojiBar();
                  // _showOptionsSheet(context);
                },
                child: Column(
                  crossAxisAlignment:
                      widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.isMe
                                    ? const Color.fromARGB(207, 126, 87, 194)
                                    : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
                              bottomRight: Radius.circular(
                                widget.isMe ? 0 : 12,
                              ),
                            ),
                            boxShadow: [
                              if (!widget.isMe)
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                widget.isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              buildClickableText(
                                widget.message.text,
                                widget.isMe,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.message.isEdited)
                                    const Icon(
                                      Icons.edit,
                                      size: 10,
                                      color: Colors.white70,
                                    ),
                                  if (widget.message.isEdited)
                                    const SizedBox(width: 5),
                                  Text(
                                    formatMessageTime(
                                      widget.message.timestamp.toString(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          widget.isMe
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                  if (widget.isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 15,
                                      color:
                                          widget.message.read
                                              ? Colors.blue
                                              : Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Reaction chips (positioned below message)
                        if (widget.message.reactions.isNotEmpty)
                          Positioned(
                            bottom: -10,
                            right: widget.isMe ? 5 : null,
                            left: widget.isMe ? null : 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Wrap(
                                spacing: 4,
                                children: _buildReactionChips(),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Inline emoji selector (scrolls with message)
                    if (_showEmojiBar)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...['👍', '❤️', '😂', '😮', '😢', '👀'].map((
                                emoji,
                              ) {
                                final isSelected =
                                    widget.message.reactions[widget
                                        .currentUserId] ==
                                    emoji;
                                return GestureDetector(
                                  onTap: () async {
                                    setState(() => _showEmojiBar = false);
                                    if (isSelected) {
                                      await ChatController().removeReaction(
                                        chatId: widget.chatId,
                                        messageId: widget.message.id,
                                        userId: widget.currentUserId,
                                      );
                                    } else {
                                      await ChatController().addReaction(
                                        chatId: widget.chatId,
                                        messageId: widget.message.id,
                                        userId: widget.currentUserId,
                                        emoji: emoji,
                                      );
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.deepPurple[100]
                                              : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _showEmojiBar = false);
                                  _showOptionsSheet(context);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.more_horiz, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactionChips() {
    final Map<String, List<String>> grouped = {};
    widget.message.reactions.forEach((userId, emoji) {
      grouped.putIfAbsent(emoji, () => []).add(userId);
    });

    return grouped.entries.map((entry) {
      final emoji = entry.key;
      final userIds = entry.value;
      final count = userIds.length;
      final isCurrentUser = userIds.contains(widget.currentUserId);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.deepPurple[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border:
              isCurrentUser
                  ? Border.all(color: Colors.deepPurple, width: 1.5)
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 1) ...[
              const SizedBox(width: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.deepPurple : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }
}
