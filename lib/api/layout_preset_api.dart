import 'dart:convert';

import '../layout_preset.dart';
import 'settings_api.dart';

class LayoutPresetApi {
  static const String _key = 'layout_presets';
  static const String _selectedKey = 'selected_layout_preset';

  static Future<List<LayoutPreset>> loadPresets() async {
    final jsonStr = await SettingsApi.getString(_key);
    if (jsonStr.isEmpty) return [];
    final List list = json.decode(jsonStr);
    return list.map((e) => LayoutPreset.fromJson(e)).toList();
  }

  static Future<void> savePresets(List<LayoutPreset> presets) async {
    final list = presets.map((p) => p.toJson()).toList();
    await SettingsApi.setString(_key, json.encode(list));
  }

  static Future<String?> getSelected() async {
    final sel = await SettingsApi.getString(_selectedKey);
    return sel.isEmpty ? null : sel;
  }

  static Future<void> setSelected(String? name) async {
    await SettingsApi.setString(_selectedKey, name);
  }
}
