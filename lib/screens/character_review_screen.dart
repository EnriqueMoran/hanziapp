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
  bool random = true;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Character Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Character line: previous, current, next
            Row(
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
            ),

            Visibility(
              visible: showPinyin,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(current?.pinyin ?? '', style: const TextStyle(fontSize: 24)),
            ),
            Visibility(
              visible: showTranslation,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(current?.meaning ?? '', style: const TextStyle(fontSize: 20)),
            ),

            const SizedBox(height: 8),

            // Toggles and info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToggle("Auto sound", autoSound, (v) => setState(() => autoSound = v)),
                    _buildToggle("Show hanzi", showHanzi, (v) => setState(() => showHanzi = v)),
                    _buildToggle("Show pinyin", showPinyin, (v) => setState(() => showPinyin = v)),
                    _buildToggle("Show translation", showTranslation, (v) => setState(() => showTranslation = v)),
                  ],
                ),
                // Level and tags
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Level: ${current?.level ?? ''}'),
                    Text('Tags: ${current?.tags.join(', ') ?? ''}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Restart + Random
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _clearDrawing,
                  child: const Text("RESTART"),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text("RANDOM"),
                    Switch(
                      value: random,
                      onChanged: (v) => setState(() => random = v),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Examples and usage notes
            Row(
              children: [
                Expanded(child: Text(current?.other ?? '')),
              ],
            ),

            const SizedBox(height: 16),

            // Drawing area with LayoutBuilder
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      final localPosition = details.localPosition;
                      print("Drawing at: $localPosition");
                      setState(() => _points.add(localPosition));
                    },
                    onPanEnd: (_) {
                      print("Stroke ended.");
                      _points.add(null);
                    },
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.black26),
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
            ),

            const SizedBox(height: 8),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _goToPreviousCharacter,
                  child: const Text("PREVIOUS"),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _clearDrawing,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("DELETE"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _goToNextCharacter,
                      child: const Text("NEXT"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
      ..color = Colors.black87
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
