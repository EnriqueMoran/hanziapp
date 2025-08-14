import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SettingsApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<String> _getValue(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/$key'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['value'] as String? ?? '';
      }
    } catch (_) {
      // Ignore network errors; the caller will treat missing values as defaults.
    }
    return '';
  }

  static Future<void> _setValue(String key, String value) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/settings/$key'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': ApiConfig.apiToken,
        },
        body: json.encode({'value': value}),
      );
    } catch (_) {
      // Swallow errors when the server is unreachable.
    }
  }

  static Future<int?> getInt(String key) async {
    final val = await _getValue(key);
    return int.tryParse(val);
  }

  static Future<void> setInt(String key, int? value) async {
    await _setValue(key, value == null ? '' : value.toString());
  }

  static Future<String> getString(String key) async {
    return await _getValue(key);
  }

  static Future<void> setString(String key, String? value) async {
    await _setValue(key, value ?? '');
  }
}
