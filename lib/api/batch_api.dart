import 'dart:convert';
import 'package:http/http.dart' as http;

class Batch {
  final int id;
  final String name;
  final List<String> characters;

  Batch({required this.id, required this.name, required this.characters});

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      characters: (json['characters'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

class BatchApi {
  static const String baseUrl = 'http://172.22.71.184:5000';

  static Future<List<Batch>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/batches'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => Batch.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> saveBatches(List<Batch> batches) async {
    final data = [
      for (final b in batches)
        {
          'name': b.name,
          'characters': b.characters.join(','),
        }
    ];
    await http.post(
      Uri.parse('$baseUrl/batches'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
  }
}
