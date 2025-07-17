import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../api/character_api.dart';
import '../api/settings_api.dart';
import '../ui_scale.dart';
import '../layout_config.dart';
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
  bool editing = false;

  late final TextEditingController hanziController;
  late final TextEditingController pinyinController;
  late final TextEditingController meaningController;
  late final TextEditingController detailsController;
  late final TextEditingController examplesController;
  late final TextEditingController levelController;
  late final TextEditingController tagsController;
  List<String> allTags = [];

  String batchLabel = 'None';
  List<Character> characters = [];
  int currentIndex = 0;

  List<Offset?> points = [];

  final mlkit.DigitalInkRecognizerModelManager modelManager =
  mlkit.DigitalInkRecognizerModelManager();
  late final mlkit.DigitalInkRecognizer inkRecognizer;
  final mlkit.Ink ink = mlkit.Ink();
  List<mlkit.StrokePoint> strokePoints = [];
  String recognizedText = '';
  double? recognizedScore;
  Timer? recognizeDebounce;
  String recognizerStatus = 'verifying model...';
  bool modelReady = false;

  final AudioPlayer player = AudioPlayer();
  bool hasAudio = false;

  Character? get current =>
      characters.isEmpty ? null : characters[currentIndex];

  static const StrutStyle fixedStrut = StrutStyle(
    forceStrutHeight: true,
    height: 1.0,
  );

  @override
  void initState() {
    super.initState();
    initializeRecognizer();
    hanziController = TextEditingController();
    pinyinController = TextEditingController();
    meaningController = TextEditingController();
    detailsController = TextEditingController();
    examplesController = TextEditingController();
    levelController = TextEditingController();
    tagsController = TextEditingController();
    CharacterApi.fetchTags().then((tags) {
      if (mounted) setState(() => allTags = tags);
    });
    if (widget.initialCharacters != null) {
      characters = List.of(widget.initialCharacters!);
      batchLabel = widget.batchValue != null && widget.batchValue!.isNotEmpty
          ? widget.batchValue!
          : 'None';
      loadInitialIndex();
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
          updateLastCharacter(characters[currentIndex].id);
          checkAudioAvailable();
          if (autoSound && hasAudio) playAudio();
        }
      });
    }
  }

  @override
  void dispose() {
    hanziController.dispose();
    pinyinController.dispose();
    meaningController.dispose();
    detailsController.dispose();
    examplesController.dispose();
    levelController.dispose();
    tagsController.dispose();
    recognizeDebounce?.cancel();
    super.dispose();
  }

  void clearDrawing() => setState(() {
    points = [];
    ink.strokes.clear();
    strokePoints.clear();
    recognizedText = '';
    recognizedScore = null;
  });

  Future<void> chooseTag() async {
    if (allTags.isEmpty) return;
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Tag'),
        children: [
          for (final t in allTags)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t),
            ),
        ],
      ),
    );
    if (tag != null) {
      final text = tagsController.text;
      final prefix = text.isNotEmpty && !text.trim().endsWith(',')
          ? '$text,'
          : text;
      setState(() => tagsController.text = '$prefix$tag,');
      tagsController.selection = TextSelection.fromPosition(
        TextPosition(offset: tagsController.text.length),
      );
    }
  }

  Future<void> checkAudioAvailable() async {
    final char = current?.character;
    if (char == null || char.isEmpty) {
      setState(() => hasAudio = false);
      return;
    }
    final encoded = Uri.encodeComponent(char);
    final url = 'https://data.dong-chinese.com/hsk-audio/$encoded.mp3';
    try {
      await player.stop();
      await player.setSourceUrl(url);
      setState(() => hasAudio = true);
    } catch (_) {
      setState(() => hasAudio = false);
    }
  }

  Future<void> playAudio() async {
    final char = current?.character;
    if (char == null || char.isEmpty) return;
    final encoded = Uri.encodeComponent(char);
    final url = 'https://data.dong-chinese.com/hsk-audio/$encoded.mp3';
    try {
      await player.stop();
      await player.setSourceUrl(url);
      await player.resume();
    } catch (_) {}
  }

  Future<void> initializeRecognizer() async {
    setState(() => recognizerStatus = 'verifying model...');
    inkRecognizer = mlkit.DigitalInkRecognizer(languageCode: 'zh-Hani');
    try {
      final downloaded = await modelManager.isModelDownloaded('zh-Hani');
      if (!downloaded) {
        setState(() => recognizerStatus = 'downloading model...');
        await modelManager.downloadModel('zh-Hani');
      }
      setState(() {
        recognizerStatus = 'model ready';
        modelReady = true;
      });
    } catch (e) {
      setState(() => recognizerStatus = e.toString());
    }
  }

  void queueRecognition() {
    recognizeDebounce?.cancel();
    recognizeDebounce = Timer(
      const Duration(milliseconds: 300),
      recognizeInk,
    );
  }

  Future<void> recognizeInk() async {
    if (!modelReady || ink.strokes.isEmpty) return;
    try {
      final candidates = await inkRecognizer.recognize(ink);
      if (candidates.isNotEmpty) {
        final candidate = candidates.first;
        final text = candidate.text.trim();
        setState(() {
          recognizedText = text;
          recognizedScore = candidate.score;
        });
        if (text == current?.character) {
          goToNextCharacter();
        }
      }
    } catch (_) {}
  }

  void goToPreviousCharacter() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        clearDrawing();
      });
      updateLastCharacter(current!.id);
      checkAudioAvailable();
      if (autoSound && hasAudio) playAudio();
    }
  }

  void goToNextCharacter() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        clearDrawing();
      });
      updateLastCharacter(current!.id);
      checkAudioAvailable();
      if (autoSound && hasAudio) playAudio();
    }
  }

  void deleteCharacter() {
    if (current == null) return;
    CharacterApi.deleteCharacter(current!.id).then((_) {
      setState(() {
        characters.removeAt(currentIndex);
        currentIndex = currentIndex.clamp(0, characters.length - 1);
      });
      if (characters.isNotEmpty) {
        updateLastCharacter(current!.id);
        checkAudioAvailable();
        if (autoSound && hasAudio) playAudio();
      }
    });
  }

  void toggleEdit() {
    if (!editing) {
      setState(() {
        editing = true;
        hanziController.text = current?.character ?? '';
        pinyinController.text = current?.pinyin ?? '';
        meaningController.text = current?.meaning ?? '';
        detailsController.text = current?.other ?? '';
        examplesController.text = current?.examples ?? '';
        levelController.text = current?.level ?? '';
        tagsController.text = current!.tags.join(',');
      });
    } else {
      if (current == null) return;
      if (hanziController.text.trim().isEmpty ||
          pinyinController.text.trim().isEmpty ||
          meaningController.text.trim().isEmpty ||
          levelController.text.trim().isEmpty) {
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
          character: hanziController.text,
          pinyin: pinyinController.text,
          meaning: meaningController.text,
          level: levelController.text,
          tags: tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          other: detailsController.text,
          examples: examplesController.text,
        );
        CharacterApi.updateCharacter(characters[currentIndex]);
        CharacterApi.fetchTags().then((tags) {
          if (mounted) setState(() => allTags = tags);
        });
        updateLastCharacter(current!.id);
        editing = false;
        checkAudioAvailable();
      });
    }
  }

  void cancelEdit() {
    setState(() {
      editing = false;
      hanziController.text = current?.character ?? '';
      pinyinController.text = current?.pinyin ?? '';
      meaningController.text = current?.meaning ?? '';
      detailsController.text = current?.other ?? '';
      examplesController.text = current?.examples ?? '';
      levelController.text = current?.level ?? '';
      tagsController.text = current!.tags.join(',');
    });
  }

  Future<void> loadInitialIndex() async {
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
      updateLastCharacter(characters[currentIndex].id);
      checkAudioAvailable();
      if (autoSound && hasAudio) playAudio();
    }
  }

  void updateLastCharacter(int id) {
    if (widget.batchId != null) {
      SettingsApi.setInt('last_batch_character', id);
    } else if (widget.groupId != null) {
      SettingsApi.setInt('last_group_character', id);
    } else {
      SettingsApi.setInt('last_reviewed_character', id);
    }
  }

  void restartReview() {
    if (widget.batchId != null) {
      SettingsApi.setInt('last_batch_character', null);
    } else if (widget.groupId != null) {
      SettingsApi.setInt('last_group_character', null);
    } else {
      SettingsApi.setInt('last_reviewed_character', null);
    }
    setState(() {
      currentIndex = 0;
      points = [];
      ink.strokes.clear();
      strokePoints.clear();
    });
    checkAudioAvailable();
    if (autoSound && hasAudio) playAudio();
  }

  String neighborAt(int offset) {
    final i = currentIndex + offset;
    if (i < 0 || i >= characters.length) return '';
    return characters[i].character;
  }

  Widget _buildLayout(BuildContext context, LayoutConfig layout) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final exampleHeight = screenH * layout.exampleHeightRatio;
    final drawingHeight = screenH * layout.drawingHeightRatio;
    final contentWidth = screenW - 48;
    final panelWidth = contentWidth * layout.panelWidthRatio;

    final showAllToggles = DeviceConfig.deviceType != DeviceType.smartphone;
    final toggles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle('Auto Sound', autoSound, (v) {
          setState(() => autoSound = v);
          if (v && hasAudio) playAudio();
        }),
        if (showAllToggles)
          _buildToggle('Show Hanzi', showHanzi,
                  (v) => setState(() => showHanzi = v)),
        if (showAllToggles)
          _buildToggle('Show Pinyin', showPinyin,
                  (v) => setState(() => showPinyin = v)),
        if (showAllToggles)
          _buildToggle('Show Translation', showTranslation,
                  (v) => setState(() => showTranslation = v)),
      ],
    );

    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNeighbor(neighborAt(-2), UiScale.smallFont),
            SizedBox(width: 12),
            _buildNeighbor(neighborAt(-1), UiScale.mediumFont),
            SizedBox(width: 24),
            _buildNeighbor(neighborAt(1), UiScale.mediumFont),
            SizedBox(width: 12),
            _buildNeighbor(neighborAt(2), UiScale.smallFont),
          ],
        ),
        SizedBox(height: 12),
        if (editing)
          TextField(
            controller: hanziController,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: UiScale.largeFont),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              showHanzi ? (current?.character ?? '') : '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: UiScale.largeFont),
            ),
          ),
        SizedBox(height: 8),
        if (editing || showPinyin)
          editing
              ? TextField(
            controller: pinyinController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: UiScale.mediumFont,
              fontFamily: 'NotoSans',
            ),
          )
              : SelectableText(
            current?.pinyin ?? '',
            strutStyle: fixedStrut,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: UiScale.mediumFont,
              fontFamily: 'NotoSans',
            ),
          ),
        SizedBox(height: 6),
        if (editing || showTranslation)
          editing
              ? TextField(
            controller: meaningController,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: UiScale.smallFont),
          )
              : SelectableText(
            current?.meaning ?? '',
            strutStyle: fixedStrut,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: UiScale.smallFont),
          ),
      ],
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: restartReview, child: Text('RESTART')),
        SizedBox(height: 8),
        ElevatedButton(
            onPressed: hasAudio ? playAudio : null, child: Text('LISTEN')),
      ],
    );

    final exampleArea = SizedBox(
      height: exampleHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border: Border.all(color: Color.fromARGB(255, 36, 99, 121)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: editing
                  ? TextField(
                controller: detailsController,
                maxLines: null,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: UiScale.detailFont),
              )
                  : SingleChildScrollView(
                child: SelectableText(
                  current?.other ?? '',
                  style: TextStyle(fontSize: UiScale.detailFont),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border: Border.all(color: Color.fromARGB(255, 36, 99, 121)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: editing
                  ? TextField(
                controller: examplesController,
                maxLines: null,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: UiScale.detailFont),
              )
                  : SingleChildScrollView(
                child: SelectableText(
                  current?.examples ?? '',
                  style: TextStyle(fontSize: UiScale.detailFont),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Character Review')),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: UiScale.toggleWidth, child: toggles),
                    Expanded(child: Center(child: previewBox)),
                    SizedBox(width: UiScale.controlsWidth, child: controls),
                  ],
                ),
                SizedBox(height: 24),
                exampleArea,
                SizedBox(height: 16),
                // Only show delete/edit buttons on tablet/browser, not on smartphone
                if (DeviceConfig.deviceType != DeviceType.smartphone)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: deleteCharacter,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: Text('DELETE CHARACTER'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: toggleEdit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                              editing ? Colors.green : null),
                          child: Text(
                              editing ? 'SAVE CHANGES' : 'EDIT CHARACTER'),
                        ),
                        if (editing) ...[
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: cancelEdit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text('CANCEL CHANGES'),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (layout.showTouchPanel)
                  SizedBox(height: drawingHeight + 56),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (layout.showTouchPanel)
                    SizedBox(
                      height: drawingHeight,
                      width: contentWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _infoColumn()),
                          SizedBox(
                            width: panelWidth,
                            child: GestureDetector(
                              onPanStart: (details) {
                                setState(() =>
                                    points.add(details.localPosition));
                                strokePoints = [];
                                strokePoints.add(mlkit.StrokePoint(
                                    x: details.localPosition.dx,
                                    y: details.localPosition.dy,
                                    t: DateTime.now()
                                        .millisecondsSinceEpoch));
                                ink.strokes
                                    .add(mlkit.Stroke()..points = List.of(strokePoints));
                              },
                              onPanUpdate: (details) {
                                setState(() =>
                                    points.add(details.localPosition));
                                strokePoints.add(mlkit.StrokePoint(
                                    x: details.localPosition.dx,
                                    y: details.localPosition.dy,
                                    t: DateTime.now()
                                        .millisecondsSinceEpoch));
                                ink.strokes.last.points =
                                    List.of(strokePoints);
                                queueRecognition();
                              },
                              onPanEnd: (_) {
                                setState(() => points.add(null));
                                strokePoints = [];
                                queueRecognition();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(12)),
                                child: CustomPaint(
                                    painter: _DrawingPainter(points: points),
                                    child: SizedBox.expand()),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                !modelReady
                                    ? 'Recognized drawing: $recognizerStatus'
                                    : 'Recognized drawing: ${recognizedText.isEmpty ? recognizerStatus : recognizedText}${recognizedScore != null ? ' (${(recognizedScore! * 100).toStringAsFixed(1)}%)' : ''}',
                                style:
                                TextStyle(fontSize: UiScale.smallFont),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Align(alignment: Alignment.centerLeft, child: _infoColumn()),
                  SizedBox(height: layout.showTouchPanel ? 16 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (layout.showTouchPanel)
                        ElevatedButton(
                            onPressed: clearDrawing,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text('DELETE')),
                      if (layout.showTouchPanel) SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: goToPreviousCharacter,
                          child: Text('PREVIOUS')),
                      SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: goToNextCharacter, child: Text('NEXT')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserLayout(BuildContext context) =>
      _buildLayout(context, LayoutConfig.forType(DeviceType.browser));

  Widget _buildTabletLayout(BuildContext context) =>
      _buildLayout(context, LayoutConfig.forType(DeviceType.tablet));

  Widget _buildSmartphoneLayout(BuildContext context) =>
      _buildLayout(context, LayoutConfig.forType(DeviceType.smartphone));

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

  Widget _infoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editing
            ? TextField(
            controller: levelController,
            decoration: InputDecoration(labelText: 'Level'))
            : SelectableText('Level: ${current?.level ?? ''}'),
        SizedBox(height: 4),
        editing
            ? Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagsController,
                decoration: InputDecoration(labelText: 'Tags'),
              ),
            ),
            IconButton(onPressed: chooseTag, icon: Icon(Icons.list)),
          ],
        )
            : SelectableText('Tags: ${current?.tags.join(', ')}'),
        SizedBox(height: 8),
        SelectableText('Batch/Group: $batchLabel',
            style: TextStyle(fontSize: UiScale.smallFont)),
      ],
    );
  }

  Widget _buildNeighbor(String char, double size) {
    return SelectableText(showHanzi ? char : '',
        textAlign: TextAlign.center, style: TextStyle(fontSize: size));
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(children: [Text(label), Switch(value: value, onChanged: onChanged)]);
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
