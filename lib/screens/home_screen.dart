import 'package:flutter/material.dart';

import '../layout_config.dart';
import '../layout_preset.dart';
import '../api/character_api.dart';
import '../api/layout_preset_api.dart';
import '../offline/offline_service.dart';
import 'dart:io' show Platform;
import 'character_review_screen.dart';
import 'batch_group_selection_screen.dart';
import 'batch_creation_screen.dart';
import 'group_creation_screen.dart';
import 'group_edit_screen.dart';
import 'add_character_screen.dart';
import 'delete_character_screen.dart';
import 'search_results_screen.dart';
import 'layout_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

LayoutPreset? _findPresetByName(List<LayoutPreset> presets, String? name) {
  for (final p in presets) {
    if (p.name == name) return p;
  }
  return null;
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LayoutPreset> _presets = [];
  String? _selectedPreset;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    await _loadPresets();
    if (Platform.isAndroid) {
      await _sync(initial: true);
    } else {
      setState(() {
        _loading = false;
        _offline = false;
      });
    }
  }

  Future<void> _loadPresets() async {
    final presets = await LayoutPresetApi.loadPresets();
    final selected = await LayoutPresetApi.getSelected();
    setState(() {
      _presets = presets;
      _selectedPreset = selected;
      final p = _findPresetByName(_presets, selected);
      DeviceConfig.customLayout = p?.toLayoutConfig();
    });
  }

  Widget _searchBox() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search hanzi or translation',
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _search, child: const Text('Search')),
      ],
    );
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final all = await CharacterApi.fetchAll();
    final lower = query.toLowerCase();
    final results = all
        .where((c) =>
            c.character.contains(query) ||
            c.meaning.toLowerCase().contains(lower))
        .toList();
    if (!mounted) return;
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found.')));
    } else if (results.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CharacterReviewScreen(
            initialCharacters: results,
            recordHistory: false,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(results: results),
        ),
      );
    }
  }

  Widget _layoutSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedPreset,
            hint: const Text('Select layout'),
            items: _presets
                .map((p) => DropdownMenuItem(
                      value: p.name,
                      child: Text(p.name),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedPreset = val;
                final p = _findPresetByName(_presets, val);
                DeviceConfig.customLayout = p?.toLayoutConfig();
              });
              LayoutPresetApi.setSelected(val);
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final preset = _findPresetByName(_presets, _selectedPreset);
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => LayoutSettingsScreen(preset: preset),
              ),
            );
            if (changed == true) {
              await _loadPresets();
            }
          },
          child: const Text('Ajustes'),
        ),
      ],
    );
  }

  /// Creates a full-width button that navigates to a new screen.
  Widget _fullWidthButton(BuildContext context, String label, Widget target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => target),
        ),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(label),
      ),
    );
  }

  /// Creates a row with two half-width buttons.
  Widget _halfWidthButtonRow(
    BuildContext context,
    String label1,
    Widget target1,
    String label2,
    Widget target2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => target1),
              ),
              child: Text(label1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => target2),
              ),
              child: Text(label2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sync({bool initial = false}) async {
    setState(() {
      _loading = true;
    });
    final hasConn = await OfflineService.hasConnection();
    OfflineService.isOffline = !hasConn;
    if (hasConn) {
      await OfflineService.syncWithServer();
    }
    setState(() {
      _loading = false;
      _offline = !hasConn;
    });
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hanzi App'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _offline ? Colors.orange : Colors.green,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: _loading,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _sync(),
                      child: const Text('Sincronizar'),
                    ),
                    const SizedBox(height: 16),
                    _layoutSelector(context),
                    const SizedBox(height: 16),
                    _searchBox(),
                    const SizedBox(height: 16),
                    _fullWidthButton(context, 'Review full vocabulary',
                        CharacterReviewScreen()),
                    _fullWidthButton(context, 'Review batches and groups',
                        const BatchGroupSelectionScreen()),
                    const SizedBox(height: 12),
                    _halfWidthButtonRow(
                      context,
                      'Create batch',
                      BatchCreationScreen(),
                      'Create group',
                      const GroupCreationScreen(),
                    ),
                    _fullWidthButton(context, 'Edit groups', const GroupEditScreen()),
                    const SizedBox(height: 12),
                    _fullWidthButton(
                        context, 'Add character', const AddCharacterScreen()),
                    _fullWidthButton(context, 'Delete characters',
                        const DeleteCharacterScreen()),
                  ],
                ),
              ),
              if (_loading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
