import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/chat_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/chat_screen.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserTile extends StatefulWidget {
  final UserModal user;
  final ChatController chatController;
  final UserController userController;

  const UserTile({
    super.key,
    required this.user,
    required this.chatController,
    required this.userController,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late String chatId;

  @override
  void initState() {
    super.initState();
    List<String> ids = [currentUserId, widget.user.uid];
    ids.sort();
    chatId = ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.chatController.getChatRoomData(chatId),
        builder: (context, snapshot) {
          String lastMsg = "Tap to Chat";
          bool isUnread = false;
          String senderName = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            data['id'] = snapshot.data!.id;
            final chat = ChatModel.fromJson(data);

            if (chat.lastMassageSender == currentUserId) {
              senderName = "You: ";
            } else if (chat.lastMassageSender == widget.user.uid) {
              senderName = "${widget.user.name.split(" ").first}: ";
            }

            isUnread =
                !(chat.lastMessageRead ?? true) &&
                chat.lastMassageSender != currentUserId;
            lastMsg = data['lastMessage'] ?? "Tap to chat";
          }

          return ListTile(
            tileColor: Colors.deepPurple[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            leading: UserAvatar(
              url: widget.user.photoUrl,
              size: 25,
              isonline: widget.user.isOnline,
            ),

            title: Text(
              widget.user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "$senderName$lastMsg",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? Colors.black : Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                ),
                _buildOnlineStatus(),
              ],
            ),
            onTap: () => _handleTap(context, currentUserId),
          );
        },
      ),
    );
  }

  Widget _buildOnlineStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.user.isOnline)
          const Text("Active ")
        else
          Text(formatLastSeen(DateTime.parse(widget.user.lastSeen))),
        // Container(
        //   width: 12,
        //   height: 12,
        //   decoration: BoxDecoration(
        //     color: widget.user.isOnline ? Colors.green : Colors.grey,
        //     shape: BoxShape.circle,
        //     border: Border.all(color: Colors.white, width: 2),
        //   ),
        // ),
      ],
    );
  }

  void _handleTap(BuildContext context, String currentUserId) async {
    UserModal? me = widget.userController.currentUser;
    if (me == null) {
      await widget.userController.fetchCurrentuser();
      me = widget.userController.currentUser;
    }

    if (context.mounted && me != null) {
      List<String> ids = [me.uid, widget.user.uid];
      ids.sort();
      String chatId = ids.join("_");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                user: widget.user,
                chatId: chatId,
                currentUser: me!,
                currentUserId: me.uid,
              ),
        ),
      );
    }
  }
}
