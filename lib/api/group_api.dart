import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../offline/offline_service.dart';

class Group {
  final int id;
  final String name;
  final List<int> characterIds;
  final int? updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.characterIds,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final chars = (json['characters'] as String? ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList();
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      characterIds: chars,
      updatedAt: json['updated_at'] as int? ?? json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'characters': characterIds,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class GroupApi {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Group>> fetchAll({bool forceRemote = false}) async {
    if (!forceRemote &&
        OfflineService.isSupported &&
        OfflineService.isOffline) {
      return OfflineService.getAllGroups();
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups'),
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Group.fromJson(e)).toList();
      }
    } catch (_) {
      if (OfflineService.isSupported) {
        OfflineService.isOffline = true;
        return OfflineService.getAllGroups();
      }
    }
    return [];
  }

  static Future<int?> createGroup(String name, List<int> characters) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final g = Group(
        id: OfflineService.nextTempId(),
        name: name,
        characterIds: characters,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await OfflineService.addLocalGroup(g);
      await OfflineService.queueOperation('group_create', {
        'name': name,
        'characters': characters,
      });
      return g.id;
    }
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

  static Future<void> updateGroup(
    int id,
    String name,
    List<int> characters,
  ) async {
    if (OfflineService.isSupported && OfflineService.isOffline) {
      final g = Group(
        id: id,
        name: name,
        characterIds: characters,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await OfflineService.updateLocalGroup(g);
      await OfflineService.queueOperation('group_update', g.toJson());
      return;
    }
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
    if (OfflineService.isSupported && OfflineService.isOffline) {
      await OfflineService.deleteLocalGroup(id);
      await OfflineService.queueOperation('group_delete', {'id': id});
      return;
    }
    await http.delete(
      Uri.parse('$baseUrl/groups/$id'),
      headers: {'X-API-Token': ApiConfig.apiToken},
    );
  }
}
