import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../api/character_api.dart';
import '../api/settings_api.dart';
import 'dart:async';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

class CharacterReviewScreen extends StatefulWidget {
  final List<Character>? initialCharacters;
  final String? batchValue;
  final int? batchId;
  final int? groupId;

  const CharacterReviewScreen({
    Key? key,
    this.initialCharacters,
    this.batchValue,
    this.batchId,
    this.groupId,
  }) : super(key: key);

  @override
  State<CharacterReviewScreen> createState() => _CharacterReviewScreenState();
}

class _CharacterReviewScreenState extends State<CharacterReviewScreen> {
  bool autoSound = false;
  bool showHanzi = true;
  bool showPinyin = true;
  bool showTranslation = true;
  bool _editing = false;

  // Text controllers for editing
  late final TextEditingController _hanziController;
  late final TextEditingController _pinyinController;
  late final TextEditingController _meaningController;
  late final TextEditingController _detailsController;
  late final TextEditingController _rightController;
  late final TextEditingController _levelController;
  late final TextEditingController _tagsController;
  List<String> _allTags = [];

  // State for batch label, character list and index
  String batchValue = 'None';
  List<Character> characters = [];
  int currentIndex = 0;

  // Drawing points for handwriting panel
  List<Offset?> _points = [];

  // Digital ink recognition
  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();
  late final mlkit.DigitalInkRecognizer _inkRecognizer;
  final mlkit.Ink _ink = mlkit.Ink();
  List<mlkit.StrokePoint> _strokePoints = [];
  String _recognizedText = '';
  double? _recognizedScore;
  Timer? _recognizeDebounce;
  String _recognizerStatus = 'verificando modelo...';
  bool _modelReady = false;

  // Audio player and flag for audio availability
  final AudioPlayer _player = AudioPlayer();
  bool _hasAudio = false;

  Character? get current =>
      characters.isEmpty ? null : characters[currentIndex];

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static const double _drawingHeightRatio = 0.25;
  static const double _drawingHeightRatioAndroid = 0.20;
  static const double _exampleHeightRatioAndroid = 0.22;
  static const double _toggleWidth = 200;
  static const double _controlsWidth = 180;

  // Prevent accents from changing line height
  static const StrutStyle _fixedStrut = StrutStyle(
    forceStrutHeight: true,
    height: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeRecognizer();
    _hanziController = TextEditingController();
    _pinyinController = TextEditingController();
    _meaningController = TextEditingController();
    _detailsController = TextEditingController();
    _rightController = TextEditingController();
    _levelController = TextEditingController();
    _tagsController = TextEditingController();
    CharacterApi.fetchTags().then((tags) {
      if (mounted) setState(() => _allTags = tags);
    });

    if (widget.initialCharacters != null) {
      characters = List.of(widget.initialCharacters!);
      batchValue = (widget.batchValue != null && widget.batchValue!.isNotEmpty)
          ? widget.batchValue!
          : 'None';
      _loadInitialIndex();
    } else {
      CharacterApi.fetchAll().then((list) async {
        if (!mounted) return;
        int start = 0;
        final id = await SettingsApi.getInt('last_reviewed_character');
        if (id != null) {
          final idx = list.indexWhere((c) => c.id == id);
          if (idx >= 0) start = idx;
        }
        setState(() {
          characters = list;
          currentIndex = start;
        });
        if (characters.isNotEmpty) {
          _updateLastCharacter(characters[currentIndex].id);
          _checkAudioAvailable();
          if (autoSound && _hasAudio) _playAudio();
        }
      });
    }
  }

  @override
  void dispose() {
    _hanziController.dispose();
    _pinyinController.dispose();
    _meaningController.dispose();
    _detailsController.dispose();
    _rightController.dispose();
    _levelController.dispose();
    _tagsController.dispose();
    _recognizeDebounce?.cancel();
    super.dispose();
  }

