import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/story.dart';
import '../models/user_summary.dart';
import 'api_exception.dart';

class MiniSocialApi {
  MiniSocialApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String baseUrl;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final json = await _post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthResult(
      accessToken: _extractAccessToken(json),
      user: AppUser.fromJson(_extractAuthUser(json)),
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final json = await _post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return AuthResult(
      accessToken: _extractAccessToken(json),
      user: AppUser.fromJson(_extractAuthUser(json)),
    );
  }

  Future<AppUser> getMe(String token) async {
    final json = await _get('/me', token: token);
    return AppUser.fromJson(_readMap(json, 'data'));
  }

  Future<FeedPayload> getFeed(String token) async {
    final json = await _get('/feed', token: token);
    final data = _readMap(json, 'data');
    final stories = _readList(data, 'stories')
        .map((item) => Story.fromJson(item as Map<String, dynamic>))
        .toList();
    final posts = _readList(data, 'posts')
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();

    return FeedPayload(stories: stories, posts: posts);
  }

  Future<List<Post>> searchPosts(
    String token, {
    String? search,
    int? userId,
    int perPage = 30,
  }) async {
    final queryParameters = <String, String>{
      'per_page': '$perPage',
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }
    if (userId != null) {
      queryParameters['user_id'] = '$userId';
    }

    final json = await _get('/posts', token: token, queryParameters: queryParameters);

    return _readList(json, 'data')
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProfileBundle> getMyProfile(String token) async {
    final json = await _get('/me/profile', token: token);
    return ProfileBundle.fromJson(_readMap(json, 'data'));
  }

  Future<List<AppNotification>> getNotifications(String token, {int perPage = 20}) async {
    final json = await _get(
      '/notifications',
      token: token,
      queryParameters: {'per_page': '$perPage'},
    );

    return _readList(json, 'data')
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Post> createPost(
    String token, {
    required String content,
    String? imageUrl,
    String? locationName,
    String? feelingText,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'visibility': 'public',
    };

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      body['image_url'] = imageUrl.trim();
    }
    if (locationName != null && locationName.trim().isNotEmpty) {
      body['location_name'] = locationName.trim();
    }
    if (feelingText != null && feelingText.trim().isNotEmpty) {
      body['feeling_text'] = feelingText.trim();
    }

    final json = await _post('/posts', token: token, body: body);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<Post> likePost(String token, int postId) async {
    final json = await _post('/posts/$postId/like', token: token);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<Post> unlikePost(String token, int postId) async {
    final json = await _delete('/posts/$postId/like', token: token);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<Post> savePost(String token, int postId) async {
    final json = await _post('/posts/$postId/save', token: token);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<Post> unsavePost(String token, int postId) async {
    final json = await _delete('/posts/$postId/save', token: token);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<void> reportPost(
    String token,
    int postId, {
    required String reason,
  }) async {
    await _post(
      '/posts/$postId/report',
      token: token,
      body: {'reason': reason},
    );
  }

  Future<AppUser> updateProfile(
    String token, {
    String? name,
    String? bio,
    String? avatarUrl,
    String? location,
    String? website,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (location != null) body['location'] = location;
    if (website != null) body['website'] = website;
    if (phone != null) body['phone'] = phone;

    final json = await _put('/me', token: token, body: body);
    return AppUser.fromJson(_readMap(json, 'data'));
  }

  Future<Post> updatePost(
    String token,
    int postId, {
    String? content,
    String? imageUrl,
    String? locationName,
    String? feelingText,
  }) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (locationName != null) body['location_name'] = locationName;
    if (feelingText != null) body['feeling_text'] = feelingText;

    final json = await _put('/posts/$postId', token: token, body: body);
    return Post.fromJson(_readMap(json, 'data'));
  }

  Future<void> deletePost(String token, int postId) async {
    await _delete('/posts/$postId', token: token);
  }

  Future<List<UserSummary>> searchUsers(String token, {String? search, int perPage = 20}) async {
    final params = <String, String>{'per_page': '$perPage'};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    final json = await _get('/users', token: token, queryParameters: params);
    return _readList(json, 'data')
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getUserProfile(String token, int userId) async {
    return _get('/users/$userId', token: token);
  }

  Future<List<UserSummary>> getUserFollowers(String token, int userId, {int perPage = 20}) async {
    final json = await _get('/users/$userId/followers', token: token, queryParameters: {'per_page': '$perPage'});
    return _readList(json, 'data')
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserSummary>> getUserFollowing(String token, int userId, {int perPage = 20}) async {
    final json = await _get('/users/$userId/following', token: token, queryParameters: {'per_page': '$perPage'});
    return _readList(json, 'data')
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> followUser(String token, int userId) async {
    await _post('/users/$userId/follow', token: token);
  }

  Future<void> unfollowUser(String token, int userId) async {
    await _delete('/users/$userId/follow', token: token);
  }

  Future<Map<String, dynamic>> getPost(String token, int postId) async {
    return _get('/posts/$postId', token: token);
  }

  Future<List<Comment>> getComments(String token, int postId, {int perPage = 20}) async {
    final json = await _get('/posts/$postId/comments', token: token, queryParameters: {'per_page': '$perPage'});
    return _readList(json, 'data')
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> addComment(String token, int postId, String content) async {
    return _post('/posts/$postId/comments', token: token, body: {'content': content});
  }

  Future<void> deleteComment(String token, int postId, int commentId) async {
    await _delete('/posts/$postId/comments/$commentId', token: token);
  }

  Future<void> markNotificationRead(String token, int notificationId) async {
    await _post('/notifications/$notificationId/read', token: token);
  }

  Future<void> markAllNotificationsRead(String token) async {
    await _post('/notifications/read-all', token: token);
  }

  Future<void> logout(String token) async {
    await _post('/auth/logout', token: token);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _client.get(
        _buildUri(path, queryParameters: queryParameters),
        headers: _headers(token),
      );

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Khong the ket noi den backend. Hay kiem tra Laravel dang chay tren cong 8000.');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.post(
        _buildUri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      );

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Khong the ket noi den backend. Hay kiem tra Laravel dang chay tren cong 8000.');
    }
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.put(
        _buildUri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      );

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Khong the ket noi den backend. Hay kiem tra Laravel dang chay tren cong 8000.');
    }
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _client.delete(
        _buildUri(path),
        headers: _headers(token),
      );

      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Khong the ket noi den backend. Hay kiem tra Laravel dang chay tren cong 8000.');
    }
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final baseUri = Uri.parse(baseUrl);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters == null || queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded;
    try {
      decoded = response.body.isEmpty ? const <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Backend tra ve du lieu khong hop le (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw ApiException(
      _extractErrorMessage(json) ?? 'Yeu cau that bai (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  static String? _extractErrorMessage(Map<String, dynamic> json) {
    final errors = json['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }

    final message = json['message'];
    return message?.toString();
  }

  static Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  static List<dynamic> _readList(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is List ? value : const [];
  }

  static String _extractAccessToken(Map<String, dynamic> json) {
    final data = _readMap(json, 'data');

    return _firstNonEmptyString([
      json['access_token'],
      json['token'],
      data['access_token'],
      data['token'],
    ]);
  }

  static Map<String, dynamic> _extractAuthUser(Map<String, dynamic> json) {
    final topLevelUser = _readMap(json, 'user');
    if (topLevelUser.isNotEmpty) {
      return topLevelUser;
    }

    final data = _readMap(json, 'data');
    return _readMap(data, 'user');
  }

  static String _firstNonEmptyString(List<dynamic> candidates) {
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  static String _resolveBaseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }
}

class AuthResult {
  final String accessToken;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.user,
  });
}

class FeedPayload {
  final List<Story> stories;
  final List<Post> posts;

  const FeedPayload({
    required this.stories,
    required this.posts,
  });
}
