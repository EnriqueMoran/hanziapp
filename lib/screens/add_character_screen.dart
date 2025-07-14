import 'package:flutter/material.dart';
import '../api/character_api.dart';

class AddCharacterScreen extends StatefulWidget {
  const AddCharacterScreen({Key? key}) : super(key: key);

  @override
  State<AddCharacterScreen> createState() => _AddCharacterScreenState();
}

class _AddCharacterScreenState extends State<AddCharacterScreen> {
  static const double _toggleWidth = 200;
  static const double _controlsWidth = 180;

  final _hanziController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _meaningController = TextEditingController();
  final _detailsController = TextEditingController();
  final _examplesController = TextEditingController();
  final _levelController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _hanziController.dispose();
    _pinyinController.dispose();
    _meaningController.dispose();
    _detailsController.dispose();
    _examplesController.dispose();
    _levelController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _hanziController.clear();
      _pinyinController.clear();
      _meaningController.clear();
      _detailsController.clear();
      _examplesController.clear();
      _levelController.clear();
      _tagsController.clear();
    });
  }

  Future<void> _save() async {
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await CharacterApi.createCharacter(
      Character(
        id: 0,
        character: _hanziController.text,
        pinyin: _pinyinController.text,
        meaning: _meaningController.text,
        level: _levelController.text,
        tags: tags,
        other: _detailsController.text,
        examples: _examplesController.text,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _hanziController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Hanzi'),
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pinyinController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Pinyin'),
          style: const TextStyle(fontSize: 20, fontFamily: 'NotoSans'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _meaningController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Translation'),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );

    final exampleArea = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border:
                    Border.all(color: const Color.fromARGB(255, 36, 99, 121)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Notes',
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border:
                    Border.all(color: const Color.fromARGB(255, 36, 99, 121)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _examplesController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Examples',
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );

    final levelTags = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _levelController,
          decoration: const InputDecoration(labelText: 'Level'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
        ),
      ],
    );

    final formSection = levelTags;

    final buttons = Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _clearAll,
            child: const Text('Clear'),
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
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Character')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: _toggleWidth),
                Expanded(child: Center(child: previewBox)),
                const SizedBox(width: _controlsWidth),
              ],
            ),
            const SizedBox(height: 24),
            exampleArea,
            const SizedBox(height: 24),
            formSection,
            const SizedBox(height: 12),
            buttons,
          ],
        ),
      ),
    );
  }
}

