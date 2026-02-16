import 'dart:developer';

import 'package:chat_app/Controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static User? user = FirebaseAuth.instance.currentUser;
  UserController userController = UserController();

  Future<User?> loginWithGoogle({bool forceAccountPicker = false}) async {
    try {
      if (forceAccountPicker) {
        await GoogleSignIn().signOut();
      }
      final googleAccount = await GoogleSignIn().signIn();

      final googleAuth = await googleAccount?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await userController.saveUserData(userCredential.user!);
      }
      log("${userCredential.user}");
      return userCredential.user;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Update user to offline before signing out
      await userController.updateOnlineStatus(currentUser.uid, false);
    }
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
