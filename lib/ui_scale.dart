import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UiScale {
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // Fonts
  static double get largeFont => _isAndroid ? 26 : 48;
  static double get mediumFont => _isAndroid ? 16 : 20;
  static double get smallFont => _isAndroid ? 12 : 16;
  static double get detailFont => _isAndroid ? 10 : 14;
  static double get tileFont => _isAndroid ? 16 : 24;
  static double get buttonFont => _isAndroid ? 14 : 16;

  // Button dimensions
  static double get buttonHeight => _isAndroid ? 36 : 48;

  // Layout widths
  static double get toggleWidth => _isAndroid ? 100 : 200;
  static double get controlsWidth => _isAndroid ? 100 : 180;

  static ButtonStyle buttonStyle({Color? backgroundColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        textStyle: TextStyle(fontSize: buttonFont),
        minimumSize: Size.fromHeight(buttonHeight),
      );
}
