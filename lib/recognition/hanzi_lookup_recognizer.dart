import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

class HanziLookupRecognizer {
  final JavascriptRuntime _js;
  bool _initialized = false;

  HanziLookupRecognizer() : _js = getJavascriptRuntime();

  Future<void> init() async {
    if (_initialized) return;
    final jsLib = await rootBundle.loadString('assets/hanzilookup.min.js');
    _js.evaluate(jsLib);
    final jsonData = await rootBundle.loadString('assets/mmah.json');
    final jsonEsc = jsonEncode(jsonData);
    _js.evaluate('HanziLookup.data = {};');
    _js.evaluate('HanziLookup.data["mmah"] = JSON.parse($jsonEsc);');
    _js.evaluate('HanziLookup.data["mmah"].substrokes = HanziLookup.decodeCompact(HanziLookup.data["mmah"].substrokes);');
    _js.evaluate('window = {};');
    _js.evaluate('var matcher = new HanziLookup.Matcher("mmah");');
    _js.evaluate('function recognize(strokes, limit){ var res=null; matcher.match(new HanziLookup.AnalyzedCharacter(strokes), limit, function(m){res=JSON.stringify(m);}); return res;}');
    _initialized = true;
  }

  Future<List<dynamic>> recognize(List<List<List<double>>> strokes, {int limit = 3}) async {
    await init();
    final strokesJson = jsonEncode(strokes);
    final result = _js.evaluate('recognize($strokesJson, $limit)');
    final list = jsonDecode(result.stringResult) as List<dynamic>;
    return list;
  }
}
