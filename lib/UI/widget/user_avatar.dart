import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String url;
  final double size;
  final bool? isonline;
  const UserAvatar({
    super.key,
    required this.url,
    this.size = 20,
    this.isonline,
  });

  @override
  Widget build(BuildContext contex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Stack(
        children: [
          CircleAvatar(
            radius: size,
            backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
            child: url.isEmpty ? const Icon(Icons.person, size: 14) : null,
          ),
          if (isonline != null) _buildOnlineIndicator(isonline!),
        ],
      ),
    );
  }

  Widget _buildOnlineIndicator(bool isOnline) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
