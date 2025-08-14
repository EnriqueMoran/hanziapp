import 'layout_config.dart';

class LayoutPreset {
  String name;
  double exampleHeightRatio;
  double drawingHeightRatio;
  double panelWidthRatio;
  double fontScale;

  LayoutPreset({
    required this.name,
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
    required this.fontScale,
  });

  factory LayoutPreset.fromJson(Map<String, dynamic> json) {
    return LayoutPreset(
      name: json['name'] as String,
      exampleHeightRatio: (json['exampleHeightRatio'] as num).toDouble(),
      drawingHeightRatio: (json['drawingHeightRatio'] as num).toDouble(),
      panelWidthRatio: (json['panelWidthRatio'] as num).toDouble(),
      fontScale: (json['fontScale'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'exampleHeightRatio': exampleHeightRatio,
        'drawingHeightRatio': drawingHeightRatio,
        'panelWidthRatio': panelWidthRatio,
        'fontScale': fontScale,
      };

  LayoutConfig toLayoutConfig() => LayoutConfig(
        exampleHeightRatio: exampleHeightRatio,
        drawingHeightRatio: drawingHeightRatio,
        panelWidthRatio: panelWidthRatio,
        fontScale: fontScale,
      );
}
