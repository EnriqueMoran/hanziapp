import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool random = true;

  static const double _otherHeight = 150;

  List<Character> characters = [];
  int currentIndex = 0;

  Character? get current =>
      characters.isEmpty ? null : characters[currentIndex];

  List<Offset?> _points = [];

  @override
  void initState() {
    super.initState();
    CharacterApi.fetchAll().then((list) {
      if (mounted) {
        setState(() {
          characters = list;
          currentIndex = 0;
        });
      }
    });
  }

  void _clearDrawing() {
    print("Canvas cleared.");
    setState(() => _points = []);
  }

  void _goToPreviousCharacter() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _clearDrawing();
      });
    }
  }

  void _goToNextCharacter() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        _clearDrawing();
      });
    }
  }

  String get currentCharacter => current?.character ?? '';
  String getCharacterAt(int offset) {
    int index = currentIndex + offset;
    if (index < 0 || index >= characters.length) return '';
    return characters[index].character;
  }

  @override
  Widget build(BuildContext context) {
    final characterRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPreviewCharacter(getCharacterAt(-2), 16),
        const SizedBox(width: 8),
        _buildPreviewCharacter(getCharacterAt(-1), 24),
        const SizedBox(width: 12),
        _buildPreviewCharacter(getCharacterAt(0), 48),
        const SizedBox(width: 12),
        _buildPreviewCharacter(getCharacterAt(1), 24),
        const SizedBox(width: 8),
        _buildPreviewCharacter(getCharacterAt(2), 16),
      ],
    );

    final pinyinWidget = Visibility(
      visible: showPinyin,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Text(
        current?.pinyin ?? '',
        style: const TextStyle(fontSize: 24),
        textAlign: TextAlign.left,
      ),
    );
    final meaningWidget = Visibility(
      visible: showTranslation,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Text(
        current?.meaning ?? '',
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.left,
      ),
    );

    final toggleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle('Auto sound', autoSound, (v) => setState(() => autoSound = v)),
        _buildToggle('Show hanzi', showHanzi, (v) => setState(() => showHanzi = v)),
        _buildToggle('Show pinyin', showPinyin, (v) => setState(() => showPinyin = v)),
        _buildToggle('Show translation', showTranslation, (v) => setState(() => showTranslation = v)),
      ],
    );

    final randomRestart = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _clearDrawing,
          child: const Text('RESTART'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('RANDOM'),
            Switch(value: random, onChanged: (v) => setState(() => random = v)),
          ],
        ),
      ],
    );

    final levelTags = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level: ${current?.level ?? ''}'),
        Text('Tags: ${current?.tags.join(', ') ?? ''}'),
      ],
    );

    final exampleArea = SizedBox(
      height: _otherHeight,
      child: SingleChildScrollView(
        child: Text(
          current?.other ?? '',
          textAlign: TextAlign.left,
        ),
      ),
    );

    final drawingHeight = MediaQuery.of(context).size.height / 4;
    final drawingArea = SizedBox(
      height: drawingHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              final localPosition = details.localPosition;
              setState(() => _points.add(localPosition));
            },
            onPanEnd: (_) {
              _points.add(null);
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
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
        },
      ),
    );

    final navigationRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _goToPreviousCharacter,
          child: const Text('PREVIOUS'),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: _clearDrawing,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('DELETE'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _goToNextCharacter,
              child: const Text('NEXT'),
            ),
          ],
        ),
      ],
    );

    Widget content;
    if (kIsWeb) {
      const double panelWidth = 220;
      final rightPanel = SizedBox(
        width: panelWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            toggleColumn,
            const SizedBox(height: 16),
            randomRestart,
            const SizedBox(height: 16),
            levelTags,
          ],
        ),
      );

      final leftColumn = Padding(
        padding: const EdgeInsets.only(right: panelWidth + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            characterRow,
            pinyinWidget,
            meaningWidget,
            const SizedBox(height: 8),
            exampleArea,
            const SizedBox(height: 8),
            drawingArea,
          ],
        ),
      );

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              leftColumn,
              Positioned(
                top: 0,
                right: 0,
                child: rightPanel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          navigationRow,
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          characterRow,
          pinyinWidget,
          meaningWidget,
          const SizedBox(height: 8),
          toggleColumn,
          const SizedBox(height: 8),
          randomRestart,
          const SizedBox(height: 8),
          levelTags,
          const SizedBox(height: 8),
          exampleArea,
          const SizedBox(height: 8),
          drawingArea,
          const SizedBox(height: 16),
          navigationRow,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Character Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildPreviewCharacter(String char, double size) {
    final display = showHanzi ? char : '';
    return Text(display, style: TextStyle(fontSize: size));
  }

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

  _DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
