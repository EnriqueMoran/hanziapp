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

  Character({
    required this.id,
    required this.character,
    required this.pinyin,
    required this.meaning,
    required this.level,
    required this.tags,
    required this.other,
    required this.examples,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      character: json['character'] as String,
      pinyin: json['pinyin'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      level: json['level'] as String? ?? '',
      tags: (json['tags'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
      other: json['other'] as String? ?? '',
      examples: json['examples'] as String? ?? '',
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
      await OfflineService.queueOperation('update', c);
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
      final c = Character(
        id: id,
        character: '',
        pinyin: '',
        meaning: '',
        level: '',
        tags: const [],
        other: '',
        examples: '',
      );
      await OfflineService.queueOperation('delete', c);
      return;
    }
    await http.delete(
      Uri.parse('$baseUrl/characters/$id'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
  }

  static Future<int?> createCharacter(Character c) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      await OfflineService.queueOperation('create', c);
      return null;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/characters'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode(c.toJson()),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as int?;
    }
    return null;
  }

  static Future<List<String>> fetchTags() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tags'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.cast<String>();
    }
    return [];
  }
}
