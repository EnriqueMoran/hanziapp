import 'package:flutter/material.dart';

import '../layout_preset.dart';
import '../api/layout_preset_api.dart';
import '../layout_config.dart';

class LayoutSettingsScreen extends StatefulWidget {
  final LayoutPreset? preset;
  const LayoutSettingsScreen({Key? key, this.preset}) : super(key: key);

  @override
  State<LayoutSettingsScreen> createState() => _LayoutSettingsScreenState();
}

class _LayoutSettingsScreenState extends State<LayoutSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _fontController;
  late double _exampleHeight;
  late double _drawingHeight;
  late double _panelWidth;
  late double _fontScale;
  late bool _showHanzi;
  late bool _showPinyin;
  late bool _showTranslation;
  late bool _showInfoText;
  late bool _showTouchPanel;
  late bool _autoSound;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    if (p != null) {
      _nameController = TextEditingController(text: p.name);
      _exampleHeight = p.exampleHeightRatio;
      _drawingHeight = p.drawingHeightRatio;
      _panelWidth = p.panelWidthRatio;
      _fontScale = p.fontScale;
      _showHanzi = p.showHanzi;
      _showPinyin = p.showPinyin;
      _showTranslation = p.showTranslation;
      _showInfoText = p.showInfoText;
      _showTouchPanel = p.showTouchPanel;
      _autoSound = p.autoSound;
      _fontController =
          TextEditingController(text: _fontScale.toStringAsFixed(2));
    } else {
      final layout = DeviceConfig.layout;
      _nameController = TextEditingController();
      _exampleHeight = layout.exampleHeightRatio;
      _drawingHeight = layout.drawingHeightRatio;
      _panelWidth = layout.panelWidthRatio;
      _fontScale = layout.fontScale;
      _showHanzi = layout.showHanzi;
      _showPinyin = layout.showPinyin;
      _showTranslation = layout.showTranslation;
      _showInfoText = layout.showInfoText;
      _showTouchPanel = layout.showTouchPanel;
      _autoSound = layout.autoSound;
      _fontController =
          TextEditingController(text: _fontScale.toStringAsFixed(2));
    }
  }

  void _newLayout() {
    final layout = LayoutConfig.forType(DeviceConfig.deviceType);
    setState(() {
      _nameController.clear();
      _exampleHeight = layout.exampleHeightRatio;
      _drawingHeight = layout.drawingHeightRatio;
      _panelWidth = layout.panelWidthRatio;
      _fontScale = layout.fontScale;
      _showHanzi = layout.showHanzi;
      _showPinyin = layout.showPinyin;
      _showTranslation = layout.showTranslation;
      _showInfoText = layout.showInfoText;
      _showTouchPanel = layout.showTouchPanel;
      _autoSound = layout.autoSound;
      _fontController.text = _fontScale.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fontController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final preset = LayoutPreset(
      name: name,
      exampleHeightRatio: _exampleHeight,
      drawingHeightRatio: _drawingHeight,
      panelWidthRatio: _panelWidth,
      fontScale: _fontScale,
      showHanzi: _showHanzi,
      showPinyin: _showPinyin,
      showTranslation: _showTranslation,
      showInfoText: _showInfoText,
      showTouchPanel: _showTouchPanel,
      autoSound: _autoSound,
    );
    final list = await LayoutPresetApi.loadPresets();
    list.removeWhere((p) => p.name == widget.preset?.name);
    list.removeWhere((p) => p.name == name);
    list.add(preset);
    await LayoutPresetApi.savePresets(list);
    await LayoutPresetApi.setSelected(name);
    DeviceConfig.customLayout = preset.toLayoutConfig();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete configuration?'),
        content: const Text('Are you sure you want to delete this configuration?'),
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
    DeviceConfig.customLayout =
        LayoutConfig.forType(DeviceConfig.deviceType);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layout settings')),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fontController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Font size'),
                      onChanged: (v) {
                        final value = double.tryParse(v);
                        if (value != null) {
                          setState(() {
                            _fontScale = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _newLayout,
                    child: const Text('New Layout'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Examples height'),
              Slider(
                value: _exampleHeight,
                min: 0.1,
                max: 0.5,
                onChanged: (v) => setState(() {
                  _exampleHeight = v;
                }),
              ),
              const Text('Touch panel height'),
              Slider(
                value: _drawingHeight,
                min: 0.1,
                max: 0.5,
                onChanged: (v) => setState(() {
                  _drawingHeight = v;
                }),
              ),
              const Text('Panel width'),
              Slider(
                value: _panelWidth,
                min: 0.3,
                max: 0.7,
                onChanged: (v) => setState(() {
                  _panelWidth = v;
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show Hanzi'),
                value: _showHanzi,
                onChanged: (v) => setState(() => _showHanzi = v),
              ),
              SwitchListTile(
                title: const Text('Show Pinyin'),
                value: _showPinyin,
                onChanged: (v) => setState(() => _showPinyin = v),
              ),
              SwitchListTile(
                title: const Text('Show Translation'),
                value: _showTranslation,
                onChanged: (v) => setState(() => _showTranslation = v),
              ),
              SwitchListTile(
                title: const Text('Show Info Text'),
                value: _showInfoText,
                onChanged: (v) => setState(() => _showInfoText = v),
              ),
              SwitchListTile(
                title: const Text('Touch Panel'),
                value: _showTouchPanel,
                onChanged: (v) => setState(() => _showTouchPanel = v),
              ),
              SwitchListTile(
                title: const Text('Auto Sound'),
                value: _autoSound,
                onChanged: (v) => setState(() => _autoSound = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.preset != null ? _delete : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Delete'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
