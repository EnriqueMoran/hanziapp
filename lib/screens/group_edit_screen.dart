import 'package:flutter/material.dart';

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
