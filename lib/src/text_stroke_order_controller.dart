import 'package:flutter/material.dart';

import 'parser.dart';
import 'svg_provider.dart';

class TextStrokeOrderController extends ChangeNotifier {
  final SvgProvider svgProvider;

  TextStrokeOrderController(
      {required this.svgProvider, required TickerProvider vsync, this.duration})
      : animationController =
            AnimationController(vsync: vsync, duration: duration);
  Duration? duration;

  SvgParser? _parser;

  SvgParser? get parser => _parser;

  Future<SvgParser> get resolve async {
    _parser = await svgProvider.parser;
    return _parser!;
  }

  List<PathSegment> get listPathSegments => parser?.getPathSegments() ?? [];

  List<TextSegment> get listTextSegments => parser?.getTextSegments() ?? [];

  AnimationController animationController;

  bool isReset = false;

  reset() {
    isReset = true;
    notifyListeners();
  }
}
