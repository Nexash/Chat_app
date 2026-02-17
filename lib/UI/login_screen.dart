import 'package:chat_app/Controller/auth_controller.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthController authController = AuthController();
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF74ABE2), Color.fromARGB(255, 10, 21, 105)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Text(
                      "S P I L L ",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Center(
                    child: Text(
                      "S O M E ",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Center(
                    child: Text(
                      "T E A",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      authController.handleLogin(context);
                    },

                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  SizedBox(height: media.height * 0.05),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26, // Dims the screen slightly
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
