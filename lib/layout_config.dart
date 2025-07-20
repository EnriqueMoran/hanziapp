import 'device_type.dart';

export 'device_type.dart';

class LayoutConfig {
  final bool showTouchPanel;
  final double exampleHeightRatio;
  final double drawingHeightRatio;
  final double panelWidthRatio;

  const LayoutConfig({
    required this.showTouchPanel,
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
  });

  static LayoutConfig forType(DeviceType type) {
    switch (type) {
      case DeviceType.browser:
        return const LayoutConfig(
          showTouchPanel: false,
          exampleHeightRatio: 0.40,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
        );
      case DeviceType.tablet:
        return const LayoutConfig(
          showTouchPanel: true,
          exampleHeightRatio: 0.376,
          drawingHeightRatio: 0.25,
          panelWidthRatio: 0.55,
        );
      case DeviceType.smartphone:
      default:
        return const LayoutConfig(
          showTouchPanel: true,
          exampleHeightRatio: 0.26,
          drawingHeightRatio: 0.21,
          panelWidthRatio: 0.55,
        );
    }
  }
}

class DeviceConfig {
  static DeviceType deviceType = DeviceType.browser;

  static LayoutConfig get layout => LayoutConfig.forType(deviceType);
}
