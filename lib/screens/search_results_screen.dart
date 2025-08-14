import 'package:flutter/material.dart';
import '../api/character_api.dart';
import '../ui_scale.dart';
import 'character_review_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<Character> results;
  const SearchResultsScreen({Key? key, required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: SafeArea(
        bottom: true,
        child: ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final c = results[index];
            return ListTile(
            title: Text(c.character, style: TextStyle(fontSize: UiScale.tileFont)),
            subtitle: Text(c.meaning),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CharacterReviewScreen(
                  initialCharacters: [c],
                  recordHistory: false,
                ),
              ),
            ),
          );
        },)
      ),
    );
  }
}
