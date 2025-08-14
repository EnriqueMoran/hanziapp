import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../offline/offline_service.dart';

class Character {
  final int id;
  final String character;
  final String pinyin;
  final String meaning;
  final String level;
  final List<String> tags;
  final String other;
  final String examples;
  final int? updatedAt;

  Character({
    required this.id,
    required this.character,
    required this.pinyin,
    required this.meaning,
    required this.level,
    required this.tags,
    required this.other,
    required this.examples,
    this.updatedAt,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      character: json['character'] as String,
      pinyin: json['pinyin'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      level: json['level'] as String? ?? '',
      tags: (json['tags'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      other: json['other'] as String? ?? '',
      examples: json['examples'] as String? ?? '',
      updatedAt: json['updated_at'] as int? ?? json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character': character,
      'pinyin': pinyin,
      'meaning': meaning,
      'level': level,
      'tags': tags.join(','),
      'other': other,
      'examples': examples,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class CharacterApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Character>> fetchAll({bool forceRemote = false}) async {
    if (!forceRemote &&
        OfflineService.isSupported &&
        OfflineService.isOffline) {
      return OfflineService.getAllCharacters();
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/characters'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.map((e) => Character.fromJson(e)).toList();
      }
    } catch (_) {
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
        return OfflineService.getAllCharacters();
      }
    }
    return [];
  }

  static Future<Character?> fetchCharacter(String char) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final all = await OfflineService.getAllCharacters();
      try {
        return all.firstWhere((c) => c.character == char);
      } catch (_) {
        return null;
      }
    }
    final response = await http.get(
      Uri.parse('$baseUrl/characters/$char'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Character.fromJson(data);
    }
    return null;
  }

  static Future<void> updateCharacter(Character c) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final updated = Character(
        id: c.id,
        character: c.character,
        pinyin: c.pinyin,
        meaning: c.meaning,
        level: c.level,
        tags: c.tags,
        other: c.other,
        examples: c.examples,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await OfflineService.updateLocalCharacter(updated);
      await OfflineService.queueOperation('character_update', updated.toJson());
      return;
    }
    await http.put(
      Uri.parse('$baseUrl/characters/${c.id}'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode(c.toJson()),
    );
  }

  static Future<void> deleteCharacter(int id) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      await OfflineService.deleteLocalCharacter(id);
      await OfflineService.queueOperation('character_delete', {'id': id});
      return;
    }
    await http.delete(
      Uri.parse('$baseUrl/characters/$id'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
  }

  static Future<int?> createCharacter(Character c) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final temp = Character(
        id: OfflineService.nextTempId(),
        character: c.character,
        pinyin: c.pinyin,
        meaning: c.meaning,
        level: c.level,
        tags: c.tags,
        other: c.other,
        examples: c.examples,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await OfflineService.addLocalCharacter(temp);
      final payload = temp.toJson();
      await OfflineService.queueOperation('character_create', payload);
      return temp.id;
    }
    final payload = Character(
      id: c.id,
      character: c.character,
      pinyin: c.pinyin,
      meaning: c.meaning,
      level: c.level,
      tags: c.tags,
      other: c.other,
      examples: c.examples,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ).toJson();
    final response = await http.post(
      Uri.parse('$baseUrl/characters'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode(payload),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as int?;
    }
    return null;
  }

  static Future<List<String>> fetchTags() async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final chars = await OfflineService.getAllCharacters();
      final set = <String>{};
      for (final c in chars) {
        set.addAll(c.tags);
      }
      final list = set.toList()..sort();
      return list;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.cast<String>();
      }
    } catch (_) {
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
        final chars = await OfflineService.getAllCharacters();
        final set = <String>{};
        for (final c in chars) {
          set.addAll(c.tags);
        }
        final list = set.toList()..sort();
        return list;
      }
    }
    return [];
  }
}
