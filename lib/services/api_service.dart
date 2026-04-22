import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'php_response_parser.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _encodeFormBody(Map<String, dynamic> body) {
    final encoded = <String, String>{};
    void addValue(String key, dynamic value) {
      if (value == null) {
        encoded[key] = '';
      } else if (value is String || value is num || value is bool) {
        encoded[key] = value.toString();
      } else if (value is Map<dynamic, dynamic>) {
        value.forEach((dynamic nestedKey, dynamic nestedValue) {
          addValue('$key[$nestedKey]', nestedValue);
        });
      } else if (value is Iterable<dynamic>) {
        var index = 0;
        for (final item in value) {
          addValue('$key[$index]', item);
          index++;
        }
      } else {
        encoded[key] = value.toString();
      }
    }

    body.forEach(addValue);
    return encoded;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final Map<String, String> headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      if (auth) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      // Ensure no double slashes and no trailing/leading whitespace
      final cleanBaseUrl = AppConstants.baseUrl.trim().replaceAll(RegExp(r'/$'), '');
      final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/'), '');
      final url = '$cleanBaseUrl/$cleanEndpoint';
      
      print('Attempting POST to: $url');
      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: _encodeFormBody(body),
      );
      
      // DEBUG: Log full response for troubleshooting
      print('API POST ${res.statusCode} to $url');
      print('Response body: ${res.body}');
      if (res.statusCode >= 400) {
        print('ERROR details: ${res.headers}');
      }
      
      return parsePhpResponseBody(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool auth = false,
    Map<String, String>? params,
  }) async {
    try {
      final cleanBaseUrl = AppConstants.baseUrl.trim().replaceAll(RegExp(r'/$'), '');
      final cleanEndpoint = endpoint.trim().replaceAll(RegExp(r'^/'), '');
      final url = '$cleanBaseUrl/$cleanEndpoint';
      var uri = Uri.parse(url);
      final Map<String, String> headers = {
        'Accept': 'application/json',
      };
      if (auth) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      
      if (params != null && params.isNotEmpty) uri = uri.replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);
      
      // DEBUG: Log full response for troubleshooting
      print('API GET ${res.statusCode} to $uri');
      print('Response body: ${res.body}');
      if (res.statusCode >= 400) {
        print('ERROR details: ${res.headers}');
      }
      
      return parsePhpResponseBody(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
