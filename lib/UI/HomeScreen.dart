import 'dart:developer';

import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Helper/format_message_time.dart';
import 'package:chat_app/Modal/chat_model.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Service/auth_service.dart';
import 'package:chat_app/UI/chat_screen.dart';
import 'package:chat_app/UI/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AuthService authService = AuthService();
  UserController userController = UserController();
  ChatController chatController = ChatController();

  Future<void> logout() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userController = UserController();
        await userController.updateOnlineStatus(currentUser.uid, false);
      }

      await authService.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      userController.updateOnlineStatus(uid, isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: Colors.deepPurple[200],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[400],
        title: Text(
          "SPILL - SOME - TEA",
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        actions: [
          IconButton(
            iconSize: 22,
            onPressed: () {
              logout();
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text("Users", style: TextStyle(fontSize: 20)),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width,

                child: StreamBuilder<List<UserModal>>(
                  stream: userController.getUsersExcluding(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Cant load Users"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data ?? [];

                    if (users.isEmpty) {
                      return Center(child: Text("No Users found"));
                    }

                    return ListView.builder(
                      // padding: const EdgeInsets.all(8),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return _buildUserTile(user);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModal user) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    List<String> ids = [currentUserId, user.uid];

    ids.sort();
    String chatId = ids.join("_");
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: chatController.getChatRoomData(chatId),
        builder: (context, snapshot) {
          String lastMsg = "Tap to Chat";
          bool isUnread = false;
          String senderName = "";
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;

            data['id'] = snapshot.data!.id;
            final chat = ChatModel.fromJson(data);
            log(
              "DEBUG: Chat with ${user.name} | Read: ${chat.lastMessageRead} | Sender: ${chat.lastMassageSender} | Me: $currentUserId",
            );
            // Determine who sent the last message
            if (chat.lastMassageSender == currentUserId) {
              senderName = "You: ";
            } else if (chat.lastMassageSender == user.uid) {
              senderName = user.name.split(" ").first;
            } else {
              senderName = ""; // Default if no messages yet
            }
            isUnread =
                !(chat.lastMessageRead ?? true) &&
                chat.lastMassageSender != currentUserId;
            lastMsg = data['lastMessage'] ?? "Tap to chat";
          }

          return ListTile(
            tileColor: Colors.deepPurple[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage:
                      user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                  child: user.photoUrl.isEmpty ? Icon(Icons.person) : null,
                ),
                //if want to show online in the profile
                // _buildOnlineIndicator(user.isOnline),
              ],
            ),
            title: Text(
              user.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: SizedBox(
                    width: 150,
                    child: Text(
                      "$senderName: $lastMsg",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                        color: const Color.fromARGB(255, 52, 51, 51),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                user.isOnline
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 50, child: Text("Active")),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                user.isOnline
                                    ? const Color.fromARGB(255, 3, 203, 16)
                                    : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            formatLastSeen(DateTime.parse(user.lastSeen)),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                user.isOnline
                                    ? const Color.fromARGB(255, 3, 203, 16)
                                    : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            onTap: () async {
              UserModal? me = userController.currentUser;
              if (me == null) {
                await userController.fetchCurrentuser();
                me = userController.currentUser;
              }
              if (context.mounted && me != null) {
                List<String> ids = [me.uid, user.uid];
                ids.sort();
                String chatId = ids.join("_");

                // 2. Mark as read in the background (Don't 'await' this)
                // This ensures the dot disappears immediately without slowing down navigation
                chatController.markAsRead(chatId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          user: user,
                          currentUser: me!,
                        ), // Pass user data!
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // Widget _buildOnlineIndicator(bool isOnline) {
  //   return Positioned(
  //     right: 0,
  //     bottom: 0,
  //     child: Container(
  //       width: 12,
  //       height: 12,
  //       decoration: BoxDecoration(
  //         color: isOnline ? const Color.fromARGB(255, 3, 203, 16) : Colors.grey,
  //         shape: BoxShape.circle,
  //         border: Border.all(color: Colors.white, width: 2),
  //       ),
  //     ),
  //   );
  // }
}
