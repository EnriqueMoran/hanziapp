import 'device_type.dart';

export 'device_type.dart';

class LayoutConfig {
  final double exampleHeightRatio;
  final double drawingHeightRatio;
  final double panelWidthRatio;
  final double fontScale;
  final bool showHanzi;
  final bool showPinyin;
  final bool showTranslation;
  final bool showInfoText;
  final bool showTouchPanel;
  final bool autoSound;

  const LayoutConfig({
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
    this.fontScale = 1.0,
    this.showHanzi = true,
    this.showPinyin = true,
    this.showTranslation = true,
    this.showInfoText = true,
    this.showTouchPanel = true,
    this.autoSound = false,
  });

  static LayoutConfig forType(DeviceType type) {
    switch (type) {
      case DeviceType.browser:
        return const LayoutConfig(
          exampleHeightRatio: 0.40,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
          fontScale: 1.0,
          showTouchPanel: false,
        );
      case DeviceType.tablet:
        return const LayoutConfig(
          exampleHeightRatio: 0.376,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.55,
          fontScale: 1.0,
        );
      case DeviceType.smartphone:
      default:
        return const LayoutConfig(
          exampleHeightRatio: 0.26,
          drawingHeightRatio: 0.21,
          panelWidthRatio: 0.55,
          fontScale: 1.0,
          showInfoText: false,
        );
    }
  }
}

class DeviceConfig {
  static DeviceType deviceType = DeviceType.browser;
  static LayoutConfig? customLayout;

  static LayoutConfig get layout =>
      customLayout ?? LayoutConfig.forType(deviceType);
}
