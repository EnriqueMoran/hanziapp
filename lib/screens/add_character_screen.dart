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
  static const double _drawingHeightRatio = 0.25;

  final _hanziController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _meaningController = TextEditingController();
  final _detailsController = TextEditingController();
  final _examplesController = TextEditingController();
  final _levelController = TextEditingController();
  final _tagsController = TextEditingController();

  List<Offset?> _points = [];

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
      _points = [];
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

  void _drawUpdate(Offset pos) => setState(() => _points.add(pos));
  void _drawEnd() => setState(() => _points.add(null));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = screenWidth / 3;
    final panelHeight = screenHeight * _drawingHeightRatio;

    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _hanziController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pinyinController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontFamily: 'NotoSans'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _meaningController,
          textAlign: TextAlign.center,
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
                decoration: const InputDecoration(border: InputBorder.none),
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
                decoration: const InputDecoration(border: InputBorder.none),
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

    final drawingSection = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: levelTags),
        SizedBox(
          width: panelWidth,
          height: panelHeight,
          child: LayoutBuilder(
            builder: (ctx, cons) {
              return GestureDetector(
                onPanUpdate: (d) => _drawUpdate(d.localPosition),
                onPanEnd: (_) => _drawEnd(),
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
            },
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );

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
            drawingSection,
            const SizedBox(height: 12),
            buttons,
          ],
        ),
      ),
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
      final p1 = points[i], p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
