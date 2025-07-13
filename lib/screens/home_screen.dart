import 'package:flutter/material.dart';
import 'character_review_screen.dart';
import 'batch_group_selection_screen.dart';
import 'batch_creation_screen.dart';
import 'group_creation_screen.dart';
import 'group_edit_screen.dart';
import 'add_character_screen.dart';
import 'delete_character_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hanzi App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _fullWidthButton(context, 'Review full vocabulary',
                const CharacterReviewScreen()),
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
            _fullWidthButton(
                context, 'Delete character', const DeleteCharacterScreen()),
          ],
        ),
      ),
    );
  }
}
