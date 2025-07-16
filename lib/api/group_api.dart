import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class Group {
  final int id;
  final String name;

  final List<int> characterIds;

  Group({required this.id, required this.name, required this.characterIds});

  factory Group.fromJson(Map<String, dynamic> json) {
    final chars = (json['characters'] as String? ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList();
    return Group(id: json['id'] as int, name: json['name'] as String, characterIds: chars);
  }
}

class GroupApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Group>> fetchAll() async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Group.fromJson(e)).toList();
    }
    return [];
  }

  static Future<int?> createGroup(String name, List<int> characters) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode({'name': name, 'characters': characters.join(',')}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as int?;
    }
    return null;
  }

  static Future<void> updateGroup(int id, String name, List<int> characters) async {
    await http.put(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode({'name': name, 'characters': characters.join(',')}),
    );
  }

  static Future<void> deleteGroup(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
  }
}
