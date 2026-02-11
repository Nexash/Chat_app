// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// // Google Sign-In Service Class
// class GoogleSignInService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   static bool isInitialize = false;
//   static Future<void> initSignIn() async {
//     if (!isInitialize) {
//       await _googleSignIn.initialize(
//         serverClientId:
//             '1010391577811-m14bfhl639pvvf0nqqq0qra51p11uthr.apps.googleusercontent.com',
//       );
//     }
//     isInitialize = true;
//   }

//   static Future<UserCredential?> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         print('User cancelled sign-in');
//         return null;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );

//       // Try to save to Firestore with error handling
//       final User? user = userCredential.user;
//       if (user != null) {
//         try {
//           final userDoc = FirebaseFirestore.instance
//               .collection('users')
//               .doc(user.uid);

//           final docSnapshot = await userDoc.get();

//           if (!docSnapshot.exists) {
//             await userDoc.set({
//               'uid': user.uid,
//               'name': user.displayName ?? '',
//               'email': user.email ?? '',
//               'photoURL': user.photoURL ?? '',
//               'provider': 'google',
//               'createdAt': FieldValue.serverTimestamp(),
//             });
//             print('✅ User saved to Firestore');
//           }
//         } on FirebaseException catch (e) {
//           // Firestore error - but user is still authenticated!
//           print('⚠️ Firestore error (user still signed in): ${e.code}');
//           if (e.code == 'unavailable') {
//             print(
//               'Firestore is unavailable. User data not saved but login successful.',
//             );
//           }
//           // Don't throw - allow sign-in to succeed even if Firestore fails
//         }
//       }

//       return userCredential;
//     } catch (e) {
//       print('Error signing in: $e');
//       rethrow;
//     }
//   }

//   // Sign out
//   static Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//       await _auth.signOut();
//     } catch (e) {
//       print('Error signing out: $e');
//       rethrow;
//     }
//   }

//   // Get current user
//   static User? getCurrentUser() {
//     return _auth.currentUser;
//   }
// }
