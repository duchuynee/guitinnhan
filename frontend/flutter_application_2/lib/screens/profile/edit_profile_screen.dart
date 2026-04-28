import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _avatarCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl     = TextEditingController(text: p.name);
    _bioCtrl      = TextEditingController(text: p.bio);
    _avatarCtrl   = TextEditingController(text: p.avatarUrl);
    _locationCtrl = TextEditingController(text: p.location ?? '');
    _websiteCtrl  = TextEditingController(text: p.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final session = SessionScope.of(context);
    setState(() => _isSaving = true);

    try {
      await session.api.updateProfile(
        session.requireToken(),
        name:      _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        bio:       _bioCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        location:  _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        website:   _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinh sua ho so'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Luu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ho ten', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ho ten khong duoc bo trong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Gioi thieu', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _avatarCtrl,
              decoration: const InputDecoration(labelText: 'URL anh dai dien', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Dia diem', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}
