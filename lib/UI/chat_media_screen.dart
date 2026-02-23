import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatMediaScreen extends StatelessWidget {
  final String chatId;
  const ChatMediaScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media', style: TextStyle(color: Colors.white)),

        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .where('type', isEqualTo: 'image')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final mediaDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final deleted = data['deleted'] as bool? ?? false;
                final imageUrl = data['imageUrl'] as String? ?? '';

                return !deleted && imageUrl.isNotEmpty;
              }).toList();

          if (mediaDocs.isEmpty) {
            return const Center(
              child: Text(
                'No media shared yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: mediaDocs.length,
            itemBuilder: (context, index) {
              final imageUrl = mediaDocs[index]['imageUrl'] as String?;
              if (imageUrl == null || imageUrl.isEmpty) return const SizedBox();

              return GestureDetector(
                onTap: () {
                  // Full screen viewer
                  showDialog(
                    context: context,
                    builder:
                        (_) => Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: EdgeInsets.zero,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: InteractiveViewer(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                  );
                },
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
