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
    animationController.dispose();
    drawStreamState.close();
    handDrawStreamState.close();
    super.dispose();
  }

  void initialAnimate(bool autoAnimate) {
    final d = duration ?? const Duration(seconds: 1);
    animationController.duration = d * listPathSegments.length;
    if (autoAnimate) {
      startAnimation();
    }
  }

  void startAnimation() {
    animationController.reset();
    animationController.forward();
  }

  void resetAnimation() {
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
    try {
      await resolve;
      return true;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    if (listPathSegments.isEmpty) {
      return;
    }
    _resetStateDraw();
    currentIndex =
        listPathSegments.indexWhere((element) => !element.isSkipTutorial);
    if (currentIndex == -1) {
      currentIndex = 0;
    }
    listPathSegments[currentIndex].isTutorial = true;

    for (var i = 0; i < listPathSegments.length; i++) {
      listPathSegments[i].isDoneTutorial = false;
      if (i != currentIndex) {
        listPathSegments[i].isTutorial = false;
      }
      listPathSegments[i].tutorialPercent = 0;
      listPathSegments[i].currentIndexOffset = 0;
    }
    notifyListeners();
  }

  void setRandomSkipStrokeOrder() {
    if (listPathSegments.length <= 1) {
      currentIndex = 0;
      return;
    }
    final partLenght = listPathSegments.length ~/ 2;
    final List<int> idx = [];
    final random = Random();
    for (var i = 0; i < listPathSegments.length; i++) {
      listPathSegments[i].isTutorial = false;
      listPathSegments[i].isSkipTutorial = false;
      listPathSegments[i].tutorialPercent = 0;
      listPathSegments[i].currentIndexOffset = 0;
      listPathSegments[i].isDoneTutorial = false;
    }
    while (idx.length < partLenght) {
      final x = random.nextInt(listPathSegments.length);
      if (!idx.contains(x)) {
        listPathSegments[x].isSkipTutorial = true;
        idx.add(x);
      }
    }
    currentIndex =
        listPathSegments.indexWhere((element) => !element.isSkipTutorial);
  }

  void updateTutorial() {
    if (listPathSegments.isEmpty || currentIndex < 0) {
      return;
    }
    canDraw = false;
    listPathSegments[currentIndex].isTutorial = true;
    notifyListeners();
  }

  void startDrawCheck(Offset position) {
    if (handlePosition == null) {
      return;
    }
    if ((handlePosition! - position).distance < 30) {
      canDraw = true;
    } else {
      canDraw = false;
    }
  }

  void endDrawCheck() {
    canDraw = false;
  }

  void updateDrawTutorial(Offset position) {
    final offsets = currentOffset;
    if (!canDraw || offsets == null || offsets.length < 2) {
      return;
    }
    // _resetStateDraw();
    final o = position;
    final x = findNearestIndexOffset(
        listPathSegments[currentIndex].currentIndexOffset, o, offsets);
    listPathSegments[currentIndex].currentIndexOffset = x;
    var percent = x / (offsets.length - 1);

    if (listPathSegments[currentIndex].isDoneTutorial == true) {
      return;
    }
    if (percent >= 0.95) {
      percent = 1;
      listPathSegments[currentIndex].isDoneTutorial = true;
      listPathSegments[currentIndex].tutorialPercent = percent;
      _nextStroke();
    } else {
      listPathSegments[currentIndex].tutorialPercent = percent;
    }
    notifyListeners();
  }

  bool nextStroke() {
    listPathSegments[currentIndex].isDoneTutorial = true;
    listPathSegments[currentIndex].tutorialPercent = 1;
    listPathSegments[currentIndex].currentIndexOffset =
        listPathSegments[currentIndex].getOffsets.length;
    final canNext = _nextStroke();
    notifyListeners();
    return canNext;
  }

  bool _nextStroke() {
    if (currentIndex < listPathSegments.length - 1) {
      try {
        do {
          currentIndex++;
        } while (listPathSegments[currentIndex].isSkipTutorial);
        updateTutorial();
        _onEndStroke();
        return true;
      } catch (e) {
        currentIndex--;
        _onFinish();
        return false;
      }
    } else {
      _onFinish();
      return false;
    }
  }

  void _onFinish() {
    drawStreamState.add(DrawState.finish);
  }

  void _onEndStroke() {
    drawStreamState.add(DrawState.endStroke);
  }

  void _onUpdateHandDrawCorrect() {
    handDrawStreamState.add(HandDrawState.correct);
  }

  void _onUpdateHandDrawIncorrect() {
    handDrawStreamState.add(HandDrawState.inCorrect);
  }

  void _resetStateDraw() {
    drawStreamState.add(DrawState.none);
  }

  void updateHandlePosision(Offset position) {
    handlePosition = position;
  }

  void updateListCurrentOffsets(List<Offset> offsets) {
    currentOffset = offsets;
  }

  void checkHandWriteStroke(List<Offset?> rawStroke) {
    final bool isCorrect = _checkStroke(currentOffset ?? [], rawStroke);
    if (isCorrect) {
      listPathSegments[currentIndex].isDoneTutorial = true;
      listPathSegments[currentIndex].tutorialPercent = 1;
      listPathSegments[currentIndex].currentIndexOffset =
          listPathSegments[currentIndex].getOffsets.length;
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
    if (targetStoke.isEmpty || stroke.isEmpty) {
      return false;
    }
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
    startEndMargin = 50;
    return startEndMargin;
  }

  List<double> _getAllowedLengthRange(double medianLength) {
    List<double> lengthRange;

    // Be more lenient on short strokes
    // if (medianLength < 150) {
    //   lengthRange = [0.2, 3];
    // } else {
    // }
    lengthRange = [0.5, 3];

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

  int findNearestIndexOffset(
      int lastIndex, Offset targetOffset, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return lastIndex;
    }

    final safeLastIndex = lastIndex < 0
        ? 0
        : lastIndex >= offsets.length
            ? offsets.length - 1
            : lastIndex;
    double minDistance = double.infinity;
    int nearestIndex = safeLastIndex;
    for (int i = safeLastIndex; i < offsets.length; i++) {
      final distance = (offsets[i] - targetOffset).distanceSquared;
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    final indexAdvance = nearestIndex - safeLastIndex;
    if (indexAdvance < 20) {
      return nearestIndex;
    }

    // Offsets are already transformed into the rendered canvas coordinates.
    // On a small canvas many SVG samples can fit inside a short finger move,
    // so limiting progress only by sample count makes drawing get stuck after
    // GestureDetector's initial touch slop. Keep the old sample guard, but
    // allow a larger index jump when it is still a short on-screen movement.
    double renderedAdvance = 0;
    for (int i = safeLastIndex + 1; i <= nearestIndex; i++) {
      renderedAdvance += (offsets[i] - offsets[i - 1]).distance;
      if (renderedAdvance > 30) {
        return safeLastIndex;
      }
    }

    return nearestIndex;
  }
}
