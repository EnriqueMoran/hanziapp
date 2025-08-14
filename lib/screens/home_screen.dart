import 'package:flutter/material.dart';

import '../layout_config.dart';
import '../layout_preset.dart';
import '../api/character_api.dart';
import '../api/layout_preset_api.dart';
import '../offline/offline_service.dart';
import '../route_observer.dart';
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

enum ConnectionStatus { unknown, online, offline }

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  List<LayoutPreset> _presets = [];
  String? _selectedPreset;
  bool _loading = true;
  ConnectionStatus _status = ConnectionStatus.unknown;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _startup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _checkConnection();
  }

  Future<void> _startup() async {
    setState(() {
      _statusMessage = 'Loading presets...';
    });
    await _loadPresets();
    if (OfflineService.isSupported) {
      await _sync(initial: true);
    } else {
      setState(() {
        _loading = false;
        _status = ConnectionStatus.online;
        _statusMessage = '';
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
        .where(
          (c) =>
              c.character.contains(query) ||
              c.meaning.toLowerCase().contains(lower),
        )
        .toList();
    if (!mounted) return;
    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No results found.')));
    } else if (results.length == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CharacterReviewScreen(
            initialCharacters: results,
            recordHistory: false,
          ),
        ),
      );
      _checkConnection();
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(results: results),
        ),
      );
      _checkConnection();
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
                .map(
                  (p) => DropdownMenuItem(value: p.name, child: Text(p.name)),
                )
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
            _checkConnection();
          },
          child: const Text('Settings'),
        ),
      ],
    );
  }

  /// Creates a full-width button that navigates to a new screen.
  Widget _fullWidthButton(BuildContext context, String label, Widget target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => target),
          );
          _checkConnection();
        },
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
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => target1),
                );
                _checkConnection();
              },
              child: Text(label1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => target2),
                );
                _checkConnection();
              },
              child: Text(label2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync({bool initial = false}) async {
    if (!OfflineService.isSupported) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Checking server connection...';
    });
    final hasConn = await OfflineService.hasConnection(
      timeout: const Duration(seconds: 2),
    );
    OfflineService.isOffline = !hasConn;
    if (hasConn) {
      final dbSize = await OfflineService.syncWithServer(
        progress: (msg, current, total, {int? items, int? bytes}) {
          if (!mounted) return;
          setState(() {
            var text = '$msg ($current/$total)';
            if (items != null) text += ' - $items items';
            if (bytes != null) text += ' - ${_formatBytes(bytes)}';
            _statusMessage = text;
          });
        },
      );
      await _loadPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync complete (${_formatBytes(dbSize)})')),
        );
      }
      setState(() {
        _status = ConnectionStatus.online;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No server connection. Offline mode.')),
        );
      }
      setState(() {
        _status = ConnectionStatus.offline;
      });
    }
    setState(() {
      _loading = false;
      _statusMessage = '';
    });
  }

  Future<void> _checkConnection() async {
    if (!OfflineService.isSupported) return;
    final hasConn = await OfflineService.hasConnection(
      timeout: const Duration(seconds: 2),
    );
    OfflineService.isOffline = !hasConn;
    setState(() {
      _status = hasConn ? ConnectionStatus.online : ConnectionStatus.offline;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
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
                color: _status == ConnectionStatus.online
                    ? Colors.green
                    : (_status == ConnectionStatus.offline
                          ? Colors.yellow
                          : Colors.red),
              ),
            ),
          ),
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
                    if (OfflineService.isSupported) ...[
                      ElevatedButton(
                        onPressed: () => _sync(),
                        child: const Text('Sync'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _layoutSelector(context),
                    const SizedBox(height: 16),
                    _searchBox(),
                    const SizedBox(height: 16),
                    _fullWidthButton(
                      context,
                      'Review full vocabulary',
                      CharacterReviewScreen(),
                    ),
                    _fullWidthButton(
                      context,
                      'Review batches and groups',
                      const BatchGroupSelectionScreen(),
                    ),
                    const SizedBox(height: 12),
                    _halfWidthButtonRow(
                      context,
                      'Create batch',
                      BatchCreationScreen(),
                      'Create group',
                      const GroupCreationScreen(),
                    ),
                    _fullWidthButton(
                      context,
                      'Edit groups',
                      const GroupEditScreen(),
                    ),
                    const SizedBox(height: 12),
                    _fullWidthButton(
                      context,
                      'Add character',
                      const AddCharacterScreen(),
                    ),
                    _fullWidthButton(
                      context,
                      'Delete characters',
                      const DeleteCharacterScreen(),
                    ),
                  ],
                ),
              ),
              if (_loading)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_statusMessage),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
