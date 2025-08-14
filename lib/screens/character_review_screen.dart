import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../api/character_api.dart';
import '../api/group_api.dart';
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
  final String? level;
  final String? tag;
  final bool recordHistory;

  const CharacterReviewScreen({
    Key? key,
    this.initialCharacters,
    this.batchValue,
    this.batchId,
    this.groupId,
    this.level,
    this.tag,
    this.recordHistory = true,
  }) : super(key: key);

  @override
  State<CharacterReviewScreen> createState() => _CharacterReviewScreenState();
}

class _CharacterReviewScreenState extends State<CharacterReviewScreen> {
  bool autoSound = false;
  bool showHanzi = true;
  bool showPinyin = true;
  bool showTranslation = true;
  bool showTouchPanel = !kIsWeb;
  bool showInfoText = DeviceConfig.deviceType != DeviceType.smartphone;
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
  List<Group> groups = [];
  bool addingToGroup = false;
  int? selectedGroupId;

  Character? get current =>
      characters.isEmpty ? null : characters[currentIndex];

  String get _storageKey {
    if (widget.batchId != null) {
      return 'last_batch_${widget.batchId}_character';
    } else if (widget.groupId != null) {
      return 'last_group_${widget.groupId}_character';
    } else if (widget.tag != null && widget.tag!.isNotEmpty) {
      return 'last_tag_${widget.tag}_character';
    } else if (widget.level != null && widget.level!.isNotEmpty) {
      return 'last_level_${widget.level}_character';
    }
    return 'last_reviewed_character';
  }

  String get _reviewType {
    if (widget.groupId != null) return 'group';
    if (widget.batchId != null) return 'batch';
    if (widget.tag != null && widget.tag!.isNotEmpty) return 'tag';
    if (widget.level != null && widget.level!.isNotEmpty) return 'level';
    return 'vocabulary';
  }

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
    GroupApi.fetchAll().then((list) {
      if (mounted) setState(() => groups = list);
    });
    if (widget.initialCharacters != null) {
      characters = List.of(widget.initialCharacters!);
      batchLabel = widget.batchValue != null && widget.batchValue!.isNotEmpty
          ? widget.batchValue!
          : 'None';
      if (widget.recordHistory) {
        loadInitialIndex();
      } else {
        currentIndex = 0;
        if (characters.isNotEmpty) {
          checkAudioAvailable();
          if (autoSound && hasAudio) playAudio();
        }
      }
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
          if (widget.recordHistory) {
            updateLastCharacter(characters[currentIndex].id);
          }
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
    recognizeDebounce = Timer(const Duration(milliseconds: 300), recognizeInk);
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
      if (widget.recordHistory) {
        updateLastCharacter(current!.id);
      }
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
      if (widget.recordHistory) {
        updateLastCharacter(current!.id);
      }
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
        if (widget.recordHistory) {
          updateLastCharacter(current!.id);
        }
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
        if (widget.recordHistory) {
          updateLastCharacter(current!.id);
        }
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

  void toggleAddToGroup() {
    setState(() {
      if (addingToGroup) {
        addingToGroup = false;
        selectedGroupId = null;
      } else {
        addingToGroup = true;
      }
    });
  }

  Future<void> applyAddToGroup() async {
    final gid = selectedGroupId;
    final c = current;
    if (!addingToGroup || gid == null || c == null || groups.isEmpty) return;
    final g = groups.firstWhere((e) => e.id == gid, orElse: () => groups.first);
    final ids = Set<int>.from(g.characterIds)..add(c.id);
    await GroupApi.updateGroup(gid, g.name, ids.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Character added to ${g.name}')),
    );
    setState(() {
      addingToGroup = false;
      selectedGroupId = null;
    });
    GroupApi.fetchAll().then((list) {
      if (mounted) setState(() => groups = list);
    });
  }

  Future<void> loadInitialIndex() async {
    int start = 0;
    final id = await SettingsApi.getInt(_storageKey);
    if (id != null) {
      final idx = characters.indexWhere((c) => c.id == id);
      if (idx >= 0) start = idx;
    }
    if (!mounted) return;
    setState(() => currentIndex = start);
    if (characters.isNotEmpty) {
      if (widget.recordHistory) {
        updateLastCharacter(characters[currentIndex].id);
      }
      checkAudioAvailable();
      if (autoSound && hasAudio) playAudio();
    }
  }

  void updateLastCharacter(int id) {
    if (widget.recordHistory) {
      SettingsApi.setInt(_storageKey, id);
    }
  }

  void restartReview() {
    if (widget.recordHistory) {
      SettingsApi.setInt(_storageKey, null);
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

  void _openSettingsMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToggle('Show Hanzi', showHanzi, (v) {
                      setState(() => showHanzi = v);
                      setStateDialog(() {});
                    }),
                    _buildToggle('Show Pinyin', showPinyin, (v) {
                      setState(() => showPinyin = v);
                      setStateDialog(() {});
                    }),
                    _buildToggle('Show Translation', showTranslation, (v) {
                      setState(() => showTranslation = v);
                      setStateDialog(() {});
                    }),
                    _buildToggle('Show Info Text', showInfoText, (v) {
                      setState(() => showInfoText = v);
                      setStateDialog(() {});
                    }),
                    _buildToggle('Touch Panel', showTouchPanel, (v) {
                      setState(() => showTouchPanel = v);
                      setStateDialog(() {});
                    }),
                    _buildToggle('Auto Sound', autoSound, (v) {
                      setState(() => autoSound = v);
                      setStateDialog(() {});
                      if (v && hasAudio) playAudio();
                    }),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Restart?'),
                            content: Text('Are you sure you want to restart?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Restart'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          Navigator.pop(context);
                          restartReview();
                        }
                      },
                      child: Text('RESTART'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildLayout(BuildContext context, LayoutConfig layout) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final exampleHeight = screenH * layout.exampleHeightRatio;
    final drawingHeight = screenH * layout.drawingHeightRatio;
    final contentWidth = screenW - 48;
    final double detailFontSize =
        DeviceConfig.deviceType == DeviceType.tablet
            ? UiScale.detailFont * 1.5
            : UiScale.detailFont;

    final previewBox = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

    final listenButton = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: hasAudio ? playAudio : null,
          child: Text('LISTEN'),
        ),
      ],
    );

