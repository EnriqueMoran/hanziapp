import 'package:flutter/foundation.dart';

class UiScale {
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static double get largeFont => _isAndroid ? 32 : 48;
  static double get mediumFont => _isAndroid ? 18 : 20;
  static double get smallFont => _isAndroid ? 14 : 16;
  static double get detailFont => _isAndroid ? 12 : 14;
  static double get tileFont => _isAndroid ? 18 : 24;

  static double get toggleWidth => _isAndroid ? 120 : 200;
  static double get controlsWidth => _isAndroid ? 120 : 180;
}
