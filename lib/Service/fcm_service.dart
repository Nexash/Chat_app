import 'dart:developer';

import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';

class FCMService {
  static final Dio _dio = Dio();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init(BuildContext context) async {
    // 1. Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get Token & save to Firestore
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // 3. Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground: ${message.notification?.title}');
        // show local notification
      });

      // 4. Background tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNavigation(context, message);
      });

      // 5. Terminated tap
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNavigation(context, initialMessage);
      }
    }
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  static void _handleNavigation(
    BuildContext context,
    RemoteMessage message,
  ) async {
    String? type = message.data['type'];
    String? senderId = message.data['senderId'];
    if (type == 'chat' && senderId != null) {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      List<String> ids = [currentUserId, senderId];
      ids.sort();
      String chatId = ids.join("_");

      final senderDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();

      final senderUser = UserModal.fromDocument(senderDoc); // your UserModel

      final meDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

      final me = UserModal.fromDocument(meDoc);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatScreen(
                  user: senderUser,
                  chatId: chatId,
                  currentUser: me,
                  currentUserId: currentUserId,
                ),
          ),
        );
      }
    }
  }

  static Future<void> sendNotification({
    required String receiverToken,
    required String title,
    required String body,
    required String senderId,
  }) async {
    log('🔔 sendNotification called'); // ✅ add this
    log('🔔 receiver token: $receiverToken');
    try {
      final accessToken = await _getAccessToken();

      final response = await _dio.post(
        'https://fcm.googleapis.com/v1/projects/flutter-chat-app-ce89b/messages:send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: {
          "message": {
            "token": receiverToken,
            "notification": {"title": title, "body": body},
            "data": {"type": "chat", "senderId": senderId},
            "android": {
              "priority": "high",
              "notification": {"sound": "default"},
            },
          },
        },
      );

      if (response.statusCode == 200) {
        print('Notification sent ✅');
      } else {
        print('Notification failed: ${response.data}');
      }
    } on DioException catch (e) {
      print('Notification error: ${e.response?.data ?? e.message}');
    }
  }

  static Future<String> _getAccessToken() async {
    final serviceAccount = {
      "type": "service_account",
      "project_id": "flutter-chat-app-ce89b",
      "private_key_id": "bba02daf4d3a85e4a3a84307e06874a3bfab2dcd",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDsaDhVnGI4nWGP\nnikGVb5/ngUsT+7Tgk2AzutHO2gTG7L6fpNaj8/JcD5x9ruDe6AtlMx8GeZPxiR8\nDbGNzH5oLkpc3aierTSufMLxkLJQX9L10ap4SH68t/oZ0P58iS8LTO/E51QNhulY\nd+78XbiB/6lV7oIbCB+zXjvpuKX0TN75RZKFTSwcI4EPSrJH0wKrs6+lWIcpza3k\nLyBIU5+rJOyN8CMPb4xKUUdlYMIeyja+L2lHV1XGT721TX5JvtfRCcRKIv+zl2ne\n4a6zcAZPFzS4yGpsZBgMOy8ki5JorwLwS4I7tDVs2LVsvUBVEohcohnLM4YvPZIf\nG8IWtN5zAgMBAAECggEAU38f3oTkYBCeA6ad4MHqDZLXSuZUeNm92++5Q6hkwtL2\nrOiFzOecQQ5mz8OQSQkh8tdqPa68HJLkEfiYLHf8cXlgBFq5komkYLhp9f3gLOkb\nTn0mE2Ovd6IXMIUTTRL6zaf3y3jUxA5RXlDF1NaZMzkEKviZdUiyQZzX1l3EJ3tN\nIs03XRigNQcb5qP3UGc6uckaxvYPzs0ItIzfFZzVnhJoFSK3jSBsYj+AsyZoo8DZ\nYAcveSO7Dy5oH3YZmKpb8szDmf0+HnseVIQU1rIeXx7zNVJ8TV+ryRMLnIQJs2pm\nAqFXHS9AsWCCwTco3PhDB7ORXsxtqBC4tEBTOuZFEQKBgQD/cpXbtb24HG69iriI\nOTtj60K7eeCP4kEbwe935mpIxSLzZh7gQ4JyBnAAL9hA7jQ9l4AtqXir0dCL1z06\nhSZuY0V+Pl54mwuxgOaFxero8sneQfIvczA7TGbNy90L/vMQjEqjVEhOyY3FC+Np\n4G5nPSGnqsbKeIPZGlvjWJbQuQKBgQDs6xgMySr+e1bsLR98ezFnjWcBPd+yp7+g\nyuRzuL4SN+1P26PdNusg2W5hBsKl6AdKPhd/pxSOS6z6kfV9CbVN3bpLFLSn4Unl\nB8m1M3kuM6/o3sHzcMfoBaP/UVHgCUUa6coPuhsLYee+HWMtQx07z4WndrnnNNBB\nBUTbtbTaiwKBgQDx2SrIuWjFxyWRjqTnVEhGcZbcqKdTkoLSJOr0OdKm0v4kM6tH\n6KK4EiA4DRRRZTVQmv9gO/NjuWIZA8+UeDvKh3Jj8+i9hw2rIL8gKCIgKr21D/qb\nshMYEV3Duh+uG9NE944y1Lkg3vK6fGby9umQFPCoLafIShGKmsoklNs1AQKBgH97\nALXgiQHl3B+5J/gTUcImlAZXBMdc+//JLKQYBC5JaahOxx2BL4O9e2c5/ALJlyKb\nxokpniXzEmDBqRZe4u/DHzrHKW4sC1bxmdemms4BgeYL9tDHHsn6PwRi/WtPkZ+p\nrNBJk8PMKqZhqbvxIQnN4Fz7xYxjHqvd6e9PFsGBAoGAbnpGjjlEexZgOVoj3oyp\nVelMY8KoESytA2P884TxOoIoQ133U0UVhj/fvXjskyGcfvyWirJauJDycGbam7an\naWcCpUeyOrC/ygf3eDXXQdy9buAW1q5ZWAKG2NtLZt4rnihBLOki/kQtPcD2qlIY\n6LU8ceCxhHP6hfzoAkA6ixg=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@flutter-chat-app-ce89b.iam.gserviceaccount.com",
      "client_id": "102321936177594362349",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40flutter-chat-app-ce89b.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };

    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final client = await clientViaServiceAccount(credentials, [
      'https://www.googleapis.com/auth/firebase.messaging',
    ]);

    return client.credentials.accessToken.data;
  }
}
