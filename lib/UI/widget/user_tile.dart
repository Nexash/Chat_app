import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/friend_controller.dart';
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
  OverlayEntry? _overlayEntry;
  @override
  void initState() {
    super.initState();
    List<String> ids = [currentUserId, widget.user.uid];
    ids.sort();
    chatId = ids.join("_");
  }

  void _showOverlayMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder:
          (_) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay, // ✅ tap outside to dismiss
            child: Stack(
              children: [
                Positioned(
                  top: position.dy + size.height / 2,
                  left: position.dx + 200,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _overlayOption(
                            icon: Icons.person_remove,
                            label: 'Unfriend',
                            color: Colors.red,

                            onTap: () {
                              _removeOverlay();
                              _showUnfriendDialog(context);
                            },
                          ),
                          const Divider(height: 1),
                          _overlayOption(
                            icon: Icons.delete_outline,
                            label: 'Delete Chat',
                            color: Colors.red,
                            onTap: () async {
                              _removeOverlay();
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Delete Chat'),
                                      content: Text(
                                        'Delete your chat with ${widget.user.name}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                try {
                                  await widget.chatController.deleteChat(
                                    chatId: chatId,
                                    currentUserId: currentUserId,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                          // ✅ easy to add more options here later
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showUnfriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(widget.user.name),
            content: Text('Remove ${widget.user.name} from friends?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await FriendController().removeFriend(
                      currentUserId: currentUserId,
                      friendId: widget.user.uid,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to unfriend: $e')),
                      );
                    }
                  }
                },
                child: const Text(
                  'Unfriend',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _overlayOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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

          return Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ), // 👈 bottom only
              ),
            ),
            child: ListTile(
              tileColor: Colors.transparent,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                // side: const BorderSide(color: Colors.grey, width: 1),
              ),
              // contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              leading: UserAvatar(
                url: widget.user.photoUrl,
                size: 25,
                isonline: widget.user.isOnline,
              ),

              title: Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              onLongPress: () => _showOverlayMenu(context),
            ),
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
