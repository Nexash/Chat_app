import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/widget/build_clickable_text.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final UserModal user;
  final UserModal currentUser;
  final bool isMe;
  final String chatId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.user,
    required this.currentUser,
    required this.isMe,
    required this.chatId,
  });

  void _showOptions(BuildContext context) {
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
                    // Small drag handle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        color:
                            isDark
                                ? Colors.deepPurple[100]
                                : Color.fromARGB(255, 254, 217, 202),
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
                            Navigator.pop(context); // close bottom sheet
                            await ChatController().deleteMessage(
                              chatId: chatId,
                              messageId: message.id,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String photoUrl = isMe ? currentUser.photoUrl : user.photoUrl;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) UserAvatar(url: photoUrl),
          Flexible(
            child: GestureDetector(
              onLongPress: isMe ? () => _showOptions(context) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isMe
                          ? const Color.fromARGB(207, 126, 87, 194)
                          : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12),
                  ),
                  boxShadow: [
                    if (!isMe) BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    buildClickableText(message.text, isMe),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMessageTime(message.timestamp.toString()),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 15,
                            color: message.read ? Colors.blue : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) UserAvatar(url: photoUrl),
        ],
      ),
    );
  }
}
