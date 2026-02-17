import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static User? user = FirebaseAuth.instance.currentUser;

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

      log("${userCredential.user}");
      return userCredential.user;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
