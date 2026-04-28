import 'package:flutter/material.dart';

import '../../models/user_summary.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.showFollowers,
  });

  final int userId;
  final String username;
  final bool showFollowers;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  bool _isLoading = true;
  String? _error;
  List<UserSummary> _users = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = widget.showFollowers
          ? await session.api.getUserFollowers(session.requireToken(), widget.userId)
          : await session.api.getUserFollowing(session.requireToken(), widget.userId);
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(UserSummary user) async {
    final session = SessionScope.of(context);
    try {
      if (user.isFollowing) {
        await session.api.unfollowUser(session.requireToken(), user.id);
      } else {
        await session.api.followUser(session.requireToken(), user.id);
      }
      if (!mounted) return;
      setState(() {
        _users = _users.map((u) {
          if (u.id != user.id) return u;
          final delta = user.isFollowing ? -1 : 1;
          return u.copyWith(
            isFollowing: !user.isFollowing,
            followersCount: (u.followersCount + delta).clamp(0, 999999),
          );
        }).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showFollowers
        ? 'Người theo dõi @${widget.username}'
        : '@${widget.username} đang theo dõi';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(widget.showFollowers ? 'Chưa có người theo dõi' : 'Chưa theo dõi ai'),
      );
    }

    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _UserRow(
        user: _users[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(
              userId: _users[i].id,
              initialUsername: _users[i].username,
            ),
          ),
        ),
        onToggleFollow: () => _toggleFollow(_users[i]),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap, required this.onToggleFollow});

  final UserSummary user;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final myId = SessionScope.of(context).currentUser?.id;
    final isMe = myId != null && myId == user.id;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
        child: user.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('@${user.username}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: isMe
          ? null
          : OutlinedButton(
              onPressed: onToggleFollow,
              style: OutlinedButton.styleFrom(
                backgroundColor: user.isFollowing ? Colors.grey[100] : Colors.blue,
                foregroundColor: user.isFollowing ? Colors.black : Colors.white,
                side: BorderSide(color: user.isFollowing ? Colors.grey : Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(user.isFollowing ? 'Đang theo dõi' : 'Theo dõi', style: const TextStyle(fontSize: 12)),
            ),
    );
  }
}
