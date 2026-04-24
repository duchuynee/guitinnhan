import 'app_user.dart';
import 'post.dart';



  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      location: json['location']?.toString(),
      website: json['website']?.toString(),
      phone: json['phone']?.toString(),
      isMe: json['is_me'] == true,
      isFollowing: json['is_following'] == true,
      stats: ProfileStats.fromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class ProfileStats {
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int savedPostsCount;

  const ProfileStats({
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.savedPostsCount,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      savedPostsCount: (json['saved_posts_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileBundle {
  final UserProfile profile;
  final List<Post> postsPreview;
  final List<Post> savedPostsPreview;

  const ProfileBundle({
    required this.profile,
    required this.postsPreview,
    required this.savedPostsPreview,
  });

  factory ProfileBundle.fromJson(Map<String, dynamic> json) {
    final postsJson = json['posts_preview'] as List<dynamic>? ?? const [];
    final savedJson = json['saved_posts_preview'] as List<dynamic>? ?? const [];

    return ProfileBundle(
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? const {}),
      postsPreview: postsJson
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList(),
      savedPostsPreview: savedJson
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
