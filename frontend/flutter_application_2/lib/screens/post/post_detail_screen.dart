import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../models/post.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';
import '../profile/user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;
  bool _isSending = false;
  String? _error;
  Post? _post;
  List<Comment> _comments = const [];

  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPost();
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final session = SessionScope.of(context);
    setState(() { _isLoadingPost = true; _error = null; });
    try {
      final json = await session.api.getPost(session.requireToken(), widget.postId);
      final data = json['data'] as Map<String, dynamic>? ?? json;
      if (!mounted) return;
      setState(() {
        _post = Post.fromJson(data);
        _isLoadingPost = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _isLoadingPost = false; });
    }
  }

  Future<void> _loadComments() async {
    final session = SessionScope.of(context);
    setState(() => _isLoadingComments = true);
    try {
      final comments = await session.api.getComments(session.requireToken(), widget.postId, perPage: 50);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _isLoadingComments = false; });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final session = SessionScope.of(context);
    setState(() => _isSending = true);

    try {
      final json = await session.api.addComment(session.requireToken(), widget.postId, text);
      if (!mounted) return;

      _commentController.clear();
      final commentData = (json['data'] as Map<String, dynamic>?)?['comment'];
      final postData   = (json['data'] as Map<String, dynamic>?)?['post'];

      setState(() {
        if (commentData != null) {
          _comments = [Comment.fromJson(commentData as Map<String, dynamic>), ..._comments];
        }
        if (postData != null) {
          _post = Post.fromJson(postData as Map<String, dynamic>);
        }
      });

      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final myId = SessionScope.of(context).currentUser?.id;
    if (myId != comment.authorId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await SessionScope.of(context).api.deleteComment(
        SessionScope.of(context).requireToken(),
        widget.postId,
        comment.id,
      );
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
        if (_post != null) {
          _post = _post!.copyWith(commentsCount: (_post!.commentsCount - 1).clamp(0, 999999));
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async { await _loadPost(); await _loadComments(); },
              child: _buildBody(),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingPost) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_post == null) {
      return const Center(child: Text('Không tìm thấy bài viết'));
    }

    return ListView(
      controller: _scrollController,
      children: [
        _buildPostHeader(),
        const Divider(height: 1),
        if (_isLoadingComments)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!')),
          )
        else
          ..._comments.map(_buildCommentTile),
      ],
    );
  }

  Widget _buildPostHeader() {
    final post = _post!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: post.userId, initialUsername: post.authorUsername),
            )),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(post.authorAvatar), radius: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('@${post.authorUsername} • ${post.timestamp}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
          if ((post.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${post.likesCount}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${post.commentsCount}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final myId = SessionScope.of(context).currentUser?.id;
    final isMe = myId != null && myId == comment.authorId;

    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: comment.authorId, initialUsername: comment.authorUsername),
      )),
      leading: CircleAvatar(
        backgroundImage: comment.authorAvatar.isNotEmpty ? NetworkImage(comment.authorAvatar) : null,
        radius: 18,
        child: comment.authorAvatar.isEmpty ? const Icon(Icons.person, size: 18) : null,
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '${comment.authorName} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextSpan(text: comment.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
      subtitle: Text(comment.timestamp, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: isMe
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () => _deleteComment(comment),
            )
          : null,
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Thêm bình luận...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendComment,
                  ),
          ],
        ),
      ),
    );
  }
}
