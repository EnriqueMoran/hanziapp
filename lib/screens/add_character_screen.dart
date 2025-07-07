import 'package:flutter/material.dart';

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
