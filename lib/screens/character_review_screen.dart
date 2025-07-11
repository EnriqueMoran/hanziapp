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
  bool random = false;

  bool _editing = false;
  late final TextEditingController _hanziController;
  late final TextEditingController _pinyinController;
  late final TextEditingController _meaningController;
  late final TextEditingController _detailsController;
  late final TextEditingController _rightController;

  String batchValue = 'None';
  List<Character> characters = [];
  int currentIndex = 0;
  List<Offset?> _points = [];

  // Placeholder for right-hand example box
  String _rightData =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';

  Character? get current =>
      characters.isEmpty ? null : characters[currentIndex];

  static const double _toggleWidth = 200;
  static const double _controlsWidth = 180;
  static const double _drawingHeightRatio = 0.25;

  // Prevent accents from changing line height
  static const StrutStyle _fixedStrut = StrutStyle(
    forceStrutHeight: true,
    height: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _hanziController = TextEditingController();
    _pinyinController = TextEditingController();
    _meaningController = TextEditingController();
    _detailsController = TextEditingController();
    _rightController = TextEditingController();

    // Fetch all characters on startup
    CharacterApi.fetchAll().then((list) {
      if (mounted) {
        setState(() {
          characters = list;
          currentIndex = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _hanziController.dispose();
    _pinyinController.dispose();
    _meaningController.dispose();
    _detailsController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  void _clearDrawing() => setState(() => _points = []);

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

  void _deleteCharacter() {
    // TODO: implement API delete and refresh
  }

  void _editCharacter() {
    if (!_editing) {
      // Enter editing mode: populate controllers
      setState(() {
        _editing = true;
        _hanziController.text = current?.character ?? '';
        _pinyinController.text = current?.pinyin ?? '';
        _meaningController.text = current?.meaning ?? '';
        _detailsController.text = current?.other ?? '';
        _rightController.text = _rightData;
      });
    } else {
      // Save changes
      if (current != null) {
        setState(() {
          characters[currentIndex] = Character(
            character: _hanziController.text,
            pinyin: _pinyinController.text,
            meaning: _meaningController.text,
            level: current!.level,
            tags: current!.tags,
            other: _detailsController.text,
          );
          _rightData = _rightController.text;
          _editing = false;
        });
      }
    }
  }

  void _cancelEdit() {
    // Cancel editing and revert controllers
    setState(() {
      _editing = false;
      _hanziController.text = current?.character ?? '';
      _pinyinController.text = current?.pinyin ?? '';
      _meaningController.text = current?.meaning ?? '';
      _detailsController.text = current?.other ?? '';
      _rightController.text = _rightData;
    });
  }

  String getCharacterAt(int offset) {
    final i = currentIndex + offset;
    if (i < 0 || i >= characters.length) return '';
    return characters[i].character;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = screenWidth / 3;
    final panelHeight = screenHeight * _drawingHeightRatio;

    // 1) Toggle switches
    final toggles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle('Auto Sound', autoSound, (v) => setState(() => autoSound = v)),
        _buildToggle('Show Hanzi', showHanzi, (v) => setState(() => showHanzi = v)),
        _buildToggle('Show Pinyin', showPinyin, (v) => setState(() => showPinyin = v)),
        _buildToggle('Show Translation', showTranslation, (v) => setState(() => showTranslation = v)),
      ],
    );

    // 2) Preview box
    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNeighbor(getCharacterAt(-2), 16),
            SizedBox(width: 12),
            _buildNeighbor(getCharacterAt(-1), 24),
            SizedBox(width: 24),
            _buildNeighbor(getCharacterAt(1), 24),
            SizedBox(width: 12),
            _buildNeighbor(getCharacterAt(2), 16),
          ],
        ),
        SizedBox(height: 12),
        if (_editing)
          TextField(
            controller: _hanziController,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 48),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              showHanzi ? (current?.character ?? '') : '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 48),
            ),
          ),
        SizedBox(height: 8),
        if (_editing || showPinyin)
          (_editing
              ? TextField(
                  controller: _pinyinController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontFamily: 'NotoSans'),
                )
              : SelectableText(
                  current?.pinyin ?? '',
                  strutStyle: _fixedStrut,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontFamily: 'NotoSans'),
                )),
        SizedBox(height: 6),
        if (_editing || showTranslation)
          (_editing
              ? TextField(
                  controller: _meaningController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                )
              : SelectableText(
                  current?.meaning ?? '',
                  strutStyle: _fixedStrut,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                )),
      ],
    );

    // 3) Controls
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: _clearDrawing, child: Text('RESTART')),
        SizedBox(height: 8),
        Row(children: [
          Text('RANDOM'),
          Switch(value: random, onChanged: (v) => setState(() => random = v)),
        ]),
        SizedBox(height: 8),
        Text('Batch: $batchValue', style: TextStyle(fontSize: 16)),
      ],
    );

    // 4) Example area: left and right boxes
    final exampleArea = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left box (details)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _editing
                  ? TextField(
                      controller: _detailsController,
                      maxLines: null,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(fontSize: 14),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        current?.other ?? '',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
            ),
          ),
          // Right box (lorem ipsum)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _editing
                  ? TextField(
                      controller: _rightController,
                      maxLines: null,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(fontSize: 14),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _rightData,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    // 5) Level & tags
    final levelTags = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText('Level: ${current?.level ?? ''}'),
        SizedBox(height: 4),
        SelectableText('Tags: ${current?.tags.join(', ')}'),
      ],
    );

    // 6) Drawing section with centered panel
    final drawingSection = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _deleteCharacter,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('DELETE CHARACTER'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _editCharacter,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _editing ? Colors.green : null),
                    child: Text(_editing ? 'SAVE CHANGES' : 'EDIT CHARACTER'),
                  ),
                  if (_editing) ...[
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _cancelEdit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('CANCEL CHANGES'),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
              levelTags,
            ],
          ),
        ),
        SizedBox(
          width: panelWidth,
          height: panelHeight,
          child: LayoutBuilder(builder: (ctx, cons) {
            return GestureDetector(
              onPanUpdate: (details) =>
                  setState(() => _points.add(details.localPosition)),
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
                  child: SizedBox.expand(),
                ),
              ),
            );
          }),
        ),
        Expanded(child: SizedBox()),
      ],
    );

    // 7) Navigation buttons
    final navigation = Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _clearDrawing,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('DELETE'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _goToPreviousCharacter,
            child: Text('PREVIOUS'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _goToNextCharacter,
            child: Text('NEXT'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Character Review')),
      body: Padding(
        padding: EdgeInsets.all(24),
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
            SizedBox(height: 24),
            exampleArea,
            SizedBox(height: 24),
            drawingSection,
            SizedBox(height: 12),
            navigation,
          ],
        ),
      ),
    );
  }

  /// Builds a neighbor-character preview
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
      final p1 = points[i], p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
