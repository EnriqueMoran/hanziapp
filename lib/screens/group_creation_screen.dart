import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../api/group_api.dart';
import '../ui_scale.dart';
import '../layout_config.dart';
import 'package:reorderables/reorderables.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<Character> _allCharacters = [];
  final List<Character> _selected = [];
  bool _showGroupOnly = false;

  @override
  void initState() {
    super.initState();
    CharacterApi.fetchAll().then((list) {
      if (mounted) setState(() => _allCharacters = list);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isSelected(Character c) => _selected.any((e) => e.id == c.id);

  void _toggleCharacter(Character c) {
    setState(() {
      if (_isSelected(c)) {
        _selected.removeWhere((e) => e.id == c.id);
      } else {
        _selected.add(c);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _selected.removeAt(oldIndex);
      _selected.insert(newIndex, item);
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  void _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Name required'),
          content: const Text('Please enter a group name.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final id = await GroupApi.createGroup(
      _nameController.text.trim(),
      _selected.map((c) => c.id).toList(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Group "${_nameController.text}" saved${id != null ? ' (id $id)' : ''}.',
        ),
      ),
    );
    _nameController.clear();
    _clearSelection();
  }

  Widget _buildCharacterTile(Character c) {
    final selected = _isSelected(c);
    return GestureDetector(
      onTap: () => _toggleCharacter(c),
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
            Text(c.character, style: TextStyle(fontSize: UiScale.tileFont)),
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

  Widget _buildBrowserLayout(BuildContext context) {
    final items = _showGroupOnly ? _selected : _allCharacters;

    Widget content;
    if (_showGroupOnly) {
      content = SingleChildScrollView(
        child: ReorderableWrap(
          needsLongPressDraggable: true,
          onReorder: _reorder,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _selected)
              Container(key: ValueKey(c.id), child: _buildCharacterTile(c)),
          ],
        ),
      );
    } else {
      content = SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in items) _buildCharacterTile(c)],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
            const SizedBox(height: 16),
            Expanded(child: content),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showGroupOnly = false),
                    child: const Text('Show All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showGroupOnly = true),
                    child: const Text('Show Group'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveGroup,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearSelection,
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            ],
          ),
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
