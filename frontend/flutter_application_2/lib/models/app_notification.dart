class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final String timestamp;
  final String actorName;
  final String actorAvatar;
  final int? postId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.actorName,
    required this.actorAvatar,
    required this.postId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;

    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      actorName: actor?['name']?.toString() ?? '',
      actorAvatar: actor?['avatar_url']?.toString() ?? '',
      postId: (json['post_id'] as num?)?.toInt(),
    );
  }
}
