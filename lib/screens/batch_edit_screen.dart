import 'package:flutter/material.dart';

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
