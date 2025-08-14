import 'package:flutter/foundation.dart';
import 'layout_config.dart';

class UiScale {
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static double get _factor =>
      DeviceConfig.deviceType == DeviceType.smartphone ? 0.8 : 1.0;

  static double get largeFont => (_isAndroid ? 32 : 48) * _factor;
  static double get mediumFont => (_isAndroid ? 18 : 20) * _factor;
  static double get smallFont => (_isAndroid ? 14 : 16) * _factor;
  static double get detailFont => (_isAndroid ? 12 : 14) * _factor;
  static double get tileFont => (_isAndroid ? 18 : 24) * _factor;

  static double get toggleWidth => (_isAndroid ? 120 : 200) * _factor;
  static double get controlsWidth => (_isAndroid ? 120 : 180) * _factor;
}
