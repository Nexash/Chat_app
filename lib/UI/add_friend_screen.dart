import 'dart:async';
import 'dart:developer';

import 'package:chat_app/Controller/friend_controller.dart';
import 'package:chat_app/Modal/user_modal.dart';
import 'package:chat_app/Provider/theme_provider.dart';
import 'package:chat_app/UI/widget/friend_request.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddFriendScreen extends StatefulWidget {
  final String currentUserId;
  const AddFriendScreen({super.key, required this.currentUserId});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendController _friendController = FriendController();
  List<UserModal> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _search(query.trim().toLowerCase()); // 👈 lowercase before searching
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await _friendController.searchUsers(
      query: query,
      currentUserId: widget.currentUserId,
    );
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

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
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Add Friends'),
        leading: IconButton(
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            await Future.delayed(Duration(milliseconds: 200));
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          FriendRequestsSection(
            currentUserId: widget.currentUserId,
            friendController: _friendController,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.black,
                  ), // ✅ unfocused border
                ),
                hintText: 'Search by name...',
                hintStyle: TextStyle(
                  color: const Color.fromARGB(255, 44, 41, 41),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.black),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return _UserSearchTile(
                    user: user,
                    currentUserId: widget.currentUserId,
                    friendController: _friendController,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UserSearchTile extends StatefulWidget {
  final UserModal user;
  final String currentUserId;
  final FriendController friendController;

  const _UserSearchTile({
    required this.user,
    required this.currentUserId,
    required this.friendController,
  });

  @override
  State<_UserSearchTile> createState() => _UserSearchTileState();
}

class _UserSearchTileState extends State<_UserSearchTile> {
  String _status = 'none'; // none | sent | incoming | friends
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await widget.friendController.getFriendStatus(
      currentUserId: widget.currentUserId,
      targetUserId: widget.user.uid,
    );
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.user.photoUrl),
      ),
      title: Text(widget.user.name),
      trailing:
          _loading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : _buildActionButton(),
    );
  }

  Widget _buildActionButton() {
    switch (_status) {
      case 'friends':
        return const Chip(label: Text('Friends ✓'));
      case 'sent':
        return const Chip(label: Text('Requested'));
      case 'incoming':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                await widget.friendController.acceptFriendRequest(
                  currentUserId: widget.currentUserId,
                  requesterId: widget.user.uid,
                );
                setState(() => _status = 'friends');
              },
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () async {
                await widget.friendController.declineFriendRequest(
                  currentUserId: widget.currentUserId,
                  requesterId: widget.user.uid,
                );
                setState(() => _status = 'none');
              },
              child: const Text('Decline'),
            ),
          ],
        );
      default:
        return ElevatedButton(
          onPressed: () async {
            try {
              await widget.friendController.sendFriendRequest(
                currentUserId: widget.currentUserId,
                targetUserId: widget.user.uid,
              );
              setState(() => _status = 'sent');
              if (!mounted) return;
            } catch (e) {
              log('e.toString()');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: const Text('Add Friend'),
        );
    }
  }
}
