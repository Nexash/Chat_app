import 'package:chat_app/Controller/friend_controller.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendRequestsSection extends StatelessWidget {
  final String currentUserId;
  final FriendController friendController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FriendRequestsSection({
    super.key,
    required this.currentUserId,
    required this.friendController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final List<String> requestIds = List<String>.from(
          data?['friendRequests'] ?? [],
        );

        if (requestIds.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 0),
              child: Text(
                'Friend Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: requestIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future:
                      _firestore
                          .collection('users')
                          .doc(requestIds[index])
                          .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const ListTile(
                        leading: CircleAvatar(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Loading...'),
                      );
                    }
                    final user = UserModal.fromDocument(userSnap.data!);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.photoUrl),
                      ),
                      title: Text(user.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await friendController.acceptFriendRequest(
                                currentUserId: currentUserId,
                                requesterId: user.uid,
                              );
                            },
                            child: const Text('Accept'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await friendController.declineFriendRequest(
                                currentUserId: currentUserId,
                                requesterId: user.uid,
                              );
                            },
                            child: const Text(
                              'Decline',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            // const Divider(),
          ],
        );
      },
    );
  }
}
