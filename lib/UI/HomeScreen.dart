import 'package:chat_app/Controller/auth_controller.dart';
import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/widget/user_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AuthController authController = AuthController();
  UserController userController = UserController();
  ChatController chatController = ChatController();

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
              authController.logout(context);
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

                        return UserTile(
                          user: user,
                          chatController: chatController,
                          userController: userController,
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
    );
  }
}
