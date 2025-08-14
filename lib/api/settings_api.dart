import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../offline/offline_service.dart';

class SettingsApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<String> _getValue(String key) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      return await OfflineService.getSetting(key);
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/$key'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final val = data['value'] as String? ?? '';
        if (OfflineService.isSupported) {
          await OfflineService.setSetting(key, val);
        }
        return val;
      }
    } catch (_) {
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
        return await OfflineService.getSetting(key);
      }
    }
    return '';
  }

  static Future<void> _setValue(String key, String value) async {
    if (OfflineService.isSupported) {
      await OfflineService.setSetting(key, value);
    }
    if (OfflineService.isSupported && OfflineService.isOffline) {
      return;
    }
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
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
      }
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
