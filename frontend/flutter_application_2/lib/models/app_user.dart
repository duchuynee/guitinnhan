class AppUser {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String avatarUrl;
  final String bio;
  final String? location;
  final String? website;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.website,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      location: json['location']?.toString(),
      website: json['website']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'website': website,
    };
  }
}
