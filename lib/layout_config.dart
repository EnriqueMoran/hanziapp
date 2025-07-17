import 'package:flutter/material.dart';
import 'device_type.dart';

export 'device_type.dart';

class LayoutConfig {
  final bool showTouchPanel;
  final double exampleHeightRatio;
  final double drawingHeightRatio;
  final double panelWidthRatio;
  final double buttonHeight;
  final EdgeInsetsGeometry buttonPadding;

  const LayoutConfig({
    required this.showTouchPanel,
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
    required this.buttonHeight,
    required this.buttonPadding,
  });

  static LayoutConfig forType(DeviceType type) {
    switch (type) {
      case DeviceType.browser:
        return const LayoutConfig(
          showTouchPanel: false,
          exampleHeightRatio: 0.36,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
          buttonHeight: 48,
          buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );
      case DeviceType.tablet:
        return const LayoutConfig(
          showTouchPanel: true,
          exampleHeightRatio: 0.36,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
          buttonHeight: 48,
          buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );
      case DeviceType.smartphone:
      default:
        return const LayoutConfig(
          showTouchPanel: true,
          exampleHeightRatio: 0.36,
          drawingHeightRatio: 0.20,
          panelWidthRatio: 0.5,
          buttonHeight: 40,
          buttonPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
    }
  }
}

class DeviceConfig {
  static DeviceType deviceType = DeviceType.browser;

  static LayoutConfig get layout => LayoutConfig.forType(deviceType);
}

ButtonStyle buttonStyle({Color? background}) {
  final layout = DeviceConfig.layout;
  return ElevatedButton.styleFrom(
    backgroundColor: background,
    padding: layout.buttonPadding,
    minimumSize: Size.fromHeight(layout.buttonHeight),
  );
}
