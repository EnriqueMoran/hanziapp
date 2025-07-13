import 'dart:convert';
import 'package:http/http.dart' as http;

class Group {
  final int id;
  final String name;
  final List<String> characters;

  Group({required this.id, required this.name, required this.characters});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      characters: (json['characters'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

class GroupApi {
  static const String baseUrl = 'http://172.22.71.184:5000';

  static Future<List<Group>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/groups'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => Group.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> createGroup(Group group) async {
    final data = {
      'name': group.name,
      'characters': group.characters.join(','),
    };
    await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
  }
}

