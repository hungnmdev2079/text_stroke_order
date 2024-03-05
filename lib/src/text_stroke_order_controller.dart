import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'parser.dart';
import 'svg_provider.dart';
import 'type.dart';

class TextStrokeOrderController extends ChangeNotifier {
  final SvgProvider svgProvider;

  TextStrokeOrderController(
      {required this.svgProvider, required TickerProvider vsync, this.duration})
      : animationController =
            AnimationController(vsync: vsync, duration: duration);

  StreamController<DrawState> drawStreamState =
      StreamController<DrawState>.broadcast();
  StreamController<HandDrawState> handDrawStreamState =
      StreamController<HandDrawState>.broadcast();

  int currentIndex = 0;

  bool canDraw = true;

  Offset? handlePosition;

  List<Offset>? currentOffset;

  Duration? duration;

  SvgParser? _parser;

  SvgParser? get parser => _parser;

  Future<SvgParser> get resolve async {
    if (_parser != null) {
      return _parser!;
    }
    _parser = await svgProvider.parser;
    return _parser!;
  }

  List<PathSegment> get listPathSegments => parser?.getPathSegments() ?? [];

  List<TextSegment> get listTextSegments => parser?.getTextSegments() ?? [];

  AnimationController animationController;

  TextStrokeOrderType? currentType;

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  initialAnimate(bool autoAnimate) {
    final d = duration ?? const Duration(seconds: 1);
    animationController.duration = d * listPathSegments.length;
    if (autoAnimate) {
      startAnimation();
    }
  }

  startAnimation() {
    animationController.reset();
    animationController.forward();
  }

  resetAnimation() {
    animationController.reset();
  }

