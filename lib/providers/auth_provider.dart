import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  String? _error;
  Timer? _tokenRefreshTimer;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _baseUrl = 'http://localhost:3000/api';

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      final token = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');

      if (token != null && refreshToken != null) {
        if (!Jwt.isExpired(token)) {
          _token = token;
          _refreshToken = refreshToken;
          _isAuthenticated = true;
          await _getUserInfo();
          _scheduleTokenRefresh();
        } else {
          // Try to refresh token
          final success = await _refreshAccessToken();
          if (!success) {
            await logout();
          }
        }
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }

    _setLoading(false);
  }

  Future<bool> login(String email, String password, {String? twoFactorToken}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (twoFactorToken != null) 'twoFactorToken': twoFactorToken,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _handleAuthSuccess(data);
        return true;
      } else {
        _setError(data['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        await _handleAuthSuccess(data);
        return true;
      } else {
        if (data['errors'] != null && data['errors'] is List) {
          _setError(data['errors'].map((e) => e['message']).join(', '));
        } else {
          _setError(data['message'] ?? 'Registration failed');
        }
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _tokenRefreshTimer?.cancel();
    
    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'refreshToken': _refreshToken}),
        );
      }
    } catch (e) {
      // Ignore logout errors
    }

    _isAuthenticated = false;
    _token = null;
    _refreshToken = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update tokens after password change
        _token = data['data']['tokens']['accessToken'];
        _refreshToken = data['data']['tokens']['refreshToken'];
        await _storage.write(key: 'access_token', value: _token!);
        await _storage.write(key: 'refresh_token', value: _refreshToken!);
        _scheduleTokenRefresh();
        return true;
      } else {
        _setError(data['message'] ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(profileData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _user = data['data']['user'];
        notifyListeners();
        return true;
      } else {
        _setError(data['message'] ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    _token = data['data']['tokens']['accessToken'];
    _refreshToken = data['data']['tokens']['refreshToken'];
    _user = data['data']['user'];
    _isAuthenticated = true;

    await _storage.write(key: 'access_token', value: _token!);
    await _storage.write(key: 'refresh_token', value: _refreshToken!);

    _scheduleTokenRefresh();
    notifyListeners();
  }

  Future<void> _getUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = data['data']['user'];
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['data']['tokens']['accessToken'];
        _refreshToken = data['data']['tokens']['refreshToken'];

        await _storage.write(key: 'access_token', value: _token!);
        await _storage.write(key: 'refresh_token', value: _refreshToken!);

        _scheduleTokenRefresh();
        return true;
      }
    } catch (e) {
      // Handle error silently
    }

    return false;
  }

  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    
    if (_token != null) {
      try {
        final payload = Jwt.parseJwt(_token!);
        final exp = payload['exp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilRefresh = exp - now - 300; // Refresh 5 minutes before expiry

        if (timeUntilRefresh > 0) {
          _tokenRefreshTimer = Timer(
            Duration(seconds: timeUntilRefresh),
            () => _refreshAccessToken(),
          );
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}