  /// Clears the drawing panel and ink data.
  void _clearDrawing() => setState(() {
        _points = [];
        _ink.strokes.clear();
        _strokePoints.clear();
        _recognizedText = '';
        _recognizedScore = null;
      });

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
      final prefix =
          text.isNotEmpty && !text.trim().endsWith(',') ? '$text,' : text;
      setState(() => _tagsController.text = '$prefix$tag,');
      _tagsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tagsController.text.length),
      );
    }
  }

  /// Checks audio availability by trying to set the audio URL.
  Future<void> _checkAudioAvailable() async {
    final char = current?.character;
    if (char == null || char.isEmpty) {
      setState(() => _hasAudio = false);
      return;
    }

    final encodedChar = Uri.encodeComponent(char);
    final url = 'https://data.dong-chinese.com/hsk-audio/$encodedChar.mp3';

    try {
      await _player.stop();
      //await _player.setUrl(url);
      await _player.setSourceUrl(url);
      setState(() => _hasAudio = true);
    } catch (_) {
      setState(() => _hasAudio = false);
    }
  }

  /// Plays the character audio.
  Future<void> _playAudio() async {
    final char = current?.character;
    if (char == null || char.isEmpty) return;

    final encodedChar = Uri.encodeComponent(char);
    final url = 'https://data.dong-chinese.com/hsk-audio/$encodedChar.mp3';

    try {
      await _player.stop();
      //await _player.setUrl(url);
      await _player.setSourceUrl(url);
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _initializeRecognizer() async {
    setState(() => _recognizerStatus = 'verifying model...');
    _inkRecognizer = mlkit.DigitalInkRecognizer(languageCode: 'zh-Hani');
    try {
      final downloaded = await _modelManager.isModelDownloaded('zh-Hani');
      if (!downloaded) {
        setState(() => _recognizerStatus = 'downloading model...');
        await _modelManager.downloadModel('zh-Hani');
      }
      setState(() {
        _recognizerStatus = 'model ready';
        _modelReady = true;
      });
    } catch (e) {
      setState(() => _recognizerStatus = 'error: ' + e.toString());
    }
  }

  void _queueRecognition() {
    _recognizeDebounce?.cancel();
    _recognizeDebounce = Timer(
      const Duration(milliseconds: 300),
      _recognizeInk,
    );
  }

  Future<void> _recognizeInk() async {
    if (!_modelReady || _ink.strokes.isEmpty) return;
    try {
      final candidates = await _inkRecognizer.recognize(_ink);
      if (candidates.isNotEmpty) {
        final candidate = candidates.first;
        final text = candidate.text.trim();
        setState(() {
          _recognizedText = text;
          _recognizedScore = candidate.score;
        });
        if (text == current?.character) {
          _goToNextCharacter();
        }
      }
    } catch (e) {
      debugPrint('Recognition error: $e');
    }
  }

  /// Navigate to previous character and update audio flag.
  void _goToPreviousCharacter() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _clearDrawing();
      });
      _updateLastCharacter(current!.id);
      _checkAudioAvailable();
      if (autoSound && _hasAudio) _playAudio();
    }
  }

  /// Navigate to next character and update audio flag.
  void _goToNextCharacter() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        _clearDrawing();
      });
      _updateLastCharacter(current!.id);
      _checkAudioAvailable();
      if (autoSound && _hasAudio) _playAudio();
    }
  }

  /// Delete the current character, update list and audio flag.
  void _deleteCharacter() {
    if (current == null) return;
    CharacterApi.deleteCharacter(current!.id).then((_) {
      setState(() {
        characters.removeAt(currentIndex);
        currentIndex = currentIndex.clamp(0, characters.length - 1);
      });
      if (characters.isNotEmpty) {
        _updateLastCharacter(current!.id);
        _checkAudioAvailable();
        if (autoSound && _hasAudio) _playAudio();
      }
    });
  }

  /// Toggle edit mode or save changes.
  void _editCharacter() {
    if (!_editing) {
      // Enter editing: populate controllers
      setState(() {
        _editing = true;
        _hanziController.text = current?.character ?? '';
        _pinyinController.text = current?.pinyin ?? '';
        _meaningController.text = current?.meaning ?? '';
        _detailsController.text = current?.other ?? '';
        _rightController.text = current?.examples ?? '';
        _levelController.text = current?.level ?? '';
        _tagsController.text = current!.tags.join(',');
      });
    } else {
      // Save changes
      if (current == null) return;
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
      setState(() {
        characters[currentIndex] = Character(
          id: current!.id,
          character: _hanziController.text,
          pinyin: _pinyinController.text,
          meaning: _meaningController.text,
          level: _levelController.text,
          tags: _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          other: _detailsController.text,
          examples: _rightController.text,
        );
        CharacterApi.updateCharacter(characters[currentIndex]);
        CharacterApi.fetchTags().then((tags) {
          if (mounted) setState(() => _allTags = tags);
        });
        _updateLastCharacter(current!.id);
        _editing = false;
        _checkAudioAvailable();
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _hanziController.text = current?.character ?? '';
      _pinyinController.text = current?.pinyin ?? '';
      _meaningController.text = current?.meaning ?? '';
      _detailsController.text = current?.other ?? '';
      _rightController.text = current?.examples ?? '';
      _levelController.text = current?.level ?? '';
      _tagsController.text = current!.tags.join(',');
    });
  }

  Future<void> _loadInitialIndex() async {
    int start = 0;
    if (widget.batchId != null) {
      final id = await SettingsApi.getInt('last_batch_character');
      if (id != null) {
        final idx = characters.indexWhere((c) => c.id == id);
        if (idx >= 0) start = idx;
      }
    } else if (widget.groupId != null) {
      final id = await SettingsApi.getInt('last_group_character');
      if (id != null) {
        final idx = characters.indexWhere((c) => c.id == id);
        if (idx >= 0) start = idx;
      }
    } else {
      final id = await SettingsApi.getInt('last_reviewed_character');
      if (id != null) {
        final idx = characters.indexWhere((c) => c.id == id);
        if (idx >= 0) start = idx;
      }
    }
    if (!mounted) return;
    setState(() => currentIndex = start);
    if (characters.isNotEmpty) {
      _updateLastCharacter(characters[currentIndex].id);
      _checkAudioAvailable();
      if (autoSound && _hasAudio) _playAudio();
    }
  }

  void _updateLastCharacter(int id) {
    if (widget.batchId != null) {
      SettingsApi.setInt('last_batch_character', id);
    } else if (widget.groupId != null) {
      SettingsApi.setInt('last_group_character', id);
    } else {
      SettingsApi.setInt('last_reviewed_character', id);
    }
  }

  void _restartReview() {
    if (widget.batchId != null) {
      SettingsApi.setInt('last_batch_character', null);
    } else if (widget.groupId != null) {
      SettingsApi.setInt('last_group_character', null);
    } else {
      SettingsApi.setInt('last_reviewed_character', null);
    }
    setState(() {
      currentIndex = 0;
      _points = [];
      _ink.strokes.clear();
      _strokePoints.clear();
    });
    _checkAudioAvailable();
    if (autoSound && _hasAudio) _playAudio();
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
    final panelHeight = screenHeight *
        (_isAndroid ? _drawingHeightRatioAndroid : _drawingHeightRatio);
    final exampleHeight =
        _isAndroid ? screenHeight * _exampleHeightRatioAndroid : null;

    // 1) Toggle switches
    final toggles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle('Auto Sound', autoSound, (v) {
          setState(() => autoSound = v);
          if (v && _hasAudio) _playAudio();
        }),
        _buildToggle(
          'Show Hanzi',
          showHanzi,
          (v) => setState(() => showHanzi = v),
        ),
        _buildToggle(
          'Show Pinyin',
          showPinyin,
          (v) => setState(() => showPinyin = v),
        ),
        _buildToggle(
          'Show Translation',
          showTranslation,
          (v) => setState(() => showTranslation = v),
        ),
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

    // 3) Controls with LISTEN enabled only if audio exists
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: _restartReview, child: Text('RESTART')),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _hasAudio ? _playAudio : null,
          child: const Text('LISTEN'),
        ),
      ],
    );

    // 4) Example area
    final exampleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left box (details)
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: 4),
            padding: EdgeInsets.all(8),
            constraints:
                _isAndroid ? BoxConstraints(maxHeight: exampleHeight!) : null,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
              border: Border.all(color: const Color.fromARGB(255, 36, 99, 121)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _editing
                ? TextField(
                    controller: _detailsController,
                    maxLines: _isAndroid ? 4 : null,
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
        // Right box (examples)
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: 4),
            padding: EdgeInsets.all(8),
            constraints:
                _isAndroid ? BoxConstraints(maxHeight: exampleHeight!) : null,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
              border: Border.all(color: const Color.fromARGB(255, 36, 99, 121)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _editing
                ? TextField(
                    controller: _rightController,
                    maxLines: _isAndroid ? 4 : null,
                    decoration: InputDecoration(border: InputBorder.none),
                    style: TextStyle(fontSize: 14),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      current?.examples ?? '',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
          ),
        ),
      ],
    );
    final exampleArea = _isAndroid
        ? SizedBox(height: exampleHeight, child: exampleRow)
        : Expanded(child: exampleRow);

    // 5) Level & tags
    final levelTags = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _editing
            ? TextField(
                controller: _levelController,
                decoration: const InputDecoration(labelText: 'Level'),
              )
            : SelectableText('Level: ${current?.level ?? ''}'),
        const SizedBox(height: 4),
        _editing
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(labelText: 'Tags'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: _chooseTag,
                  ),
                ],
              )
            : SelectableText('Tags: ${current?.tags.join(', ')}'),
        const SizedBox(height: 8),
        Text('Batch/ Group: $batchValue', style: TextStyle(fontSize: 16)),
      ],
    );

    // 6) Drawing section
    final buttonsRow = Row(
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
            backgroundColor: _editing ? Colors.green : null,
          ),
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
    );

    final recognizedBox = Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            !_modelReady
                ? 'Recognized drawing: $_recognizerStatus'
                : 'Recognized drawing: '
                    '${_recognizedText.isEmpty ? _recognizerStatus : _recognizedText}'
                    '${_recognizedScore != null ? ' (${(_recognizedScore! * 100).toStringAsFixed(1)}%)' : ''}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );

    final drawingPanel = SizedBox(
      width: panelWidth,
      height: panelHeight,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          return GestureDetector(
            onPanStart: (details) {
              setState(() => _points.add(details.localPosition));
              _strokePoints = [];
              _strokePoints.add(
                mlkit.StrokePoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                  t: DateTime.now().millisecondsSinceEpoch,
                ),
              );
              _ink.strokes.add(mlkit.Stroke()..points = List.of(_strokePoints));
            },
            onPanUpdate: (details) {
              setState(() => _points.add(details.localPosition));
              _strokePoints.add(
                mlkit.StrokePoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                  t: DateTime.now().millisecondsSinceEpoch,
                ),
              );
              if (_ink.strokes.isNotEmpty) {
                _ink.strokes.last.points = List.of(_strokePoints);
              }
              _queueRecognition();
            },
            onPanEnd: (_) {
              setState(() => _points.add(null));
              _strokePoints = [];
              _queueRecognition();
            },
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
        },
      ),
    );

    final drawingSection = screenWidth < 650
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buttonsRow,
              SizedBox(height: 16),
              levelTags,
              SizedBox(height: 16),
              drawingPanel,
              SizedBox(height: 8),
              recognizedBox,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [buttonsRow, SizedBox(height: 16), levelTags],
                ),
              ),
              drawingPanel,
              Expanded(child: recognizedBox),
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
          ElevatedButton(onPressed: _goToNextCharacter, child: Text('NEXT')),
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

  Widget _buildNeighbor(String char, double size) {
    return SelectableText(
      showHanzi ? char : '',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size),
    );
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
