import 'package:flutter/material.dart';

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
