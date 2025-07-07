import 'package:flutter/material.dart';

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
