import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../offline/offline_service.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'characters': characters.join(','),
  };
}

class BatchApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Batch>> fetchAll({bool forceRemote = false}) async {
    if (!forceRemote &&
        OfflineService.isSupported &&
        OfflineService.isOffline) {
      return OfflineService.getAllBatches();
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/batches'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        return list.map((e) => Batch.fromJson(e)).toList();
      }
    } catch (_) {
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
        return OfflineService.getAllBatches();
      }
    }
    return [];
  }

  static Future<void> saveBatches(List<Batch> batches) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      await OfflineService.saveLocalBatches(batches);
      await OfflineService.queueOperation('batches_save', {
        'batches': batches.map((e) => e.toJson()).toList(),
      });
      return;
    }
    final data = [
      for (final b in batches)
        {'name': b.name, 'characters': b.characters.join(',')},
    ];
    await http.post(
      Uri.parse('$baseUrl/batches'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Token': ApiConfig.apiToken,
      },
      body: json.encode(data),
    );
  }
}
