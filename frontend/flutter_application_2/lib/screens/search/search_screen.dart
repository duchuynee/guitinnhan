import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';
import '../../widgets/feed_post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  bool _didLoad = false;
  bool _isLoading = true;
  String? _error;
  List<Post> _results = const [];
  String _lastQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _search();
    }
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _search(query: _lastQuery, showRefreshMessage: _lastQuery.isEmpty);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search({String? query, bool showRefreshMessage = false}) async {
    final session = SessionScope.of(context);
    final normalizedQuery = (query ?? _queryController.text).trim();

    setState(() {
      _isLoading = true;
      _error = null;
      _lastQuery = normalizedQuery;
    });

    try {
      final results = await session.api.searchPosts(
        session.requireToken(),
        search: normalizedQuery.isEmpty ? null : normalizedQuery,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });

      if (showRefreshMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danh sach bai viet da duoc cap nhat'),
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
      _results = _results
          .map((post) => post.id == postId ? updated : post)
          .toList(growable: false);
    });
    return updated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tim kiem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _search(query: _lastQuery),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _search(query: value),
                    decoration: InputDecoration(
                      hintText: 'Tim bai viet theo noi dung',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _search(),
                  child: const Text('Tim'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _search(query: _lastQuery),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _search(query: _lastQuery),
                  child: const Text('Thu lai'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 140),
          Center(
            child: Text(
              _lastQuery.isEmpty
                  ? 'Chua co bai viet nao de hien thi'
                  : 'Khong tim thay ket qua cho "$_lastQuery"',
            ),
          ),
        ],
      );
    }

    return ListView(
      children: _results
          .map(
            (post) => PostCard(
              key: ValueKey(post.id),
              post: post,
              onToggleLike: _toggleLike,
              onToggleSave: _toggleSave,
              onReport: _reportPost,
            ),
          )
          .toList(growable: false),
    );
  }
}
