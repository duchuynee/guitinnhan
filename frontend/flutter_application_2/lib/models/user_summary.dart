class UserSummary {
  final int id;
  final String name;
  final String username;
  final String avatarUrl;
  final String bio;
  final String? location;
  final bool isFollowing;
  final int followersCount;

  const UserSummary({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.isFollowing,
    required this.followersCount,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id:             (json['id'] as num?)?.toInt() ?? 0,
      name:           json['name']?.toString() ?? '',
      username:       json['username']?.toString() ?? '',
      avatarUrl:      json['avatar_url']?.toString() ?? '',
      bio:            json['bio']?.toString() ?? '',
      location:       json['location']?.toString(),
      isFollowing:    json['is_following'] == true,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
    );
  }

  UserSummary copyWith({bool? isFollowing, int? followersCount}) {
    return UserSummary(
      id:             id,
      name:           name,
      username:       username,
      avatarUrl:      avatarUrl,
      bio:            bio,
      location:       location,
      isFollowing:    isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}
