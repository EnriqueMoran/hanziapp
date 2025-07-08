import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class HanziApp extends StatelessWidget {
  const HanziApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanzi App',
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
