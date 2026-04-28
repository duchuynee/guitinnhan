import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../models/profile.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';
import '../post/post_detail_screen.dart';
import 'follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId, this.initialUsername});

  final int userId;
  final String? initialUsername;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isFollowLoading = false;
  String? _error;
  ProfileBundle? _bundle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final session = SessionScope.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final json = await session.api.getUserProfile(session.requireToken(), widget.userId);
      final data = json['data'] as Map<String, dynamic>? ?? json;
      final bundle = ProfileBundle.fromJson(data);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
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

  Future<void> _toggleFollow() async {
    final bundle = _bundle;
    if (bundle == null || _isFollowLoading) return;

    final session = SessionScope.of(context);
    setState(() => _isFollowLoading = true);

    try {
      if (bundle.profile.isFollowing) {
        await session.api.unfollowUser(session.requireToken(), widget.userId);
      } else {
        await session.api.followUser(session.requireToken(), widget.userId);
      }
      if (!mounted) return;
      await _loadProfile();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  void _openFollowList({required bool showFollowers}) {
    final bundle = _bundle;
    if (bundle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: widget.userId,
          username: bundle.profile.username,
          showFollowers: showFollowers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _bundle?.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile != null ? '@${profile.username}' : (widget.initialUsername != null ? '@${widget.initialUsername}' : 'Hồ sơ')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
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
            ElevatedButton(onPressed: _loadProfile, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final bundle = _bundle!;
    final profile = bundle.profile;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profile.avatarUrl.isNotEmpty ? NetworkImage(profile.avatarUrl) : null,
              child: profile.avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('${profile.stats.postsCount}', 'Bài viết'),
                      GestureDetector(
                        onTap: () => _openFollowList(showFollowers: true),
                        child: _buildStat('${profile.stats.followersCount}', 'Người theo dõi'),
                      ),
                      GestureDetector(
                        onTap: () => _openFollowList(showFollowers: false),
                        child: _buildStat('${profile.stats.followingCount}', 'Đang theo dõi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!profile.isMe)
                    SizedBox(
                      width: double.infinity,
                      child: _isFollowLoading
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: profile.isFollowing ? Colors.grey[100] : Colors.blue,
                                foregroundColor: profile.isFollowing ? Colors.black : Colors.white,
                                side: BorderSide(color: profile.isFollowing ? Colors.grey : Colors.blue),
                              ),
                              child: Text(profile.isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text('@${profile.username}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(profile.bio),
        ],
        if ((profile.location ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(profile.location!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
        ],
        if ((profile.website ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.link, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
            Text(profile.website!, style: const TextStyle(color: Colors.blue, fontSize: 13)),
          ]),
        ],
        const SizedBox(height: 24),
        if (bundle.postsPreview.isNotEmpty) ...[
          const Text('Bài viết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          _buildPostGrid(bundle.postsPreview),
        ] else
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Chưa có bài viết nào'),
          )),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildPostGrid(List<Post> posts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final post = posts[i];
        final url = post.imageUrl;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          ),
          child: Container(
            color: Colors.grey[200],
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null && url.isNotEmpty)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  )
                else
                  Container(
                    color: Colors.grey[100],
                    alignment: Alignment.center,
                    child: const Icon(Icons.article_outlined, color: Colors.grey, size: 28),
                  ),
                if (url == null || url.isEmpty)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
