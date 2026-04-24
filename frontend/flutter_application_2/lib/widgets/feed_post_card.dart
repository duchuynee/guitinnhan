import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_exception.dart';


class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late Post _post;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isLikeLoading = false;
  bool _isSaveLoading = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1, end: 1.25).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  Future<void> _handleLike() async {
    final callback = widget.onToggleLike;
    if (callback == null || _isLikeLoading) {
      return;
    }

    setState(() => _isLikeLoading = true);

    try {
      final updated = await callback(_post);
      if (!mounted) {
        return;
      }

      setState(() => _post = updated);
      await _likeAnimationController.forward();
      if (mounted) {
        await _likeAnimationController.reverse();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isLikeLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final callback = widget.onToggleSave;
    if (callback == null || _isSaveLoading) {
      return;
    }

    setState(() => _isSaveLoading = true);

    try {
      final updated = await callback(_post);
      if (!mounted) {
        return;
      }

      setState(() => _post = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_post.isSaved ? 'Da luu bai viet' : 'Da bo luu bai viet'),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSaveLoading = false);
      }
    }
  }

  Future<void> _showActions() async {
    final action = await showModalBottomSheet<_PostAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_post.isSaved ? Icons.bookmark : Icons.bookmark_outline),
              title: Text(_post.isSaved ? 'Bo luu bai viet' : 'Luu bai viet'),
              onTap: () => Navigator.pop(context, _PostAction.save),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bao cao bai viet'),
              onTap: () => Navigator.pop(context, _PostAction.report),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostAction.save:
        await _handleSave();
        break;
      case _PostAction.report:
        await _handleReport();
        break;
    }
  }

  Future<void> _handleReport() async {
    final callback = widget.onReport;
    if (callback == null) {
      return;
    }

    final controller = TextEditingController(text: 'Inappropriate content.');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bao cao bai viet'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ly do bao cao',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Gui'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || reason == null || reason.isEmpty) {
      return;
    }

    try {
      await callback(_post, reason);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bao cao da duoc gui')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authorHandle = _post.authorUsername.isEmpty ? '' : '@${_post.authorUsername}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(_post.authorAvatar)),
          title: Text(
            _post.authorName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            authorHandle.isEmpty ? _post.timestamp : '$authorHandle • ${_post.timestamp}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: _showActions,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if ((_post.locationName ?? '').isNotEmpty || (_post.feelingText ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((_post.locationName ?? '').isNotEmpty)
                        Chip(
                          label: Text(_post.locationName!),
                          visualDensity: VisualDensity.compact,
                        ),
                      if ((_post.feelingText ?? '').isNotEmpty)
                        Chip(
                          label: Text(_post.feelingText!),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if ((_post.imageUrl ?? '').isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 240,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 44, color: Colors.grey),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ScaleTransition(
                scale: _likeAnimation,
                child: GestureDetector(
                  onTap: _handleLike,
                  child: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 24,
                    color: _post.isLiked ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text('${_post.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.grey),
              const SizedBox(width: 5),
              Text('${_post.commentsCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (_isLikeLoading || _isSaveLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _handleSave,
                  icon: Icon(
                    _post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: _post.isSaved ? Colors.blue[700] : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

enum _PostAction {
  save,
  report,
}
