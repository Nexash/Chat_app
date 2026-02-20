import 'dart:developer';

import 'package:chat_app/FCM/fcm_handler.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/HomeScreen.dart';
import 'package:chat_app/UI/login_screen.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    log("✅ dotenv loaded");
    log("CLOUD NAME: ${dotenv.env['CLOUDINARY_CLOUD_NAME']}");
    log("PRESET: ${dotenv.env['CLOUDINARY_UPLOAD_PRESET']}");
  } catch (e) {
    log("❌ dotenv error: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Hive.initFlutter();
  await Hive.openBox('theme');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          // LIGHT THEME
          theme: ThemeData(
            cardColor: Colors.deepPurple[100],
            scaffoldBackgroundColor: Colors.deepPurple[100],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.deepPurple[400],
              foregroundColor: Colors.white,
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: const Color.fromARGB(245, 179, 157, 219),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          // DARK THEME
          darkTheme: ThemeData(
            cardColor: const Color.fromARGB(255, 254, 217, 202),
            scaffoldBackgroundColor: const Color(0xFFB6CEB4),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF254F22),
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: const Color.fromARGB(255, 159, 205, 154),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const HomeScreen();
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
