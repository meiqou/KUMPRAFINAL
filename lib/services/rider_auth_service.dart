import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class RiderAuthService {
static Future<Map<String, dynamic>> login(String identifier, String password) async {
  return ApiService.post('auth/rider_login.php', {
      'identifier': identifier,
      'password': password,
    });
  }

static Future<Map<String, dynamic>> register({
    required String name,
    required String plateNumber,
    required String phone,
    required String workShift,
    required String password,
  }) async {
  return ApiService.post('auth/rider_register.php', {
      'name': name,
      'plate_number': plateNumber,
      'phone': phone,
      'work_shift': workShift,
      'password': password,
    });
  }

  static Future<void> saveSession(Map<String, dynamic> riderData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rider_data', jsonEncode(riderData));
    await prefs.setBool('is_rider', true);
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_name', riderData['name'] ?? '');
    
    final token = riderData['token'];
    if (token != null) {
      await prefs.setString('token', token.toString());
    }
  }

  static Future<bool> isRider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_rider') ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}