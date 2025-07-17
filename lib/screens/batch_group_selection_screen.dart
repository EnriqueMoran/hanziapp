import 'package:flutter/material.dart';
import '../api/batch_api.dart';
import '../api/group_api.dart';
import '../api/character_api.dart';
import '../api/settings_api.dart';
import '../device_type.dart';
import 'character_review_screen.dart';

class BatchGroupSelectionScreen extends StatefulWidget {
  const BatchGroupSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BatchGroupSelectionScreen> createState() =>
      _BatchGroupSelectionScreenState();
}

class _BatchGroupSelectionScreenState extends State<BatchGroupSelectionScreen> {
  List<Batch> _batches = [];
  List<Group> _groups = [];
  List<String> _tags = [];
  List<String> _levels = [];

  Batch? _selectedBatch;
  Group? _selectedGroup;
  String? _selectedTag;
  String? _selectedLevel;

  /// One of 'batch', 'group', 'tag', 'level', or null for no selection.
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final batches = await BatchApi.fetchAll();
    final groups = await GroupApi.fetchAll();
    final tags = await CharacterApi.fetchTags();
    final chars = await CharacterApi.fetchAll();

    final levelsSet = <String>{};
    for (final c in chars) {
      if (c.level.isNotEmpty) levelsSet.add(c.level);
    }
    final levels = levelsSet.toList()..sort();

    final lastBatchId = await SettingsApi.getInt('last_batch_id');
    final lastGroupId = await SettingsApi.getInt('last_group_id');
    final lastTag = await SettingsApi.getString('last_tag');
    final lastLevel = await SettingsApi.getString('last_level');

    if (!mounted) return;
    setState(() {
      _batches = batches;
      _groups = groups;
      _tags = tags;
      _levels = levels;

      _selectedBatch = null;
      for (final b in batches) {
        if (b.id == lastBatchId) {
          _selectedBatch = b;
          break;
        }
      }
      _selectedGroup = null;
      for (final g in groups) {
        if (g.id == lastGroupId) {
          _selectedGroup = g;
          break;
        }
      }
      _selectedTag = tags.contains(lastTag) ? lastTag : null;
      _selectedLevel = levels.contains(lastLevel) ? lastLevel : null;

      if (_selectedGroup != null) {
        _filterType = 'group';
      } else if (_selectedBatch != null) {
        _filterType = 'batch';
      } else if (_selectedTag != null) {
        _filterType = 'tag';
      } else if (_selectedLevel != null) {
        _filterType = 'level';
      } else {
        _filterType = null;
      }
    });
  }

  String get _selectedName {
    switch (_filterType) {
      case 'group':
        return _selectedGroup?.name ?? '';
      case 'batch':
        return _selectedBatch?.name ?? '';
      case 'tag':
        return _selectedTag ?? '';
      case 'level':
        return _selectedLevel ?? '';
      default:
        return '';
    }
  }

  Future<void> _startReview() async {
    if (_filterType == null) return;
    final chars = await CharacterApi.fetchAll();
    List<Character> subset;
    String label;
    int? batchId;
    int? groupId;
    if (_filterType == 'group' && _selectedGroup != null) {
      subset = chars
          .where((c) => _selectedGroup!.characterIds.contains(c.id))
          .toList();
      label = _selectedGroup!.name;
      groupId = _selectedGroup!.id;
      await SettingsApi.setInt('last_group_id', groupId);
    } else if (_filterType == 'batch' && _selectedBatch != null) {
      subset = chars
          .where((c) => _selectedBatch!.characters.contains(c.character))
          .toList();
      label = _selectedBatch!.name;
      batchId = _selectedBatch!.id;
      await SettingsApi.setInt('last_batch_id', batchId);
    } else if (_filterType == 'tag' && _selectedTag != null) {
      subset = chars.where((c) => c.tags.contains(_selectedTag)).toList();
      label = _selectedTag!;
      await SettingsApi.setString('last_tag', _selectedTag!);
    } else if (_filterType == 'level' && _selectedLevel != null) {
      subset = chars.where((c) => c.level == _selectedLevel).toList();
      label = _selectedLevel!;
      await SettingsApi.setString('last_level', _selectedLevel!);
    } else {
      subset = chars;
      label = '';
    }

    if (subset.isEmpty) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterReviewScreen(
          initialCharacters: subset,
          batchValue: label,
          batchId: batchId,
          groupId: groupId,
        ),
      ),
    );
  }

  Widget _buildBrowserLayout(BuildContext context) {
    final batchDropdown = DropdownButton<Batch>(
      value: _selectedBatch,
      hint: const Text('Select batch'),
      items: [
        for (final b in _batches)
          DropdownMenuItem(value: b, child: Text(b.name)),
      ],
      onChanged: (b) => setState(() {
        _selectedBatch = b;
        if (b != null) {
          _filterType = 'batch';
          _selectedGroup = null;
          _selectedTag = null;
          _selectedLevel = null;
        }
      }),
    );

    final groupDropdown = DropdownButton<Group>(
      value: _selectedGroup,
      hint: const Text('Select group'),
      items: [
        for (final g in _groups)
          DropdownMenuItem(value: g, child: Text(g.name)),
      ],
      onChanged: (g) => setState(() {
        _selectedGroup = g;
        if (g != null) {
          _filterType = 'group';
          _selectedBatch = null;
          _selectedTag = null;
          _selectedLevel = null;
        }
      }),
    );

    final tagDropdown = DropdownButton<String>(
      value: _selectedTag,
      hint: const Text('Select tag'),
      items: [
        for (final t in _tags) DropdownMenuItem(value: t, child: Text(t)),
      ],
      onChanged: (t) => setState(() {
        _selectedTag = t;
        if (t != null) {
          _filterType = 'tag';
          _selectedBatch = null;
          _selectedGroup = null;
          _selectedLevel = null;
        }
      }),
    );

    final levelDropdown = DropdownButton<String>(
      value: _selectedLevel,
      hint: const Text('Select level'),
      items: [
        for (final l in _levels) DropdownMenuItem(value: l, child: Text(l)),
      ],
      onChanged: (l) => setState(() {
        _selectedLevel = l;
        if (l != null) {
          _filterType = 'level';
          _selectedBatch = null;
          _selectedGroup = null;
          _selectedTag = null;
        }
      }),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Characters')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: batchDropdown),
                const SizedBox(width: 8),
                Expanded(child: groupDropdown),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: tagDropdown),
                const SizedBox(width: 8),
                Expanded(child: levelDropdown),
              ],
            ),
            const Spacer(),
            Text('Selected: $_selectedName'),
            const SizedBox(height: 8),
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
                    onPressed: _startReview,
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) => _buildBrowserLayout(context);

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
