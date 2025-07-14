import 'dart:convert';
import 'package:http/http.dart' as http;

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
}

class CharacterApi {
  static const String baseUrl = 'http://172.22.71.184:5000';

  static Future<List<Character>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/characters'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => Character.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Character?> fetchCharacter(String char) async {
    final response = await http.get(Uri.parse('$baseUrl/characters/$char'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Character.fromJson(data);
    }
    return null;
  }

  static Future<void> updateCharacter(Character c) async {
    await http.put(
      Uri.parse('$baseUrl/characters/${c.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'character': c.character,
        'pinyin': c.pinyin,
        'meaning': c.meaning,
        'level': c.level,
        'tags': c.tags.join(','),
        'other': c.other,
        'examples': c.examples,
      }),
    );
  }

  static Future<void> deleteCharacter(int id) async {
    await http.delete(Uri.parse('$baseUrl/characters/$id'));
  }

  static Future<int?> createCharacter(Character c) async {
    final response = await http.post(
      Uri.parse('$baseUrl/characters'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'character': c.character,
        'pinyin': c.pinyin,
        'meaning': c.meaning,
        'level': c.level,
        'tags': c.tags.join(','),
        'other': c.other,
        'examples': c.examples,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as int?;
    }
    return null;
  }

  static Future<List<String>> fetchTags() async {
    final response = await http.get(Uri.parse('$baseUrl/tags'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.cast<String>();
    }
    return [];
  }
}
