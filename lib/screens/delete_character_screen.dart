import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../ui_scale.dart';

class DeleteCharacterScreen extends StatefulWidget {
  const DeleteCharacterScreen({Key? key}) : super(key: key);

  @override
  State<DeleteCharacterScreen> createState() => _DeleteCharacterScreenState();
}

class _DeleteCharacterScreenState extends State<DeleteCharacterScreen> {
  List<Character> _characters = [];
  final Set<int> _selected = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chars = await CharacterApi.fetchAll();
    if (mounted) setState(() => _characters = chars);
  }

  bool _isSelected(Character c) => _selected.contains(c.id);

  void _toggle(Character c) {
    setState(() {
      if (_selected.remove(c.id)) {
        // already removed
      } else {
        _selected.add(c.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (final id in _selected) {
      await CharacterApi.deleteCharacter(id);
    }
    if (!mounted) return;
    setState(() {
      _characters.removeWhere((c) => _selected.contains(c.id));
      _selected.clear();
    });
  }

  void _confirmDelete() {
    if (_selected.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete characters?'),
        content: Text(
          'Are you sure you want to delete ${_selected.length} characters?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelected();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Character c) {
    final selected = _isSelected(c);
    return GestureDetector(
      onTap: () => _toggle(c),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Characters')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final c in _characters) _buildTile(c)],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    onPressed: _confirmDelete,
                    child: const Text('Delete'),
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
