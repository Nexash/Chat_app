import 'package:chat_app/Controller/chat_controller.dart';
import 'package:chat_app/Controller/user_controller.dart';
import 'package:chat_app/Service/auth_service.dart';
import 'package:chat_app/UI/HomeScreen.dart';
import 'package:chat_app/UI/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  AuthService authService = AuthService();
  UserController userController = UserController();

  void handleLogin(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      User? user = await authService.loginWithGoogle(forceAccountPicker: true);
      if (context.mounted) Navigator.of(context).pop();
      if (user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Spill some tea.."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;

      // Handle error UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error, Try again later!!!"),

          // Text("Error: $e"),
          backgroundColor: const Color.fromARGB(255, 228, 102, 93),
        ),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      ChatController().disposeAll();
      if (currentUser != null) {
        await userController.updateOnlineStatus(currentUser.uid, false);

        authService.signOut();
      }

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
}
