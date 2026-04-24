class Story {
  final int id;
  final int userId;
  final String mediaUrl;
  final String caption;
  final String timestamp;
  final String userName;
  final String userAvatar;

  const Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.caption,
    required this.timestamp,
    required this.userName,
    required this.userAvatar,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      mediaUrl: json['media_url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString() ?? '',
    );
  }
}
/////
