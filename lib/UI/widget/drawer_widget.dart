import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/UI/widget/user_avatar.dart';
import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context, UserModal user) {
  return Drawer(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                SizedBox(width: 10),
                UserAvatar(
                  url: user.photoUrl,
                  size: 22,
                  isonline: user.isOnline,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    user.name,
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
        const Divider(),

        // Media Only
        ListTile(
          leading: const Icon(
            Icons.photo_library_outlined,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
          title: const Text(
            'Photos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          onTap: () {
            Navigator.pop(context); // close drawer
            // TODO: navigate to media screen
          },
        ),

        // Search in Chat
        ListTile(
          leading: const Icon(
            Icons.search,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
          title: const Text(
            'Search in Chat',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          onTap: () {
            Navigator.pop(context); // close drawer
            // TODO: show search bar
          },
        ),
      ],
    ),
  );
}
