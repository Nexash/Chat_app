import 'dart:developer';

import 'package:chat_app/FCM/fcm_handler.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/HomeScreen.dart';
import 'package:chat_app/firebase_options.dart';
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
      builder:
          (context, themeProvider, _) => MaterialApp(
            themeMode: themeProvider.themeMode,

            // ✅ Light theme (only once)
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: themeProvider.seedColor,
                secondary: themeProvider.seedColor.withValues(alpha: 0.7),
                surface: Colors.white,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: themeProvider.seedColor,
                foregroundColor: Colors.white,
              ),
              useMaterial3: true,
            ),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: themeProvider.seedColor,
                secondary: themeProvider.seedColor.withValues(alpha: 0.7),
                surface: const Color(0xFF2C2C2C),
                onPrimary: Colors.white,
                onSurface: Colors.white,
                // ✅ These two fix the bottom sheet and dialog backgrounds
                surfaceContainer: const Color(0xFF2C2C2C),
                surfaceContainerHigh: const Color(0xFF3A3A3A),
                surfaceContainerHighest: const Color(0xFF3A3A3A),
              ),
              scaffoldBackgroundColor: const Color(0xFF2C2C2C),
              appBarTheme: AppBarTheme(
                backgroundColor: themeProvider.seedColor,
                foregroundColor: Colors.white,
              ),

              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF2C2C2C),
                surfaceTintColor: Colors.transparent,
                modalBackgroundColor: Color(0xFF2C2C2C),
              ),

              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF2C2C2C),
                surfaceTintColor: Colors.transparent,
              ),
              cardColor: const Color(0xFF3A3A3A),
              useMaterial3: true,
            ),

            home: const HomeScreen(),
          ),
    );
  }
}
