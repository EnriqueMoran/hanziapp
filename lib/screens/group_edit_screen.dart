import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../api/group_api.dart';
import '../ui_scale.dart';
import 'package:reorderables/reorderables.dart';

class GroupEditScreen extends StatefulWidget {
  const GroupEditScreen({Key? key}) : super(key: key);

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class GroupEntry {
  GroupEntry(this.character, {this.selected = true});
  final Character character;
  bool selected;
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  List<Group> _groups = [];
  int? _selectedId;
  final Map<int, List<GroupEntry>> _groupMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chars = await CharacterApi.fetchAll();
    final groups = await GroupApi.fetchAll();
    if (!mounted) return;
    final map = <int, List<GroupEntry>>{};
    for (final g in groups) {
      final entries = <GroupEntry>[];
      for (final id in g.characterIds) {
        final match = chars.where((e) => e.id == id);
        if (match.isNotEmpty) entries.add(GroupEntry(match.first));
      }
      map[g.id] = entries;
    }
    setState(() {
      _groups = groups;
      _groupMap.clear();
      _groupMap.addAll(map);
      _selectedId = groups.isEmpty ? null : groups.first.id;
    });
  }

  List<GroupEntry> get _currentEntries =>
      _groupMap[_selectedId] ?? <GroupEntry>[];

  void _toggleEntry(GroupEntry entry) {
    setState(() => entry.selected = !entry.selected);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final list = _currentEntries;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
    });
  }

  void _save() async {
    final id = _selectedId;
    if (id != null) {
      final group = _groups.firstWhere((g) => g.id == id);
      await GroupApi.updateGroup(
        id,
        group.name,
        _currentEntries
            .where((e) => e.selected)
            .map((e) => e.character.id)
            .toList(),
      );
      if (!mounted) return;
      final count = _currentEntries.where((e) => e.selected).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${group.name}" saved with $count characters.'),
        ),
      );
    }
  }

  void _deleteGroup() async {
    final id = _selectedId;
    if (id == null) return;
    await GroupApi.deleteGroup(id);
    if (!mounted) return;
    setState(() {
      _groupMap.remove(id);
      _groups.removeWhere((g) => g.id == id);
      _selectedId = _groups.isEmpty ? null : _groups.first.id;
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const SizedBox.shrink();
    if (_selectedId != null) {
      content = SingleChildScrollView(
        child: ReorderableWrap(
          needsLongPressDraggable: true,
          onReorder: _reorder,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _currentEntries)
              Container(key: ValueKey(e.character.id), child: _buildTile(e)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Groups')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<int>(
              value: _selectedId,
              hint: const Text('Select group'),
              items: [
                for (final g in _groups)
                  DropdownMenuItem(value: g.id, child: Text(g.name)),
              ],
              onChanged: (v) => setState(() => _selectedId = v),
            ),
            const SizedBox(height: 16),
            Expanded(child: content),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmDelete,
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(GroupEntry entry) {
    final selected = entry.selected;
    return GestureDetector(
      onTap: () => _toggleEntry(entry),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.blue : Colors.grey),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              entry.character.character,
              style: TextStyle(fontSize: UiScale.tileFont),
            ),
            if (selected)
              const Positioned(
                top: -4,
                right: -4,
                child: Icon(Icons.check_circle, color: Colors.green, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
