import 'package:flutter/material.dart';
import '../api/character_api.dart';
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
  List<String> _groups = [];
  String? _selectedGroup;
  final Map<String, List<GroupEntry>> _groupMap = {};

  @override
  void initState() {
    super.initState();
    CharacterApi.fetchAll().then((list) {
      if (mounted) {
        final g1 = <GroupEntry>[];
        final g2 = <GroupEntry>[];
        for (var i = 0; i < list.length; i++) {
          final entry = GroupEntry(list[i]);
          (i.isEven ? g1 : g2).add(entry);
        }
        setState(() {
          _groupMap['Group 1'] = g1;
          _groupMap['Group 2'] = g2;
          _groups = _groupMap.keys.toList();
          _selectedGroup = _groups.isEmpty ? null : _groups.first;
        });
      }
    });
  }

  List<GroupEntry> get _currentEntries =>
      _groupMap[_selectedGroup] ?? <GroupEntry>[];

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

  void _save() {
    if (_selectedGroup != null) {
      final count = _currentEntries.where((e) => e.selected).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Group "$_selectedGroup" saved with $count characters.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const SizedBox.shrink();
    if (_selectedGroup != null) {
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
            DropdownButton<String>(
              value: _selectedGroup,
              hint: const Text('Select group'),
              items: [
                for (final g in _groups)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) => setState(() => _selectedGroup = v),
            ),
            const SizedBox(height: 16),
            Expanded(child: content),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
              style: const TextStyle(fontSize: 24),
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
