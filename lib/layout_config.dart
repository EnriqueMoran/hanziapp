import 'device_type.dart';

export 'device_type.dart';

class LayoutConfig {
  final double exampleHeightRatio;
  final double drawingHeightRatio;
  final double panelWidthRatio;
  final double fontScale;

  const LayoutConfig({
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
    this.fontScale = 1.0,
  });

  static LayoutConfig forType(DeviceType type) {
    switch (type) {
      case DeviceType.browser:
        return const LayoutConfig(
          exampleHeightRatio: 0.40,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
          fontScale: 1.0,
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
