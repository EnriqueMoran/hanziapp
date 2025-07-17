import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../ui_scale.dart';
import '../layout_config.dart';

class AddCharacterScreen extends StatefulWidget {
  const AddCharacterScreen({Key? key}) : super(key: key);

  @override
  State<AddCharacterScreen> createState() => _AddCharacterScreenState();
}

class _AddCharacterScreenState extends State<AddCharacterScreen> {
  final _hanziController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _meaningController = TextEditingController();
  final _detailsController = TextEditingController();
  final _examplesController = TextEditingController();
  final _levelController = TextEditingController();
  final _tagsController = TextEditingController();
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    CharacterApi.fetchTags().then((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
  }

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

  Future<void> _chooseTag() async {
    if (_allTags.isEmpty) return;
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Tag'),
        children: [
          for (final t in _allTags)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t),
            ),
        ],
      ),
    );
    if (tag != null) {
      final text = _tagsController.text;
      final prefix = text.isNotEmpty && !text.trim().endsWith(',')
          ? '$text,'
          : text;
      setState(() => _tagsController.text = '$prefix$tag,');
      _tagsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tagsController.text.length),
      );
    }
  }

  Future<void> _save() async {
    if (_hanziController.text.trim().isEmpty ||
        _pinyinController.text.trim().isEmpty ||
        _meaningController.text.trim().isEmpty ||
        _levelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill hanzi, pinyin, translation and level.'),
        ),
      );
      return;
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Character added.')));
    _clearAll();
    CharacterApi.fetchTags().then((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
  }

  Widget _buildBrowserLayout(BuildContext context) {
    final layout = DeviceConfig.layout;
    final screenH = MediaQuery.of(context).size.height;
    final exampleHeight = screenH * layout.exampleHeightRatio;

    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _hanziController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Hanzi'),
          style: TextStyle(fontSize: UiScale.largeFont),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pinyinController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Pinyin'),
          style: TextStyle(
            fontSize: UiScale.mediumFont,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _meaningController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Translation'),
          style: TextStyle(fontSize: UiScale.smallFont),
        ),
      ],
    );

    final exampleArea = SizedBox(
      height: exampleHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border: Border.all(
                  color: const Color.fromARGB(255, 36, 99, 121),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Notes',
                ),
                style: TextStyle(fontSize: UiScale.detailFont),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border: Border.all(
                  color: const Color.fromARGB(255, 36, 99, 121),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _examplesController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Examples',
                ),
                style: TextStyle(fontSize: UiScale.detailFont),
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
          decoration: InputDecoration(
            labelText: 'Tags (comma separated)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.list),
              onPressed: _chooseTag,
            ),
          ),
        ),
      ],
    );

    final formSection = levelTags;

    final buttons = Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _clearAll,
            style: buttonStyle(),
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: buttonStyle(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _save,
            style: buttonStyle(),
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
                SizedBox(width: UiScale.toggleWidth),
                Expanded(child: Center(child: previewBox)),
                SizedBox(width: UiScale.controlsWidth),
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
