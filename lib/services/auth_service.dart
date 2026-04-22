import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  // Base URL from AppConstants
  static const String baseUrl = AppConstants.baseUrl;

  static Future<void> _storeSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_name', userData['name'] ?? '');
    await prefs.setString('user_username', userData['username'] ?? '');
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('cluster_name', userData['cluster_name'] ?? '');
    await prefs.setString(
        'cluster_id', (userData['cluster_id'] ?? '').toString());

    final token = userData['token'];
    if (token != null && token.toString().isNotEmpty) {
      await prefs.setString('token', token.toString());
    }
  }

  // 1. Fetch Clusters (Barangays)
  static Future<Map<String, dynamic>> getClusters() async {
    return ApiService.get('clusters/list.php');
  }

  // 2. Login Method
  static Future<Map<String, dynamic>> login(
      String identifier, String password) async {
    return ApiService.post('auth/login.php', {
      'identifier': identifier,
      'password': password,
    });
  }

  // 3. Register Method
  static Future<Map<String, dynamic>> register(String name, String username,
      String email, String phone, String password, String clusterId) async {
    return ApiService.post('auth/register.php', {
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'cluster_id': clusterId,
    });
  }

  static Future<Map<String, dynamic>> updateProfile(String name,
      String username, String email, String password, String clusterId) async {
    final body = <String, dynamic>{};
    if (name.isNotEmpty) body['name'] = name;
    if (username.isNotEmpty) body['username'] = username;
    if (email.isNotEmpty) body['email'] = email;
    if (password.isNotEmpty) body['password'] = password;
    if (clusterId.isNotEmpty) body['cluster_id'] = clusterId;

    return ApiService.post('auth/update.php', body, auth: true);
  }

  // 4. Session Management
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    await _storeSession(userData);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool('is_logged_in') ?? false) ||
        ((prefs.getString('token') ?? '').isNotEmpty);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
