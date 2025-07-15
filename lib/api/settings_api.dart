import 'dart:convert';
import 'package:http/http.dart' as http;

class SettingsApi {
  static const String baseUrl = 'http://172.22.208.95:5000';

  static Future<String> _getValue(String key) async {
    final response = await http.get(Uri.parse('$baseUrl/settings/$key'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['value'] as String? ?? '';
    }
    return '';
  }

  static Future<void> _setValue(String key, String value) async {
    await http.put(
      Uri.parse('$baseUrl/settings/$key'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'value': value}),
    );
  }

  static Future<int?> getInt(String key) async {
    final val = await _getValue(key);
    return int.tryParse(val);
  }

  static Future<void> setInt(String key, int? value) async {
    await _setValue(key, value == null ? '' : value.toString());
  }
}
