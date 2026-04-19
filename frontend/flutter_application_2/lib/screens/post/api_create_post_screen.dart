import 'package:flutter/material.dart';

import '../../services/api_exception.dart';
import '../../session/session_scope.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isPosting = false;
  String? _locationName;
  String? _feelingText;

  Future<void> _selectImage() async {
    final action = await showModalBottomSheet<_ImageAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.blue),
              title: const Text('Dung anh mau'),
              onTap: () => Navigator.pop(context, _ImageAction.useSample),
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text('Nhap link anh'),
              onTap: () => Navigator.pop(context, _ImageAction.enterUrl),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ImageAction.useSample:
        setState(() {
          _imageUrlController.text =
              'https://picsum.photos/seed/post${DateTime.now().millisecondsSinceEpoch}/900/700';
        });
        break;
      case _ImageAction.enterUrl:
        await _editSingleField(
          title: 'Nhap link anh',
          initialValue: _imageUrlController.text,
          hintText: 'https://...',
          onSaved: (value) => _imageUrlController.text = value,
        );
        break;
    }
  }

  Future<void> _editSingleField({
    required String title,
    required String initialValue,
    required String hintText,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Luu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (value == null) {
      return;
    }

    setState(() => onSaved(value));
  }

  void _removeImage() {
    setState(() => _imageUrlController.clear());
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long viet noi dung bai viet')),
      );
      return;
    }

    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isPosting = true);

    try {
      await session.api.createPost(
        session.requireToken(),
        content: _contentController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        locationName: _locationName,
        feelingText: _feelingText,
      );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Bai viet da duoc dang thanh cong')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.image,
          label: 'Anh',
          onTap: _selectImage,
        ),
        _buildActionButton(
          icon: Icons.location_on_outlined,
          label: 'Vi tri',
          onTap: () => _editSingleField(
            title: 'Them vi tri',
            initialValue: _locationName ?? '',
            hintText: 'VD: Ho Chi Minh City',
            onSaved: (value) => _locationName = value.isEmpty ? null : value,
          ),
        ),
        _buildActionButton(
          icon: Icons.emoji_emotions_outlined,
          label: 'Cam xuc',
          onTap: () => _editSingleField(
            title: 'Them cam xuc',
            initialValue: _feelingText ?? '',
            hintText: 'VD: Vui ve',
            onSaved: (value) => _feelingText = value.isEmpty ? null : value,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).currentUser;
    final imageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bai viet moi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _publishPost,
                      child: Text(
                        'Dang',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user == null ? null : NetworkImage(user.avatarUrl),
                    child: user == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Mini Social User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Cong khai',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 8,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Ban dang nghi gi?',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
              ),
              if (_locationName != null || _feelingText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((_locationName ?? '').isNotEmpty)
                        Chip(label: Text('Vi tri: $_locationName')),
                      if ((_feelingText ?? '').isNotEmpty)
                        Chip(label: Text('Cam xuc: $_feelingText')),
                    ],
                  ),
                ),
              if (imageUrl.isNotEmpty)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Text('Link anh khong hop le'),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeImage,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              TextField(
                controller: _imageUrlController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Link anh (tuy chon)',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),
              SizedBox(height: 45, child: _buildActions()),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ImageAction {
  useSample,
  enterUrl,
}
