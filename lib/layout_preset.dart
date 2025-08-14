import 'layout_config.dart';

class LayoutPreset {
  String name;
  double exampleHeightRatio;
  double drawingHeightRatio;
  double panelWidthRatio;
  double fontScale;
  bool showHanzi;
  bool showPinyin;
  bool showTranslation;
  bool showInfoText;
  bool showTouchPanel;
  bool autoSound;

  LayoutPreset({
    required this.name,
    required this.exampleHeightRatio,
    required this.drawingHeightRatio,
    required this.panelWidthRatio,
    required this.fontScale,
    required this.showHanzi,
    required this.showPinyin,
    required this.showTranslation,
    required this.showInfoText,
    required this.showTouchPanel,
    required this.autoSound,
  });

  factory LayoutPreset.fromJson(Map<String, dynamic> json) {
    return LayoutPreset(
      name: json['name'] as String,
      exampleHeightRatio: (json['exampleHeightRatio'] as num).toDouble(),
      drawingHeightRatio: (json['drawingHeightRatio'] as num).toDouble(),
      panelWidthRatio: (json['panelWidthRatio'] as num).toDouble(),
      fontScale: (json['fontScale'] as num).toDouble(),
      showHanzi: json['showHanzi'] as bool? ?? true,
      showPinyin: json['showPinyin'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? true,
      showInfoText: json['showInfoText'] as bool? ?? true,
      showTouchPanel: json['showTouchPanel'] as bool? ?? true,
      autoSound: json['autoSound'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'exampleHeightRatio': exampleHeightRatio,
        'drawingHeightRatio': drawingHeightRatio,
        'panelWidthRatio': panelWidthRatio,
        'fontScale': fontScale,
        'showHanzi': showHanzi,
        'showPinyin': showPinyin,
        'showTranslation': showTranslation,
        'showInfoText': showInfoText,
        'showTouchPanel': showTouchPanel,
        'autoSound': autoSound,
      };

  LayoutConfig toLayoutConfig() => LayoutConfig(
        exampleHeightRatio: exampleHeightRatio,
        drawingHeightRatio: drawingHeightRatio,
        panelWidthRatio: panelWidthRatio,
        fontScale: fontScale,
        showHanzi: showHanzi,
        showPinyin: showPinyin,
        showTranslation: showTranslation,
        showInfoText: showInfoText,
        showTouchPanel: showTouchPanel,
        autoSound: autoSound,
      );
}
