import 'package:chat_app/Controller/auth_controller.dart';
import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/Service/fcm_service.dart';
import 'package:chat_app/UI/add_friend_screen.dart';
import 'package:chat_app/UI/widget/user_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AuthController authController = AuthController();
  UserController userController = UserController();
  ChatController chatController = ChatController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    FCMService.init(context);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "SPILL - SOME - TEA",
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream:
                _firestore.collection('users').doc(currentUserId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final List requests = data?['friendRequests'] ?? [];
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddFriendScreen(
                                  currentUserId: currentUserId,
                                ),
                          ),
                        ),
                  ),
                  if (requests.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          Selector<ThemeProvider, ThemeMode>(
            selector: (_, provider) => provider.themeMode,
            builder: (context, currentTheme, child) {
              return IconButton(
                icon: Icon(
                  // Change icon based on current theme
                  currentTheme == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  final provider = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );
                  provider.toggleTheme(provider.themeMode == ThemeMode.light);
                },
              );
            },
          ),
          IconButton(
            iconSize: 22,
            onPressed: () {
              userController.clearPersistentStream();
              authController.logout(context);
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width,

                    child: StreamBuilder<DocumentSnapshot>(
                      stream:
                          _firestore
                              .collection('users')
                              .doc(currentUserId)
                              .snapshots(),
                      builder: (context, userSnapshot) {
                        final data =
                            userSnapshot.data?.data() as Map<String, dynamic>?;
                        final List<String> friends = List<String>.from(
                          data?['friends'] ?? [],
                        );

                        if (friends.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No friends yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Tap + to add friends',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return StreamBuilder<List<UserModal>>(
                          stream: userController.getFriendsStream(
                            friends,
                          ), // 👈 new method
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text("No friends found"),
                              );
                            }

                            final users = snapshot.data!;
                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                return UserTile(
                                  user: users[index],
                                  chatController: chatController,
                                  userController: userController,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.person_add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
