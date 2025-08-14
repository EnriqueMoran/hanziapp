import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import '../api/character_api.dart';

class OfflineService {
  static Database? _db;
  static bool isOffline = false;

  static Future<void> init() async {
    final path = join(await getDatabasesPath(), 'hanzi.db');
    _db = await openDatabase(
      path,
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
          CREATE TABLE pending_ops(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op_type TEXT,
            payload TEXT,
            updated_at INTEGER
          )
        ''');
      },
    );
  }

  static Future<List<Character>> getAllCharacters() async {
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

  static Future<void> _saveCharacters(List<Character> chars) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    for (final c in chars) {
      batch.insert(
        'characters',
        {
          'id': c.id,
          'character': c.character,
          'pinyin': c.pinyin,
          'meaning': c.meaning,
          'level': c.level,
          'tags': c.tags.join(','),
          'other': c.other,
          'examples': c.examples,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> downloadAll() async {
    final remote = await CharacterApi.fetchAll(forceRemote: true);
    await _saveCharacters(remote);
  }

  static Future<bool> hasConnection() async {
    if (Platform.isAndroid) {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    }
    return false;
  }

  static Future<void> syncWithServer() async {
    final db = _db;
    if (db != null) {
      final ops = await db.query('pending_ops', orderBy: 'updated_at');
      for (final op in ops) {
        final payload = json.decode(op['payload'] as String);
        final type = op['op_type'] as String;
        final c = Character.fromJson(payload);
        if (type == 'create') {
          await CharacterApi.createCharacter(c);
        } else if (type == 'update') {
          await CharacterApi.updateCharacter(c);
        } else if (type == 'delete') {
          await CharacterApi.deleteCharacter(c.id);
        }
      }
      await db.delete('pending_ops');
    }
    await downloadAll();
  }

  static Future<void> queueOperation(String type, Character c) async {
    final db = _db;
    if (db == null) return;
    await db.insert('pending_ops', {
      'op_type': type,
      'payload': json.encode(c.toJson()),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
