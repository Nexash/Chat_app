import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/chat_media_screen.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrawerWidget extends StatefulWidget {
  final UserModal user;
  final String chatId;

  const DrawerWidget({super.key, required this.user, required this.chatId});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final bgColor =
        isDark
            ? Color.alphaBlend(
              themeProvider.seedColor.withValues(alpha: 0.5),
              Colors.white, // blend with dark base
            )
            : Color.alphaBlend(
              themeProvider.seedColor.withValues(alpha: 0.08),
              Colors.white, // blend with white base
            );
    return Drawer(
      backgroundColor: bgColor,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 10),
                  UserAvatar(
                    url: widget.user.photoUrl,
                    size: 22,
                    isonline: widget.user.isOnline,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _drawerTile(
            icon: Icons.photo_library_outlined,
            label: 'Photos',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatMediaScreen(chatId: widget.chatId),
                ),
              );
            },
          ),
          _drawerTile(
            icon: Icons.search,
            label: 'Search in Chat',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          ),
          onTap: onTap,
        ),
        Divider(color: Colors.grey),
      ],
    );
  }
}
