import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/widget/build_clickable_text.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';
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
  OverlayEntry? _emojiOverlay;

  void _showEmojiBar(BuildContext context) {
    _removeEmojiBar();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _emojiOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: widget.isMe ? null : position.dx + 8,
            right:
                widget.isMe
                    ? MediaQuery.of(context).size.width -
                        position.dx -
                        size.width +
                        8
                    : null,
            top: position.dy + size.height + 4,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _removeEmojiBar, // Dismiss on outside tap
                behavior: HitTestBehavior.translucent,
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
                      ...['👍', '❤️', '😂', '😮', '😢', '👀'].map((emoji) {
                        final isSelected =
                            widget.message.reactions[widget.currentUserId] ==
                            emoji;
                        return GestureDetector(
                          onTap: () async {
                            _removeEmojiBar();
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
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
                            margin: const EdgeInsets.symmetric(horizontal: 4),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_emojiOverlay!);
  }

  void _removeEmojiBar() {
    _emojiOverlay?.remove();
    _emojiOverlay = null;
  }

  void _showOptionsSheet(BuildContext context) {
    final hasReacted = widget.message.reactions.containsKey(
      widget.currentUserId,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              bool isDark = themeProvider.themeMode == ThemeMode.dark;
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          if (widget.isMe)
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color:
                                  isDark
                                      ? Colors.deepPurple[100]
                                      : const Color.fromARGB(
                                        255,
                                        254,
                                        217,
                                        202,
                                      ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Delete message',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () async {
                                  _removeEmojiBar();
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
                            ),

                          // Remove reaction
                          if (hasReacted)
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color:
                                  isDark
                                      ? Colors.deepPurple[100]
                                      : const Color.fromARGB(
                                        255,
                                        254,
                                        217,
                                        202,
                                      ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.grey,
                                ),
                                title: const Text('Remove reaction'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await ChatController().removeReaction(
                                    chatId: widget.chatId,
                                    messageId: widget.message.id,
                                    userId: widget.currentUserId,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
    ).then((_) {
      _removeEmojiBar();
    });
  }

  @override
  void dispose() {
    _removeEmojiBar();
    super.dispose();
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
                : EdgeInsets.only(bottom: 0),
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe) UserAvatar(url: photoUrl),
            Flexible(
              child: GestureDetector(
                onLongPress: () {
                  _showEmojiBar(context);
                  _showOptionsSheet(context);
                },

                child: Stack(
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
                          bottomRight: Radius.circular(widget.isMe ? 0 : 12),
                        ),
                        boxShadow: [
                          if (!widget.isMe)
                            BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            widget.isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          buildClickableText(widget.message.text, widget.isMe),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
              ),
            ),
            if (widget.isMe) UserAvatar(url: photoUrl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactionChips() {
    // Group reactions by emoji
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
