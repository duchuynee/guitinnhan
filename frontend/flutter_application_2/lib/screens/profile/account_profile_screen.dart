import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../models/profile.dart';
import '../../services/api_exception.dart';
import '../../session/session_scope.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _error;
  ProfileBundle? _bundle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadProfile();
    }
  }

 
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bundle = await session.api.getMyProfile(session.requireToken());
      if (!mounted) {
        return;
      }

      setState(() {
        _bundle = bundle;
        _isLoading = false;
      });

      await session.refreshUser();
      if (showRefreshMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ho so da duoc cap nhat')),
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

  Future<void> _logout() async {
    await SessionScope.of(context).logout();
  }

  Widget _buildGrid(List<Post> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text(emptyMessage)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final imageUrl = posts[index].imageUrl;
        return Container(
          color: Colors.grey[200],
          child: imageUrl == null || imageUrl.isEmpty
              ? const Icon(Icons.image_outlined, color: Colors.grey)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    final profile = bundle?.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? 'Profile' : '@${profile.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _buildBody(bundle, profile),
      ),
    );
  }

  Widget _buildBody(ProfileBundle? bundle, UserProfile? profile) {
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
          const SizedBox(height: 120),
          Center(child: Text(_error!)),
        ],
      );
    }

    if (bundle == null || profile == null) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Khong tai duoc du lieu profile')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(profile.avatarUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('${profile.stats.postsCount}', 'Posts'),
                  _buildStat('${profile.stats.followersCount}', 'Followers'),
                  _buildStat('${profile.stats.followingCount}', 'Following'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('@${profile.username}', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(profile.bio.isEmpty ? 'Chua co gioi thieu' : profile.bio),
        if ((profile.location ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(profile.location!, style: TextStyle(color: Colors.grey[600])),
        ],
        if ((profile.website ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(profile.website!, style: const TextStyle(color: Colors.blue)),
        ],
        const SizedBox(height: 24),
        const Text('Bai viet', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGrid(bundle.postsPreview, 'Chua co anh bai viet de hien thi'),
        const SizedBox(height: 20),
        Text(
          'Da luu (${profile.stats.savedPostsCount})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildGrid(bundle.savedPostsPreview, 'Chua co bai viet nao duoc luu'),
      ],
    );
  }
}
