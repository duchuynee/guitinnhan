import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../models/story.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';
import '../../widgets/feed_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.refreshToken,
    required this.onOpenSearch,
    required this.onOpenNotifications,
  });

  final int refreshToken;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _error;
  List<Story> _stories = const [];
  List<Post> _posts = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadFeed();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadFeed(showRefreshMessage: true);
    }
  }

  Future<void> _loadFeed({bool showRefreshMessage = false}) async {
    final session = SessionScope.of(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final feed = await session.api.getFeed(session.requireToken());
      if (!mounted) {
        return;
      }

      setState(() {
        _stories = feed.stories;
        _posts = feed.posts;
        _isLoading = false;
      });

      if (showRefreshMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed da duoc cap nhat'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  Future<Post> _toggleLike(Post post) {
    final session = SessionScope.of(context);
    final future = post.isLiked
        ? session.api.unlikePost(session.requireToken(), post.id)
        : session.api.likePost(session.requireToken(), post.id);
    return _replacePost(post.id, future);
  }

  Future<Post> _toggleSave(Post post) {
    final session = SessionScope.of(context);
    final future = post.isSaved
        ? session.api.unsavePost(session.requireToken(), post.id)
        : session.api.savePost(session.requireToken(), post.id);
    return _replacePost(post.id, future);
  }

  Future<void> _reportPost(Post post, String reason) async {
    final session = SessionScope.of(context);
    await session.api.reportPost(
      session.requireToken(),
      post.id,
      reason: reason,
    );
  }

  Future<Post> _replacePost(int postId, Future<Post> future) async {
    final updated = await future;
    if (!mounted) {
      return updated;
    }

    setState(() {
      _posts = _posts
          .map((post) => post.id == postId ? updated : post)
          .toList(growable: false);
    });

    return updated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mini Social',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: widget.onOpenSearch,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: widget.onOpenNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 140),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFeed,
                  child: const Text('Thu lai'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    final caption = story.caption.isEmpty ? story.userName : story.caption;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Story: $caption')),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.pink, Colors.orange],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(story.userAvatar),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          story.userName,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        if (_posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Chua co bai viet nao trong feed')),
          ),
        ..._posts.map(
          (post) => PostCard(
            key: ValueKey(post.id),
            post: post,
            onToggleLike: _toggleLike,
            onToggleSave: _toggleSave,
            onReport: _reportPost,
          ),
        ),
      ],
    );
  }
}
