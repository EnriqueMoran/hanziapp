import 'package:flutter/material.dart';

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