    final exampleArea = SizedBox(
      width: contentWidth,
      height: exampleHeight,
      child: DeviceConfig.deviceType == DeviceType.smartphone
          ? Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                border: Border.all(color: Color.fromARGB(255, 36, 99, 121)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: editing
                  ? Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: detailsController,
                            maxLines: null,
                            expands: true,
                            decoration: InputDecoration(border: InputBorder.none),
                            style: TextStyle(fontSize: detailFontSize),
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: examplesController,
                            maxLines: null,
                            expands: true,
                            decoration: InputDecoration(border: InputBorder.none),
                            style: TextStyle(fontSize: detailFontSize),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            current?.other ?? '',
                            style: TextStyle(fontSize: detailFontSize),
                          ),
                          SizedBox(height: 8),
                          SelectableText(
                            current?.examples ?? '',
                            style: TextStyle(fontSize: detailFontSize),
                          ),
                        ],
                      ),
                    ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 2),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                      border: Border.all(color: Color.fromARGB(255, 36, 99, 121)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: editing
                        ? TextField(
                            controller: detailsController,
                            maxLines: null,
                            expands: true,
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            style: TextStyle(fontSize: detailFontSize),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              current?.other ?? '',
                              style: TextStyle(fontSize: detailFontSize),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 2),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 20, 18, 24).withOpacity(0.1),
                      border: Border.all(color: Color.fromARGB(255, 36, 99, 121)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: editing
                        ? TextField(
                            controller: examplesController,
                            maxLines: null,
                            expands: true,
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            style: TextStyle(fontSize: detailFontSize),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              current?.examples ?? '',
                              style: TextStyle(fontSize: detailFontSize),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );

    final recognizedLabel = !modelReady
        ? 'Recognized drawing: $recognizerStatus'
        : 'Recognized drawing: ${recognizedText.isEmpty ? recognizerStatus : recognizedText}'
            '${recognizedScore != null ? ' (${(recognizedScore! * 100).toStringAsFixed(1)}%)' : ''}';

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
                    SizedBox(
                      width: UiScale.toggleWidth,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: _openSettingsMenu,
                        ),
                      ),
                    ),
                    Expanded(child: Center(child: previewBox)),
                    SizedBox(width: UiScale.controlsWidth, child: listenButton),
                  ],
                ),
                SizedBox(height: 24),
                exampleArea,
                SizedBox(height: 16),
                if (DeviceConfig.deviceType != DeviceType.smartphone)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: deleteCharacter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text('DELETE CHARACTER'),
                        ),
                        ElevatedButton(
                          onPressed: toggleEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: editing ? Colors.green : null,
                          ),
                          child:
                              Text(editing ? 'SAVE CHANGES' : 'EDIT CHARACTER'),
                        ),
                        if (editing)
                          ElevatedButton(
                            onPressed: cancelEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('CANCEL CHANGES'),
                          ),
                        ElevatedButton(
                          onPressed: toggleAddToGroup,
                          child:
                              Text(addingToGroup ? 'CANCEL' : 'ADD TO GROUP'),
                        ),
                        if (addingToGroup)
                          DropdownButton<int>(
                            value: selectedGroupId,
                            hint: Text('Select group'),
                            items: [
                              for (final g in groups)
                                DropdownMenuItem(
                                    value: g.id, child: Text(g.name)),
                            ],
                            onChanged: (v) => setState(() => selectedGroupId = v),
                          ),
                        if (addingToGroup)
                          ElevatedButton(
                            onPressed:
                                selectedGroupId != null ? applyAddToGroup : null,
                            child: Text('APPLY'),
                          ),
                      ],
                    ),
                  ),
                if (showTouchPanel) SizedBox(height: drawingHeight + 56),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showInfoText) ...[
                      SizedBox(
                        width: contentWidth,
                        child: _infoColumn(recognizedLabel),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (showTouchPanel)
                      SizedBox(
                        width: contentWidth,
                        height: drawingHeight,
                        child: _buildDrawingPad(),
                      ),
                    SizedBox(height: showTouchPanel ? 16 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showTouchPanel)
                          ElevatedButton(
                            onPressed: clearDrawing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('DELETE'),
                          ),
                        if (showTouchPanel) SizedBox(width: 8),
                        ElevatedButton(
                        onPressed: goToPreviousCharacter,
                        child: Text('PREVIOUS'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: goToNextCharacter,
                        child: Text('NEXT'),
                      ),
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
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      DeviceConfig.deviceType = DeviceType.browser;
    } else if (width > 600) {
      DeviceConfig.deviceType = DeviceType.tablet;
    } else {
      DeviceConfig.deviceType = DeviceType.smartphone;
    }
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

  Widget _infoColumn(String recognizedLabel) {
    final level = current?.level;
    final tags = current?.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editing
            ? TextField(
                controller: levelController,
                decoration: InputDecoration(
                  labelText: 'Level',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              )
            : SelectableText(
                'Level: ${level == null || level.isEmpty ? '—' : level}',
                style: TextStyle(
                    fontSize: UiScale.smallFont * DeviceConfig.layout.fontScale),
              ),
        SizedBox(height: 4),
        editing
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                  IconButton(onPressed: chooseTag, icon: Icon(Icons.list)),
                ],
              )
            : SelectableText(
                'Tags: ${tags == null || tags.isEmpty ? '—' : tags.join(', ')}',
                style: TextStyle(
                    fontSize: UiScale.smallFont * DeviceConfig.layout.fontScale),
              ),
        SizedBox(height: 8),
        SelectableText(
          'Batch/Group: $batchLabel',
          style: TextStyle(
              fontSize: UiScale.smallFont * DeviceConfig.layout.fontScale),
        ),
        SizedBox(height: 4),
        SelectableText(
          'Characters left in this $_reviewType: ${characters.length - currentIndex - 1}',
          style: TextStyle(
              fontSize: UiScale.smallFont * DeviceConfig.layout.fontScale),
        ),
        SizedBox(height: 4),
        SelectableText(
          recognizedLabel,
          style: TextStyle(
              fontSize: UiScale.smallFont * DeviceConfig.layout.fontScale),
        ),
      ],
    );
  }

  Widget _buildDrawingPad() {
    return GestureDetector(
      onPanStart: (details) {
        setState(() => points.add(details.localPosition));
        strokePoints = [];
        strokePoints.add(
          mlkit.StrokePoint(
            x: details.localPosition.dx,
            y: details.localPosition.dy,
            t: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        ink.strokes.add(mlkit.Stroke()..points = List.of(strokePoints));
      },
      onPanUpdate: (details) {
        setState(() => points.add(details.localPosition));
        strokePoints.add(
          mlkit.StrokePoint(
            x: details.localPosition.dx,
            y: details.localPosition.dy,
            t: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        ink.strokes.last.points = List.of(strokePoints);
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: _DrawingPainter(points: points),
          child: SizedBox.expand(),
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
        Transform.scale(
          scale: 0.7,
          child: Switch(value: value, onChanged: onChanged),
        ),
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
