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
  static const String baseUrl = 'http://172.22.71.184:5000';

  static Future<List<Character>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/characters'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => Character.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Character?> fetchCharacter(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/characters/$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Character.fromJson(data);
    }
    return null;
  }

  static Future<bool> deleteCharacter(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/characters/$id'));
    return response.statusCode == 200;
  }

  static Future<bool> updateCharacter(Character c) async {
    final response = await http.put(
      Uri.parse('$baseUrl/characters/${c.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(c.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<void> setLastReviewed(int id) async {
    await http.put(
      Uri.parse('$baseUrl/last_reviewed'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'character_id': id}),
    );
  }
}
