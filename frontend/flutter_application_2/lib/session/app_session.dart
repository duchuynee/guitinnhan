import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/api_exception.dart';
import '../services/mini_social_api.dart';

class AppSession extends ChangeNotifier {
  AppSession({MiniSocialApi? api}) : api = api ?? MiniSocialApi();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final MiniSocialApi api;

  SharedPreferences? _preferences;
  String? _token;
  AppUser? _currentUser;
  bool _isReady = false;

  bool get isReady => _isReady;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _currentUser != null;
  AppUser? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> bootstrap() async {
    _preferences = await SharedPreferences.getInstance();
    final savedToken = _preferences?.getString(_tokenKey);
    final savedUser = _preferences?.getString(_userKey);

    if (savedToken == null || savedToken.isEmpty) {
      await _clearLocalSession();
      _isReady = true;
      notifyListeners();
      return;
    }

    _token = savedToken;

    if (savedUser != null && savedUser.isNotEmpty) {
      final decoded = jsonDecode(savedUser);
      if (decoded is Map<String, dynamic>) {
        _currentUser = AppUser.fromJson(decoded);
      }
    }

    if (_token != null && _token!.isNotEmpty) {
      try {
        _currentUser = await api.getMe(_token!);
        await _persist();
      } on ApiException {
        await _clearLocalSession();
      }
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final result = await api.login(email: email, password: password);
    if (result.accessToken.isEmpty) {
      throw const ApiException('Dang nhap that bai. Backend khong tra token hop le.');
    }
    _token = result.accessToken;
    _currentUser = result.user;
    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await api.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (result.accessToken.isEmpty) {
      throw const ApiException('Dang ky that bai. Backend khong tra token hop le.');
    }
    _token = result.accessToken;
    _currentUser = result.user;
    await _persist();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final currentToken = requireToken();
    _currentUser = await api.getMe(currentToken);
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    final currentToken = _token;
    if (currentToken != null && currentToken.isNotEmpty) {
      try {
        await api.logout(currentToken);
      } on ApiException {
        // Always clear local session to avoid trapping the user.
      }
    }

    await _clearLocalSession();
    notifyListeners();
  }

  String requireToken() {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw const ApiException('Phien dang nhap da het han. Vui long dang nhap lai.');
    }
    return currentToken;
  }

  Future<void> _persist() async {
    if (_token != null && _token!.isNotEmpty) {
      await _preferences?.setString(_tokenKey, _token!);
    } else {
      await _preferences?.remove(_tokenKey);
    }
    if (_currentUser != null) {
      await _preferences?.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    } else {
      await _preferences?.remove(_userKey);
    }
  }

  Future<void> _clearLocalSession() async {
    _token = null;
    _currentUser = null;
    await _preferences?.remove(_tokenKey);
    await _preferences?.remove(_userKey);
  }
}
