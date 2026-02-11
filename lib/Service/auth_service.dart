import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Out (from both Firebase and Google)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
