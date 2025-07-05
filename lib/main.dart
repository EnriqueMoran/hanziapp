import 'package:flutter/material.dart';

void main() {
  runApp(const HanziApp());
}

class HanziApp extends StatelessWidget {
  const HanziApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanzi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hanzi App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CharacterReviewScreen(),
                ),
              );
            },
            child: const Text('Review complete vocabulary'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BatchGroupSelectionScreen(),
                ),
              );
            },
            child: const Text('Review by batch or group'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BatchCreationScreen(),
                ),
              );
            },
            child: const Text('Create batch'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BatchEditScreen(),
                ),
              );
            },
            child: const Text('Edit batches'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupCreationScreen(),
                ),
              );
            },
            child: const Text('Create group'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupEditScreen(),
                ),
              );
            },
            child: const Text('Edit groups'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCharacterScreen(),
                ),
              );
            },
            child: const Text('Add character'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeleteCharacterScreen(),
                ),
              );
            },
            child: const Text('Delete character'),
          ),
        ],
      ),
    );
  }
}

class CharacterReviewScreen extends StatelessWidget {
  const CharacterReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Review')),
      body: const Center(child: Text('Character Review Screen')),
    );
  }
}

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
              MaterialPageRoute(
                builder: (context) => const CharacterReviewScreen(),
              ),
            );
          },
          child: const Text('Go to Character Review'),
        ),
      ),
    );
  }
}

class BatchCreationScreen extends StatelessWidget {
  const BatchCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Batch')),
      body: const Center(child: Text('Batch Creation Screen')),
    );
  }
}

class BatchEditScreen extends StatelessWidget {
  const BatchEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Batches')),
      body: const Center(child: Text('Batch Edit Screen')),
    );
  }
}

class GroupCreationScreen extends StatelessWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: const Center(child: Text('Group Creation Screen')),
    );
  }
}

class GroupEditScreen extends StatelessWidget {
  const GroupEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Groups')),
      body: const Center(child: Text('Group Edit Screen')),
    );
  }
}

class AddCharacterScreen extends StatelessWidget {
  const AddCharacterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Character')),
      body: const Center(child: Text('Add Character Screen')),
    );
  }
}

class DeleteCharacterScreen extends StatelessWidget {
  const DeleteCharacterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Character')),
      body: const Center(child: Text('Delete Character Screen')),
    );
  }
}
