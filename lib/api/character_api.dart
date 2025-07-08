import 'dart:convert';
import 'package:http/http.dart' as http;

class Character {
  final String character;
  final String pinyin;
  final String meaning;
  final String level;
  final List<String> tags;
  final String other;

  Character({
    required this.character,
    required this.pinyin,
    required this.meaning,
    required this.level,
    required this.tags,
    required this.other,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      character: json['character'] as String,
      pinyin: json['pinyin'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      level: json['level'] as String? ?? '',
      tags: (json['tags'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
      other: json['other'] as String? ?? '',
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
}
