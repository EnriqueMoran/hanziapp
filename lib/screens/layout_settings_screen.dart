import 'package:flutter/material.dart';

import '../api/character_api.dart';
import '../api/layout_preset_api.dart';
import '../layout_config.dart';
import '../layout_preset.dart';
import '../ui_scale.dart';
import 'character_review_screen.dart';

class LayoutSettingsScreen extends StatefulWidget {
  final LayoutPreset? preset;
  const LayoutSettingsScreen({Key? key, this.preset}) : super(key: key);

  @override
  State<LayoutSettingsScreen> createState() => _LayoutSettingsScreenState();
}

class _LayoutSettingsScreenState extends State<LayoutSettingsScreen> {
  late TextEditingController _nameController;
  late double _exampleHeight;
  late double _drawingHeight;
  late double _panelWidth;
  late double _fontSize;
  Character? _character;
  LayoutConfig? _previousLayout;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    if (p != null) {
      _nameController = TextEditingController(text: p.name);
      _exampleHeight = p.exampleHeightRatio;
      _drawingHeight = p.drawingHeightRatio;
      _panelWidth = p.panelWidthRatio;
      _fontSize = UiScale.smallFont * p.fontScale;
    } else {
      final layout = DeviceConfig.layout;
      _nameController = TextEditingController();
      _exampleHeight = layout.exampleHeightRatio;
      _drawingHeight = layout.drawingHeightRatio;
      _panelWidth = layout.panelWidthRatio;
      _fontSize = UiScale.smallFont * layout.fontScale;
    }
    _previousLayout = DeviceConfig.customLayout;
    CharacterApi.fetchAll().then((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _character = list.first);
      }
    });
  }

  @override
  void dispose() {
    DeviceConfig.customLayout = _previousLayout;
    _nameController.dispose();
    super.dispose();
  }

  void _updateLayout() {
    DeviceConfig.customLayout = LayoutConfig(
      exampleHeightRatio: _exampleHeight,
      drawingHeightRatio: _drawingHeight,
      panelWidthRatio: _panelWidth,
      fontScale: _fontSize / UiScale.smallFont,
    );
  }

  Future<void> _openAdjustDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust layout'),
        content: StatefulBuilder(
          builder: (ctx, dialogSetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Examples height'),
              Slider(
                value: _exampleHeight,
                min: 0.1,
                max: 0.5,
                onChanged: (v) {
                  dialogSetState(() => _exampleHeight = v);
                  setState(() {
                    _exampleHeight = v;
                    _updateLayout();
                  });
                },
              ),
              const Text('Touch panel height'),
              Slider(
                value: _drawingHeight,
                min: 0.1,
                max: 0.5,
                onChanged: (v) {
                  dialogSetState(() => _drawingHeight = v);
                  setState(() {
                    _drawingHeight = v;
                    _updateLayout();
                  });
                },
              ),
              const Text('Panel width'),
              Slider(
                value: _panelWidth,
                min: 0.3,
                max: 0.7,
                onChanged: (v) {
                  dialogSetState(() => _panelWidth = v);
                  setState(() {
                    _panelWidth = v;
                    _updateLayout();
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _updateLayout();
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      name = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Configuration name'),
              content: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, _nameController.text),
                  child: const Text('OK'),
                ),
              ],
            ),
          ) ??
          '';
      if (name.trim().isEmpty) return;
    }
    final preset = LayoutPreset(
      name: name,
      exampleHeightRatio: _exampleHeight,
      drawingHeightRatio: _drawingHeight,
      panelWidthRatio: _panelWidth,
      fontScale: _fontSize / UiScale.smallFont,
    );
    final list = await LayoutPresetApi.loadPresets();
    list.removeWhere((p) => p.name == widget.preset?.name);
    list.removeWhere((p) => p.name == name);
    list.add(preset);
    await LayoutPresetApi.savePresets(list);
    await LayoutPresetApi.setSelected(name);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete configuration?'),
        content:
            const Text('Are you sure you want to delete this configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final list = await LayoutPresetApi.loadPresets();
    list.removeWhere((p) => p.name == widget.preset?.name);
    await LayoutPresetApi.savePresets(list);
    await LayoutPresetApi.setSelected(null);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _loadPreset() async {
    final presets = await LayoutPresetApi.loadPresets();
    final selected = await showDialog<LayoutPreset>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select layout'),
        children: [
          for (final p in presets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (selected != null) {
      setState(() {
        _nameController.text = selected.name;
        _exampleHeight = selected.exampleHeightRatio;
        _drawingHeight = selected.drawingHeightRatio;
        _panelWidth = selected.panelWidthRatio;
        _fontSize = UiScale.smallFont * selected.fontScale;
        _updateLayout();
      });
    }
  }

  void _newLayout() {
    final layout = LayoutConfig.forType(DeviceConfig.deviceType);
    setState(() {
      _nameController.clear();
      _exampleHeight = layout.exampleHeightRatio;
      _drawingHeight = layout.drawingHeightRatio;
      _panelWidth = layout.panelWidthRatio;
      _fontSize = UiScale.smallFont * layout.fontScale;
      _updateLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _updateLayout();
    return CharacterReviewScreen(
      initialCharacters: [_character!],
      recordHistory: false,
      layoutMode: true,
      onSaveLayout: _save,
      onDeleteLayout: widget.preset != null ? _delete : null,
      onLoadLayout: _loadPreset,
      onNewLayout: _newLayout,
      fontSizeValue: _fontSize,
      onFontSizeChanged: (v) {
        setState(() => _fontSize = v);
        _updateLayout();
      },
      onSettingsPressed: _openAdjustDialog,
    );
  }
}

