import 'package:flutter/material.dart';
import 'app.dart';
import 'offline/offline_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (OfflineService.isSupported) {
    await OfflineService.init();
  }
  runApp(const HanziApp());
}
