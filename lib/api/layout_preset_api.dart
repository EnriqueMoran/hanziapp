import 'dart:convert';

import '../layout_preset.dart';
import 'settings_api.dart';
import '../offline/offline_service.dart';

class LayoutPresetApi {
  static const String _key = 'layout_presets';
  static const String _selectedKey = 'selected_layout_preset';

  static Future<List<LayoutPreset>> loadPresets() async {
    String jsonStr;
    if (OfflineService.isSupported && OfflineService.isOffline) {
      jsonStr = await OfflineService.getSetting(_key);
    } else {
      jsonStr = await SettingsApi.getString(_key);
      if (OfflineService.isSupported) {
        await OfflineService.setSetting(_key, jsonStr);
      }
    }
    if (jsonStr.isEmpty) return [];
    final List list = json.decode(jsonStr);
    return list.map((e) => LayoutPreset.fromJson(e)).toList();
  }

  static Future<void> savePresets(List<LayoutPreset> presets) async {
    final list = presets.map((p) => p.toJson()).toList();
    final jsonStr = json.encode(list);
    if (OfflineService.isSupported) {
      await OfflineService.setSetting(_key, jsonStr);
    }
    await SettingsApi.setString(_key, jsonStr);
  }

  static Future<String?> getSelected() async {
    String sel;
    if (OfflineService.isSupported && OfflineService.isOffline) {
      sel = await OfflineService.getSetting(_selectedKey);
    } else {
      sel = await SettingsApi.getString(_selectedKey);
      if (OfflineService.isSupported) {
        await OfflineService.setSetting(_selectedKey, sel);
      }
    }
    return sel.isEmpty ? null : sel;
  }

  static Future<void> setSelected(String? name) async {
    if (OfflineService.isSupported) {
      await OfflineService.setSetting(_selectedKey, name ?? '');
    }
    await SettingsApi.setString(_selectedKey, name);
  }
}
