import 'package:chat_app/Service/auth_service.dart';
import 'package:chat_app/UI/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthService authservice = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Text("Welcome", style: TextStyle(fontSize: 30)),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ElevatedButton(onPressed: () {}, child: Text("Chat")),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authservice.signOut();

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // Show error if logout fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
