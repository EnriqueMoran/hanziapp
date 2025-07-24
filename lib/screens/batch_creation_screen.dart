import 'dart:math';

import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../api/batch_api.dart';
import '../layout_config.dart';

class BatchCreationScreen extends StatefulWidget {
  const BatchCreationScreen({Key? key}) : super(key: key);

  @override
  State<BatchCreationScreen> createState() => _BatchCreationScreenState();
}

class _BatchCreationScreenState extends State<BatchCreationScreen> {
  final TextEditingController _sizeController = TextEditingController();
  final List<int> _percentages = [1, 5, 10, 15, 20];
  bool _random = true;

  List<Character> _allCharacters = [];
  List<Character> _characters = [];
  List<String> _levels = [];
  List<String> _tags = [];
  String? _selectedLevel;
  String? _selectedTag;

  int get _total => _characters.length;
  int get _batchCount {
    final size = int.tryParse(_sizeController.text) ?? 0;
    if (size <= 0 || _total == 0) return 0;
    return (_total + size - 1) ~/ size;
  }

  @override
  void initState() {
    super.initState();
    CharacterApi.fetchAll().then((list) {
      if (!mounted) return;
      final levelsSet = <String>{};
      for (final c in list) {
        if (c.level.isNotEmpty) levelsSet.add(c.level);
      }
      final levels = levelsSet.toList()..sort();
      setState(() {
        _allCharacters = list;
        _characters = list;
        _levels = levels;
        _selectedLevel = null;
        _selectedTag = null;
      });
    });
    CharacterApi.fetchTags().then((tags) {
      if (mounted) setState(() => _tags = tags);
    });
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _setFromPercent(int percent) {
    if (_total == 0) return;
    final size = max(1, (_total * percent / 100).floor());
    setState(() {
      _sizeController.text = size.toString();
    });
  }

  void _updateCharacters() {
    var list = _allCharacters;
    if (_selectedLevel != null) {
      list = list.where((c) => c.level == _selectedLevel).toList();
    }
    if (_selectedTag != null) {
      list = list.where((c) => c.tags.contains(_selectedTag)).toList();
    }
    _characters = list;
  }

  void _applyLevel(String? level) {
    setState(() {
      _selectedLevel = level;
      _updateCharacters();
    });
  }

  void _applyTag(String? tag) {
    setState(() {
      _selectedTag = tag;
      _updateCharacters();
    });
  }

  void _createBatches() async {
    final size = int.tryParse(_sizeController.text) ?? 0;
    if (size <= 0 || _total == 0) return;

    final chars = _characters.map((e) => e.character).toList();
    if (_random) chars.shuffle();

    final batches = <Batch>[];
    int index = 0;
    int count = 1;
    while (index < chars.length) {
      final end = min(index + size, chars.length);
      final sub = chars.sublist(index, end);
      batches.add(Batch(id: 0, name: 'Batch $count', characters: sub));
      index = end;
      count++;
    }

    await BatchApi.saveBatches(batches);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created ${batches.length} batches.')),
    );
    Navigator.pop(context);
  }

  Widget _buildBrowserLayout(BuildContext context) {
    final percentButtons = [
      for (final p in _percentages)
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _setFromPercent(p),
              child: Text('$p%'),
            ),
            const SizedBox(height: 4),
            Text('${(_total * p / 100).floor()}'),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Batch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String?>(
              value: _selectedLevel,
              hint: const Text('All characters'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All characters'),
                ),
                for (final l in _levels)
                  DropdownMenuItem<String?>(value: l, child: Text(l)),
              ],
              onChanged: _applyLevel,
            ),
            const SizedBox(height: 12),
            DropdownButton<String?>(
              value: _selectedTag,
              hint: const Text('Any tag'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any tag'),
                ),
                for (final t in _tags)
                  DropdownMenuItem<String?>(value: t, child: Text(t)),
              ],
              onChanged: _applyTag,
            ),
            const SizedBox(height: 12),
            Text('Total characters: $_total'),
            const SizedBox(height: 12),
            TextField(
              controller: _sizeController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Characters per batch',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: percentButtons),
            const SizedBox(height: 12),
            Text('Total batches: $_batchCount'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Random'),
                Switch(
                  value: _random,
                  onChanged: (v) => setState(() => _random = v),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createBatches,
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) =>
      _buildBrowserLayout(context);

  Widget _buildSmartphoneLayout(BuildContext context) =>
      _buildBrowserLayout(context);

  @override
  Widget build(BuildContext context) {
    switch (DeviceConfig.deviceType) {
      case DeviceType.tablet:
        return _buildTabletLayout(context);
      case DeviceType.smartphone:
        return _buildSmartphoneLayout(context);
      case DeviceType.browser:
      default:
        return _buildBrowserLayout(context);
    }
  }
}
