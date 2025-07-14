import 'package:flutter/material.dart';
import '../api/batch_api.dart';
import '../api/group_api.dart';
import '../api/character_api.dart';
import '../api/settings_api.dart';
import 'character_review_screen.dart';
import '../ui_scale.dart';

class BatchGroupSelectionScreen extends StatefulWidget {
  const BatchGroupSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BatchGroupSelectionScreen> createState() =>
      _BatchGroupSelectionScreenState();
}

class _BatchGroupSelectionScreenState extends State<BatchGroupSelectionScreen> {
  List<Batch> _batches = [];
  List<Group> _groups = [];
  Batch? _selectedBatch;
  Group? _selectedGroup;
  bool _lastWasGroup = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final batches = await BatchApi.fetchAll();
    final groups = await GroupApi.fetchAll();
    final lastBatchId = await SettingsApi.getInt('last_batch_id');
    final lastGroupId = await SettingsApi.getInt('last_group_id');
    if (!mounted) return;
    setState(() {
      _batches = batches;
      _groups = groups;
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
      if (_selectedGroup != null) {
        _lastWasGroup = true;
      } else if (_selectedBatch != null) {
        _lastWasGroup = false;
      }
    });
  }

  String get _selectedName {
    if (_lastWasGroup && _selectedGroup != null) return _selectedGroup!.name;
    if (!_lastWasGroup && _selectedBatch != null) return _selectedBatch!.name;
    return '';
  }

  Future<void> _startReview() async {
    if (_selectedBatch == null && _selectedGroup == null) return;
    final chars = await CharacterApi.fetchAll();
    List<Character> subset;
    String label;
    int? batchId;
    int? groupId;
    if (_lastWasGroup && _selectedGroup != null) {
      subset = chars
          .where((c) => _selectedGroup!.characterIds.contains(c.id))
          .toList();
      label = _selectedGroup!.name;
      groupId = _selectedGroup!.id;
      await SettingsApi.setInt('last_group_id', groupId);
    } else if (_selectedBatch != null) {
      subset = chars
          .where((c) => _selectedBatch!.characters.contains(c.character))
          .toList();
      label = _selectedBatch!.name;
      batchId = _selectedBatch!.id;
      await SettingsApi.setInt('last_batch_id', batchId);
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

  @override
  Widget build(BuildContext context) {
    final batchDropdown = DropdownButton<Batch>(
      value: _selectedBatch,
      hint: const Text('Select batch'),
      items: [
        for (final b in _batches)
          DropdownMenuItem(value: b, child: Text(b.name)),
      ],
      onChanged: (b) => setState(() {
        _selectedBatch = b;
        if (b != null) _lastWasGroup = false;
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
        if (g != null) _lastWasGroup = true;
      }),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Batch or Group')),
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
            const Spacer(),
            Text('Selected: $_selectedName'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: UiScale.buttonStyle(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startReview,
                    style: UiScale.buttonStyle(),
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
}
