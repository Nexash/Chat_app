import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/message_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/widget/build_clickable_text.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final UserModal user;
  final UserModal currentUser;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.user,
    required this.currentUser,
    required this.isMe,
  });

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
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple[400] : Colors.white,
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
          if (isMe) UserAvatar(url: photoUrl),
        ],
      ),
    );
  }
}