  Future<bool> reloadSvg() async {
    try {
      _parser = await svgProvider.parser;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> preloadSvg() async {
    Completer<bool> completer = Completer();
    try {
      await resolve.then((value) {
        completer.complete(true);
      });
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  reset() {
    _resetStateDraw();
    currentIndex =
        listPathSegments.indexWhere((element) => !element.isSkipTutorial);
    listPathSegments[currentIndex].isTutorial = true;

    for (var i = 0; i < listPathSegments.length; i++) {
      listPathSegments[i].isDoneTutorial = false;
      if (i != currentIndex) {
        listPathSegments[i].isTutorial = false;
      }
      listPathSegments[i].tutorialPercent = 0;
    }
    notifyListeners();
  }

  setRandomSkipStrokeOrder() {
    if (listPathSegments.length <= 1) {
      currentIndex = 0;
      return;
    }
    final partLenght = listPathSegments.length ~/ 2;
    final List<int> idx = [];
    for (var i = 0; i < listPathSegments.length; i++) {
      listPathSegments[i].isTutorial = false;
      listPathSegments[i].isSkipTutorial = false;
      listPathSegments[i].tutorialPercent = 0;
      listPathSegments[i].isDoneTutorial = false;
    }
    while (idx.length < partLenght) {
      Random random = Random();
      int x = random.nextInt(listPathSegments.length);
      if (!idx.contains(x)) {
        listPathSegments[x].isSkipTutorial = true;
        idx.add(x);
      }
    }
    currentIndex =
        listPathSegments.indexWhere((element) => !element.isSkipTutorial);
  }

  updateTutorial() {
    canDraw = false;
    listPathSegments[currentIndex].isTutorial = true;
    notifyListeners();
  }

  startDrawCheck(Offset position) {
    if (handlePosition == null) {
      return;
    }
    if ((handlePosition! - position).distance < 25) {
      canDraw = true;
    } else {
      canDraw = false;
    }
  }

  endDrawCheck() {
    canDraw = false;
  }

  updateDrawTutorial(Offset position) {
    if (!canDraw) {
      return;
    }
    // _resetStateDraw();
    final o = position;
    final x = findNearestIndexOffset(o, currentOffset!);
    var percent = x / (currentOffset!.length - 1);
    if (listPathSegments[currentIndex].isDoneTutorial == true) {
      return;
    }
    if (percent >= 1) {
      percent = 1;
      listPathSegments[currentIndex].isDoneTutorial = true;
      listPathSegments[currentIndex].tutorialPercent = percent;
      _nextStroke();
    } else {
      listPathSegments[currentIndex].tutorialPercent = percent;
    }
    notifyListeners();
  }

  _nextStroke() {
    if (currentIndex < listPathSegments.length - 1) {
      try {
        do {
          currentIndex++;
        } while (listPathSegments[currentIndex].isSkipTutorial);
        updateTutorial();
        _onEndStroke();
      } catch (e) {
        currentIndex--;
        _onFinish();
      }
    } else {
      _onFinish();
    }
  }

  _onFinish() {
    drawStreamState.add(DrawState.finish);
  }

  _onEndStroke() {
    drawStreamState.add(DrawState.endStroke);
  }

  _onUpdateHandDrawCorrect() {
    handDrawStreamState.add(HandDrawState.correct);
  }

  _onUpdateHandDrawIncorrect() {
    handDrawStreamState.add(HandDrawState.inCorrect);
  }

  _resetStateDraw() {
    drawStreamState.add(DrawState.none);
  }

  updateHandlePosision(Offset position) {
    handlePosition = position;
  }

  updateListCurrentOffsets(List<Offset> offsets) {
    currentOffset = offsets;
  }

  void checkHandWriteStroke(List<Offset?> rawStroke) {
    final bool isCorrect = _checkStroke(currentOffset ?? [], rawStroke);
    if (isCorrect) {
      listPathSegments[currentIndex].isDoneTutorial = true;
      listPathSegments[currentIndex].tutorialPercent = 1;
      if (currentIndex < listPathSegments.length - 1) {
        _nextStroke();
      } else {
        _onFinish();
        notifyListeners();
      }
      _onUpdateHandDrawCorrect();
    } else {
      _onUpdateHandDrawIncorrect();
    }
  }

  bool _checkStroke(List<Offset> targetStroke, List<Offset?> rawStroke) {
    final List<Offset> stroke = _getNonNullPointsFrom(rawStroke);
    final strokeLength = _getLength(stroke);

    return _strokeIsCorrect(targetStroke, strokeLength, stroke);
  }

  bool _strokeIsCorrect(
      List<Offset> targetStoke, double strokeLength, List<Offset> stroke) {
    final median = targetStoke;
    final medianLength = _getLength(median);

    final List<double> allowedLengthRange =
        _getAllowedLengthRange(medianLength);
    final double startEndMargin = _getStartEndMargin(medianLength);

    bool isCorrect = false;

    if (_strokeLengthWithinBounds(strokeLength, allowedLengthRange) &&
        _strokeStartIsWithinMargin(stroke, median, startEndMargin) &&
        _strokeEndIsWithinMargin(stroke, median, startEndMargin) &&
        _strokeHasRightDirection(stroke, median)) {
      isCorrect = true;
    }
    return isCorrect;
  }

  bool _strokeStartIsWithinMargin(
    List<Offset> points,
    List<Offset> currentMedian,
    double startEndMargin,
  ) {
    final strokeStartWithinMargin =
        points.first.dx > currentMedian.first.dx - startEndMargin &&
            points.first.dx < currentMedian.first.dx + startEndMargin &&
            points.first.dy > currentMedian.first.dy - startEndMargin &&
            points.first.dy < currentMedian.first.dy + startEndMargin;
    return strokeStartWithinMargin;
  }

  bool _strokeEndIsWithinMargin(
    List<Offset> points,
    List<Offset> currentMedian,
    double startEndMargin,
  ) {
    final strokeEndWithinMargin =
        points.last.dx > currentMedian.last.dx - startEndMargin &&
            points.last.dx < currentMedian.last.dx + startEndMargin &&
            points.last.dy > currentMedian.last.dy - startEndMargin &&
            points.last.dy < currentMedian.last.dy + startEndMargin;
    return strokeEndWithinMargin;
  }

  bool _strokeLengthWithinBounds(
      double strokeLength, List<double> lengthRange) {
    return strokeLength > lengthRange[0] && strokeLength < lengthRange[1];
  }

  double _getStartEndMargin(double medianLength) {
    double startEndMargin;

    // Be more lenient on short strokes
    // if (medianLength < 150) {
    //   startEndMargin = 50;
    // } else {
    //   startEndMargin = 50;
    // }
    startEndMargin = 30;
    return startEndMargin;
  }

  List<double> _getAllowedLengthRange(double medianLength) {
    List<double> lengthRange;

    // Be more lenient on short strokes
    // if (medianLength < 150) {
    //   lengthRange = [0.2, 3];
    // } else {
    // }
    lengthRange = [0.5, 1.5];

    return lengthRange.map((e) => e * medianLength).toList();
  }

  List<Offset> _getNonNullPointsFrom(List<Offset?> rawPoints) {
    final List<Offset> points = [];

    for (final point in rawPoints) {
      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }

  double _getLength(List<Offset> points) {
    double pathLength = 0;

    final path = _convertOffsetsToPath(points);
    final pathMetrics = path.computeMetrics().toList();

    if (pathMetrics.isNotEmpty) {
      pathLength = pathMetrics.first.length;
    }
    return pathLength;
  }

  Path _convertOffsetsToPath(List<Offset> points) {
    final path = Path();

    if (points.length > 1) {
      path.moveTo(points[0].dx, points[0].dy);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  bool _strokeHasRightDirection(
    List<Offset> points,
    List<Offset> currentMedian,
  ) {
    return (_distance2D(points.first, currentMedian.first) <
            _distance2D(points.last, currentMedian.first)) ||
        (_distance2D(points.last, currentMedian.last) <
            _distance2D(points.first, currentMedian.last));
  }

  double _distance2D(Offset p, Offset q) {
    return sqrt(pow(p.dx - q.dx, 2) + pow(p.dy - q.dy, 2));
  }

  int findNearestIndexOffset(Offset targetOffset, List<Offset> offsets) {
    double minDistance = double.infinity;
    int index = 0;
    for (int i = 0; i < offsets.length; i++) {
      Offset offset = offsets[i];
      double distance = (offset - targetOffset).distanceSquared;
      if (distance < minDistance) {
        minDistance = distance;
        index = i;
      }
    }
    return index;
  }
}
