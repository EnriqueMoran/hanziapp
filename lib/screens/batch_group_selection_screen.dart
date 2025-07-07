import 'package:flutter/material.dart';
import 'character_review_screen.dart';

class BatchGroupSelectionScreen extends StatelessWidget {
  const BatchGroupSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Batch or Group')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CharacterReviewScreen()),
            );
          },
          child: const Text('Go to Character Review'),
        ),
      ),
    );
  }
}
