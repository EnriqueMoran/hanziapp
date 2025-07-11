import 'package:flutter/material.dart';
import '../api/character_api.dart';

class CharacterReviewScreen extends StatefulWidget {
  const CharacterReviewScreen({Key? key}) : super(key: key);

  @override
  State<CharacterReviewScreen> createState() => _CharacterReviewScreenState();
}

class _CharacterReviewScreenState extends State<CharacterReviewScreen> {
  bool autoSound = false;
  bool showHanzi = true;
  bool showPinyin = true;
  bool showTranslation = true;
  bool random = false; // Random disabled by default

  // Placeholder for batch value; will be fetched from the database in future
  String batchValue = 'None';

  List<Character> characters = [];
  int currentIndex = 0;
  List<Offset?> _points = [];

  Character? get current => characters.isEmpty ? null : characters[currentIndex];

  static const double _toggleWidth = 200;
  static const double _controlsWidth = 180;
  static const double _drawingHeightRatio = 0.25;

  // Fixed strut to prevent accents from changing line height
  static const StrutStyle _fixedStrut = StrutStyle(
    forceStrutHeight: true,
    height: 1.0,
  );

  @override
  void initState() {
    super.initState();
    // Fetch all characters on init
    CharacterApi.fetchAll().then((list) {
      if (mounted) {
        setState(() {
          characters = list;
          currentIndex = 0;
        });
        if (list.isNotEmpty) {
          CharacterApi.setLastReviewed(list[0].id);
        }
      }
    });
    // TODO: in the future, load batchValue from API/database here
  }

  // Clear the drawing strokes
  void _clearDrawing() => setState(() => _points = []);

  // Navigate to the previous character
  void _goToPreviousCharacter() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _clearDrawing();
      });
      CharacterApi.setLastReviewed(current!.id);
    }
  }

  // Navigate to the next character
  void _goToNextCharacter() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        _clearDrawing();
      });
      CharacterApi.setLastReviewed(current!.id);
    }
  }

  // Delete the current character
  void _deleteCharacter() async {
    final c = current;
    if (c == null) return;
    final success = await CharacterApi.deleteCharacter(c.id);
    if (success) {
      setState(() {
        characters.removeAt(currentIndex);
        if (currentIndex >= characters.length) {
          currentIndex = characters.isEmpty ? 0 : characters.length - 1;
        }
      });
      if (characters.isNotEmpty) {
        CharacterApi.setLastReviewed(current!.id);
      }
    }
  }

  // Edit the current character via a simple dialog
  void _editCharacter() async {
    final c = current;
    if (c == null) return;
    final pinyinCtrl = TextEditingController(text: c.pinyin);
    final meaningCtrl = TextEditingController(text: c.meaning);
    final levelCtrl = TextEditingController(text: c.level);
    final tagsCtrl = TextEditingController(text: c.tags.join(','));
    final otherCtrl = TextEditingController(text: c.other);
    final examplesCtrl = TextEditingController(text: c.examples);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Character'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: pinyinCtrl, decoration: const InputDecoration(labelText: 'Pinyin')),
                TextField(controller: meaningCtrl, decoration: const InputDecoration(labelText: 'Meaning')),
                TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: 'Level')),
                TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
                TextField(controller: otherCtrl, decoration: const InputDecoration(labelText: 'Other')),
                TextField(controller: examplesCtrl, decoration: const InputDecoration(labelText: 'Examples')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (result == true) {
      final updated = Character(
        id: c.id,
        character: c.character,
        pinyin: pinyinCtrl.text,
        meaning: meaningCtrl.text,
        level: levelCtrl.text,
        tags: tagsCtrl.text.split(',').where((e) => e.trim().isNotEmpty).toList(),
        other: otherCtrl.text,
        examples: examplesCtrl.text,
      );
      final success = await CharacterApi.updateCharacter(updated);
      if (success) {
        setState(() => characters[currentIndex] = updated);
      }
    }
  }

  // Get neighbour character at a given offset
  String getCharacterAt(int offset) {
    final i = currentIndex + offset;
    if (i < 0 || i >= characters.length) return '';
    return characters[i].character;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 1) Toggle switches for options
    final toggles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle('Auto Sound', autoSound, (v) => setState(() => autoSound = v)),
        _buildToggle('Show Hanzi', showHanzi, (v) => setState(() => showHanzi = v)),
        _buildToggle('Show Pinyin', showPinyin, (v) => setState(() => showPinyin = v)),
        _buildToggle('Show Translation', showTranslation, (v) => setState(() => showTranslation = v)),
      ],
    );

    // 2) Preview box with neighbours, character, pinyin, and translation
    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNeighbor(getCharacterAt(-2), 16),
            const SizedBox(width: 12),
            _buildNeighbor(getCharacterAt(-1), 24),
            const SizedBox(width: 24),
            _buildNeighbor(getCharacterAt(1), 24),
            const SizedBox(width: 12),
            _buildNeighbor(getCharacterAt(2), 16),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: SelectableText(
            showHanzi ? (current?.character ?? '') : '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48),
          ),
        ),
        const SizedBox(height: 8),
        if (showPinyin)
          SelectableText(
            current?.pinyin ?? '',
            strutStyle: _fixedStrut,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontFamily: 'NotoSans'),
          ),
        const SizedBox(height: 6),
        if (showTranslation)
          SelectableText(
            current?.meaning ?? '',
            strutStyle: _fixedStrut,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
      ],
    );

    // 3) Controls: restart, random toggle, and batch info
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _clearDrawing,
          child: const Text('RESTART'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('RANDOM'),
            Switch(
              value: random,
              onChanged: (v) => setState(() => random = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Batch: $batchValue',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );

    // 4) Example data area with two equal-sized boxes
    final exampleArea = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // make both fill the height
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  current?.other ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  current?.examples ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // 5) Level & Tags display
    final levelTags = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText('Level: ${current?.level ?? ''}'),
        const SizedBox(height: 4),
        SelectableText('Tags: ${current?.tags.join(', ')}'),
      ],
    );

    // 6) Drawing area with delete/edit and level/tags
    final drawingSection = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _deleteCharacter,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('DELETE CHARACTER'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _editCharacter,
                  child: const Text('EDIT CHARACTER'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            levelTags,
          ],
        ),
        const Spacer(),
        SizedBox(
          width: screenWidth / 3,
          height: screenHeight * _drawingHeightRatio,
          child: LayoutBuilder(builder: (ctx, cons) {
            return GestureDetector(
              onPanUpdate: (details) => setState(() => _points.add(details.localPosition)),
              onPanEnd: (_) => _points.add(null),
              child: Container(
                width: cons.maxWidth,
                height: cons.maxHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _DrawingPainter(points: _points),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          }),
        ),
        const Spacer(flex: 2),
      ],
    );

    // 7) Navigation buttons below drawing
    final navigation = Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _clearDrawing,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _goToPreviousCharacter, child: const Text('PREVIOUS')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _goToNextCharacter, child: const Text('NEXT')),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Character Review')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: _toggleWidth, child: toggles),
                Expanded(child: Center(child: previewBox)),
                SizedBox(width: _controlsWidth, child: controls),
              ],
            ),
            const SizedBox(height: 24),
            exampleArea,
            const SizedBox(height: 24),
            drawingSection,
            const SizedBox(height: 12),
            navigation,
          ],
        ),
      ),
    );
  }

  /// Builds a neighbour-character preview
  Widget _buildNeighbor(String char, double size) {
    return SelectableText(
      showHanzi ? char : '',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size),
    );
  }

  /// Builds a toggle row with label and switch
  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  const _DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
