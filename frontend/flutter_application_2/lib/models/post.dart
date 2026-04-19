class Post {
  final int id;
  final int userId;
  final String content;
  final String? imageUrl;
  final String? locationName;
  final String? feelingText;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final int reportsCount;
  final String timestamp;
  final String createdAt;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final bool isLiked;
  final bool isSaved;

  const Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrl,
    required this.locationName,
    required this.feelingText,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.reportsCount,
    required this.timestamp,
    required this.createdAt,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.isLiked,
    required this.isSaved,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return Post(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      locationName: json['location_name']?.toString(),
      feelingText: json['feeling_text']?.toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? (json['likes'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? (json['comments'] as num?)?.toInt() ?? 0,
      savesCount: (json['saves_count'] as num?)?.toInt() ?? 0,
      reportsCount: (json['reports_count'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      authorName: author?['name']?.toString() ?? json['author_name']?.toString() ?? '',
      authorUsername: author?['username']?.toString() ?? '',
      authorAvatar: author?['avatar_url']?.toString() ?? json['author_avatar']?.toString() ?? '',
      isLiked: json['is_liked'] == true,
      isSaved: json['is_saved'] == true,
    );
  }

  Post copyWith({
    int? id,
    int? userId,
    String? content,
    String? imageUrl,
    String? locationName,
    String? feelingText,
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    int? reportsCount,
    String? timestamp,
    String? createdAt,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      locationName: locationName ?? this.locationName,
      feelingText: feelingText ?? this.feelingText,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      savesCount: savesCount ?? this.savesCount,
      reportsCount: reportsCount ?? this.reportsCount,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
