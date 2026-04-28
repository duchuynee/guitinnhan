class Comment {
  final int id;
  final int postId;
  final String content;
  final String timestamp;
  final String createdAt;
  final int authorId;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;

  const Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.timestamp,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return Comment(
      id:             (json['id'] as num?)?.toInt() ?? 0,
      postId:         (json['post_id'] as num?)?.toInt() ?? 0,
      content:        json['content']?.toString() ?? '',
      timestamp:      json['timestamp']?.toString() ?? '',
      createdAt:      json['created_at']?.toString() ?? '',
      authorId:       (author?['id'] as num?)?.toInt() ?? 0,
      authorName:     author?['name']?.toString() ?? '',
      authorUsername: author?['username']?.toString() ?? '',
      authorAvatar:   author?['avatar_url']?.toString() ?? '',
    );
  }
}
