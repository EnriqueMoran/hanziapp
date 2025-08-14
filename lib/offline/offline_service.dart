import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../api/api_config.dart';
import '../api/character_api.dart';
import '../api/group_api.dart';
import '../api/batch_api.dart' show Batch, BatchApi;
import '../api/settings_api.dart';

typedef SyncProgress = void Function(
  String message,
  int current,
  int total, {
  int? currentItem,
  int? totalItems,
});

class OfflineService {
  static sqflite.Database? _db;
  static bool isOffline = false;
  static late String _dbPath;
  static int _tempId = -1;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!isSupported) return;
    _dbPath = join(await sqflite.getDatabasesPath(), 'hanzi.db');
    _db = await sqflite.openDatabase(
      _dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE characters(
            id INTEGER PRIMARY KEY,
            character TEXT,
            pinyin TEXT,
            meaning TEXT,
            level TEXT,
            tags TEXT,
            other TEXT,
            examples TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE groups(
            id INTEGER PRIMARY KEY,
            name TEXT,
            characters TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE batches(
            id INTEGER PRIMARY KEY,
            name TEXT,
            characters TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_ops(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op_type TEXT,
            payload TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  static Future<List<Character>> getAllCharacters() async {
    if (!isSupported) return [];
    final db = _db;
    if (db == null) return [];
    final maps = await db.query('characters');
    return maps
        .map(
          (e) => Character(
            id: e['id'] as int,
            character: e['character'] as String,
            pinyin: e['pinyin'] as String? ?? '',
            meaning: e['meaning'] as String? ?? '',
            level: e['level'] as String? ?? '',
            tags: (e['tags'] as String? ?? '')
                .split(',')
                .where((t) => t.isNotEmpty)
                .toList(),
            other: e['other'] as String? ?? '',
            examples: e['examples'] as String? ?? '',
          ),
        )
        .toList();
  }

  static Future<void> _saveCharacters(
    List<Character> chars, {
    bool clearExisting = false,
    SyncProgress? progress,
    int stage = 0,
    int totalStages = 0,
  }) async {
    if (!isSupported) return;
    final db = _db;
    if (db == null) return;
    if (clearExisting) {
      await db.delete('characters');
    }
    final batch = db.batch();
    for (int i = 0; i < chars.length; i++) {
      final c = chars[i];
      batch.insert('characters', {
        'id': c.id,
        'character': c.character,
        'pinyin': c.pinyin,
        'meaning': c.meaning,
        'level': c.level,
        'tags': c.tags.join(','),
        'other': c.other,
        'examples': c.examples,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
      progress?.call('Characters synced', stage, totalStages,
          currentItem: i + 1, totalItems: chars.length);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Group>> getAllGroups() async {
    if (!isSupported) return [];
    final db = _db;
    if (db == null) return [];
    final maps = await db.query('groups');
    return maps
        .map(
          (e) => Group(
            id: e['id'] as int,
            name: e['name'] as String,
            characterIds: (e['characters'] as String? ?? '')
                .split(',')
                .where((t) => t.isNotEmpty)
                .map(int.parse)
                .toList(),
          ),
        )
        .toList();
  }

  static Future<void> _saveGroups(
    List<Group> groups, {
    bool clearExisting = false,
    SyncProgress? progress,
    int stage = 0,
    int totalStages = 0,
  }) async {
    if (!isSupported) return;
    final db = _db;
    if (db == null) return;
    if (clearExisting) {
      await db.delete('groups');
    }
    final batch = db.batch();
    for (int i = 0; i < groups.length; i++) {
      final g = groups[i];
      batch.insert('groups', {
        'id': g.id,
        'name': g.name,
        'characters': g.characterIds.join(','),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
      progress?.call('Groups synced', stage, totalStages,
          currentItem: i + 1, totalItems: groups.length);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Batch>> getAllBatches() async {
    if (!isSupported) return [];
    final db = _db;
    if (db == null) return [];
    final maps = await db.query('batches');
    return maps
        .map(
          (e) => Batch(
            id: e['id'] as int,
            name: e['name'] as String,
            characters: (e['characters'] as String? ?? '')
                .split(',')
                .where((t) => t.isNotEmpty)
                .toList(),
          ),
        )
        .toList();
  }

  static Future<void> _saveBatches(
    List<Batch> batches, {
    bool clearExisting = false,
    SyncProgress? progress,
    int stage = 0,
    int totalStages = 0,
  }) async {
    if (!isSupported) return;
    final db = _db;
    if (db == null) return;
    if (clearExisting) {
      await db.delete('batches');
    }
    final batch = db.batch();
    for (int i = 0; i < batches.length; i++) {
      final b = batches[i];
      batch.insert('batches', {
        'id': b.id,
        'name': b.name,
        'characters': b.characters.join(','),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
      progress?.call('Batches synced', stage, totalStages,
          currentItem: i + 1, totalItems: batches.length);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> setSetting(String key, String value) async {
    if (!isSupported) return;
    final db = _db;
    if (db == null) return;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  static Future<String> getSetting(String key) async {
    if (!isSupported) return '';
    final db = _db;
    if (db == null) return '';
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isEmpty) return '';
    return res.first['value'] as String? ?? '';
  }

  static int nextTempId() => _tempId--;

  static Future<void> addLocalCharacter(Character c) async {
    await _saveCharacters([c]);
  }

  static Future<void> updateLocalCharacter(Character c) async {
    await _saveCharacters([c]);
  }

  static Future<void> deleteLocalCharacter(int id) async {
    final db = _db;
    if (db == null) return;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> addLocalGroup(Group g) async {
    await _saveGroups([g]);
  }

  static Future<void> updateLocalGroup(Group g) async {
    await _saveGroups([g]);
  }

  static Future<void> deleteLocalGroup(int id) async {
    final db = _db;
    if (db == null) return;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveLocalBatches(List<Batch> batches) async {
    await _saveBatches(batches, clearExisting: true);
  }

  static Future<int> downloadAll({SyncProgress? progress}) async {
    if (!isSupported) return 0;
    const total = 4;
    final chars = await CharacterApi.fetchAll(forceRemote: true);
    await _saveCharacters(chars,
        clearExisting: true,
        progress: progress,
        stage: 1,
        totalStages: total);

    final groups = await GroupApi.fetchAll(forceRemote: true);
    await _saveGroups(groups,
        clearExisting: true,
        progress: progress,
        stage: 2,
        totalStages: total);

    final batches = await BatchApi.fetchAll(forceRemote: true);
    await _saveBatches(batches,
        clearExisting: true,
        progress: progress,
        stage: 3,
        totalStages: total);

    const presetKey = 'layout_presets';
    const selectedKey = 'selected_layout_preset';
    final presetStr = await SettingsApi.getString(presetKey);
    final List list = presetStr.isEmpty ? [] : json.decode(presetStr);
    for (int i = 0; i < list.length; i++) {
      progress?.call('Layouts synced', 4, total,
          currentItem: i + 1, totalItems: list.length);
    }
    await setSetting(presetKey, presetStr);
    final sel = await SettingsApi.getString(selectedKey);
    await setSetting(selectedKey, sel);

    final size = await File(_dbPath).length();
    return size;
  }

  static Future<bool> hasConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isSupported) return false;
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) return false;
    try {
      final resp = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/ping'))
          .timeout(timeout);
      return resp.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<int> syncWithServer({SyncProgress? progress}) async {
    if (!isSupported) return 0;
    final db = _db;
    if (db != null) {
      final ops = await db.query('pending_ops', orderBy: 'updated_at');
      for (int i = 0; i < ops.length; i++) {
        progress?.call('Uploading pending operations', 0, 5,
            currentItem: i + 1, totalItems: ops.length);
        final op = ops[i];
        final payload = json.decode(op['payload'] as String);
        final type = op['op_type'] as String;
        switch (type) {
          case 'character_create':
            final map = Map<String, dynamic>.from(payload);
            map.remove('id');
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/characters'),
              headers: {
                'Content-Type': 'application/json',
                'X-API-Token': ApiConfig.apiToken,
              },
              body: json.encode(map),
            );
            break;
          case 'character_update':
            final c = Character.fromJson(payload);
            await CharacterApi.updateCharacter(c);
            break;
          case 'character_delete':
            await CharacterApi.deleteCharacter(payload['id'] as int);
            break;
          case 'group_create':
            await GroupApi.createGroup(
              payload['name'] as String,
              (payload['characters'] as List).cast<int>(),
            );
            break;
          case 'group_update':
            await GroupApi.updateGroup(
              payload['id'] as int,
              payload['name'] as String,
              (payload['characters'] as List).cast<int>(),
            );
            break;
          case 'group_delete':
            await GroupApi.deleteGroup(payload['id'] as int);
            break;
          case 'batches_save':
            final list = (payload['batches'] as List)
                .map((e) => Batch.fromJson(e as Map<String, dynamic>))
                .toList();
            await BatchApi.saveBatches(list);
            break;
        }
      }
      await db.delete('pending_ops');
    }
    return await downloadAll(progress: (msg, current, total,
        {int? currentItem, int? totalItems}) {
      progress?.call(msg, current + 1, total + 1,
          currentItem: currentItem, totalItems: totalItems);
    });
  }

  static Future<void> queueOperation(
    String type,
    Map<String, dynamic> payload,
  ) async {
    if (!isSupported) return;
    final db = _db;
    if (db == null) return;
    await db.insert('pending_ops', {
      'op_type': type,
      'payload': json.encode(payload),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
