import 'dart:math';

import 'package:flutter/material.dart';
import 'package:text_stroke_order/src/extensions.dart';

import '../text_stroke_order.dart';
import 'callback.dart';

import 'dart:ui' as ui;

import 'utils.dart';

class PaintedPainter extends PathPainter {
  PaintedPainter({
    required Animation<double> animation,
    required List<PathSegment> pathSegments,
    required List<TextSegment> textSegments,
    required this.hintSetting,
    required this.tutorialPathSetting,
    required this.isFinish,
    this.handlePositionCallback,
    this.getListCurrentOffsets,
  }) : super(
          animation,
          pathSegments,
          textSegments,
        );
  Function(Offset position)? handlePositionCallback;
  Function(List<Offset>)? getListCurrentOffsets;

  final HintSetting hintSetting;

  final TutorialPathSetting tutorialPathSetting;

  final bool isFinish;

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      if (hintSetting.enable) {
        for (var segment in pathSegments!) {
          var paint = (Paint()
            ..color = hintSetting.color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = hintSetting.strokeWidth);
          canvas.drawPath(segment.path, paint);
        }
      }

      for (var segment in pathSegments!) {
        if (segment.isSkipTutorial) {
          var pathMetric = segment.path.computeMetrics().first;
          _drawTutorialLine(pathMetric, segment.length, segment, canvas);
        } else if (segment.isTutorial) {
          final scale = calculateScaleFactor(Size.copy(size));

          var offset = Offset.zero - pathBoundingBox!.topLeft;
          var center = Offset(
              (size.width / scale.x - pathBoundingBox!.width) / 2,
              (size.height / scale.y - pathBoundingBox!.height) / 2);

          final offsets = segment.getOffsets
              .map((e) => e
                  .translate(offset.dx, offset.dy)
                  .translate(center.dx, center.dy)
                  .scale(scale.x, scale.y))
              .toList();
          getListCurrentOffsets?.call(offsets);
          var drawLength = segment.length * segment.tutorialPercent;
          var pathMetric = segment.path.computeMetrics().first;

          _drawTutorialLine(pathMetric, drawLength, segment, canvas);

          _drawHandleCircle(pathMetric, drawLength, canvas, segment, size);
        }
      }

      //No callback etc. needed
      // super.onFinish(canvas, size);
    }
  }

  void _drawHandleCircle(ui.PathMetric pathMetric, double drawLength,
      Canvas canvas, PathSegment segment, Size size) {
    if (!tutorialPathSetting.handleEnable) return;
    if (segment.isDoneTutorial) return;

    var tagent = pathMetric.getTangentForOffset(drawLength);
    canvas.drawCircle(
        tagent!.position,
        tutorialPathSetting.handleCircleSetting.size,
        Paint()..color = tutorialPathSetting.handleCircleSetting.color);
    final scale = calculateScaleFactor(Size.copy(size));

    var offset = Offset.zero - pathBoundingBox!.topLeft;
    var center = Offset((size.width / scale.x - pathBoundingBox!.width) / 2,
        (size.height / scale.y - pathBoundingBox!.height) / 2);

    handlePositionCallback?.call((tagent.position
        .translate(offset.dx, offset.dy)
        .translate(center.dx, center.dy)
        .scale(scale.x, scale.y)));

    if (tutorialPathSetting.handleCircleSetting.type == HandleType.text) {
      final textSpan = TextSpan(
        text: '${segment.pathIndex}',
        style: tutorialPathSetting.handleCircleSetting.textStyle ??
            const TextStyle(color: Colors.white, fontSize: 6),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      final sizeText = textPainter.size / 2;
      textPainter.paint(
          canvas, tagent.position - Offset(sizeText.width, sizeText.height));
    } else {
      ui.Tangent? lastTagent1;
      ui.Tangent? lastTagent2;
      lastTagent1 = pathMetric.getTangentForOffset(drawLength);
      lastTagent2 = pathMetric.getTangentForOffset(segment.length);

      final p1 = lastTagent1!.position;
      var p2 = lastTagent2!.position;

      final angle = Utils.getAngleOffset(p1, p2);

      const icon = Icons.double_arrow_sharp;
      final textSpan = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
                color: tutorialPathSetting.handleCircleSetting.arrowColor,
                fontSize:
                    (tutorialPathSetting.handleCircleSetting.arrowSize ?? 3) *
                        scale.x)
            .copyWith(fontFamily: icon.fontFamily),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      canvas.drawRotatedText(
          pivot: tagent.position,
          textPainter: textPainter,
          angle: angle,
          alignment: Alignment.center);
    }
  }

  void _drawTutorialLine(ui.PathMetric pathMetric, double drawLength,
      PathSegment segment, Canvas canvas) {
    if (!tutorialPathSetting.enable) return;
    var paint = (Paint()
      ..color = tutorialPathSetting.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = tutorialPathSetting.strokeWidth);
    canvas.drawPath(segment.path, paint);

    _drawDashArrowTutorial(segment, pathMetric, canvas);

    var subPath = pathMetric.extractPath(0, drawLength);
    final p = Paint()
      ..color = isFinish
          ? tutorialPathSetting.finishColor
          : tutorialPathSetting.fillColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = tutorialPathSetting.strokeWidth;
    canvas.drawPath(subPath, p);
  }

  void _drawDashArrowTutorial(
      PathSegment segment, ui.PathMetric pathMetric, Canvas canvas) {
    if (!tutorialPathSetting.arrowDashEnable) return;
    double dashLength = 0;
    double dashWidth = tutorialPathSetting.arrowDashLineSetting.length;
    double dashSpace = tutorialPathSetting.arrowDashLineSetting.spacing;
    final p = Paint()
      ..color = tutorialPathSetting.arrowDashLineSetting.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = tutorialPathSetting.arrowDashLineSetting.strokeWidth;
    while (dashLength < segment.length - dashSpace - dashWidth) {
      var dashStart = dashLength;
      var dashEnd = dashStart + dashWidth;
      var subPath = pathMetric.extractPath(dashStart, dashEnd);
      canvas.drawPath(subPath, p);
      dashLength = dashEnd + dashSpace;
    }
    final lastTagent1 = pathMetric.getTangentForOffset(segment.length * 0.95);
    final lastTagent2 = pathMetric.getTangentForOffset(segment.length);

    final p1 = lastTagent1!.position;
    var p2 = lastTagent2!.position;

    final angle = Utils.getAngleOffset(p1, p2);
    final arrowSize = tutorialPathSetting.arrowDashLineSetting.arrowSize;
    final arrowAngle =
        tutorialPathSetting.arrowDashLineSetting.arrowAngle * pi / 180;

    final path = Path();
    final paint = Paint()
      ..color = tutorialPathSetting.arrowDashLineSetting.color
      ..strokeWidth = 2;
    path.moveTo(p2.dx - arrowSize * cos(angle - arrowAngle),
        p2.dy - arrowSize * sin(angle - arrowAngle));
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p2.dx - arrowSize * cos(angle + arrowAngle),
        p2.dy - arrowSize * sin(angle + arrowAngle));
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Paints a list of [PathSegment] one-by-one to a canvas
class OneByOnePainter extends PathPainter {
  OneByOnePainter({
    required Animation<double> animation,
    required List<PathSegment> pathSegments,
    required List<TextSegment> textSegments,
  })  : totalPathSum = 0,
        super(animation, pathSegments, textSegments) {
    if (this.pathSegments != null) {
      for (var e in this.pathSegments!) {
        totalPathSum += e.length;
      }
    }
  }

  /// The total length of all summed up [PathSegment] elements of the parsed Svg
  double totalPathSum;

  /// The index of the last fully painted segment
  int paintedSegmentIndex = 0;

  /// The total painted path length - the length of the last partially painted segment
  double _paintedLength = 0.0;

  /// Path segments which will be painted to canvas at current frame
  List<PathSegment> toPaint = <PathSegment>[];

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);

    if (canPaint) {
      //[1] Calculate and search for upperBound of total path length which should be painted
      var upperBound = animation.value * totalPathSum;
      var currentIndex = paintedSegmentIndex;
      var currentLength = _paintedLength;
      while (currentIndex < pathSegments!.length - 1) {
        if (currentLength + pathSegments![currentIndex].length < upperBound) {
          toPaint.add(pathSegments![currentIndex]);
          currentLength += pathSegments![currentIndex].length;
          currentIndex++;
        } else {
          break;
        }
      }
      //[2] Extract subPath of last path which breaks the upperBound
      var subPathLength = upperBound - currentLength;
      var lastPathSegment = pathSegments![currentIndex];

      var subPath = lastPathSegment.path
          .computeMetrics()
          .first
          .extractPath(0, subPathLength);
      paintedSegmentIndex = currentIndex;
      _paintedLength = currentLength;
      // //[3] Paint all selected paths to canvas
      Paint paint;
      late Path tmp;
      if (animation.value == 1.0) {
        //hotfix: to ensure callback for last segment to do not pretty
        toPaint.clear();
        toPaint.addAll(pathSegments!);
      } else {
        //[3.1] Add last subPath temporarily
        tmp = Path.from(lastPathSegment.path);
        lastPathSegment.path = subPath;
        toPaint.add(lastPathSegment);
      }
      //[3.2] Restore rendering order - last path element in original PathOrder should be last painted -> most visible
      //[3.3] Paint elements
      for (var segment in (toPaint
        ..sort(
          (a, b) => a.pathIndex.compareTo(b.pathIndex),
        ))) {
        paint = (Paint()
          ..color = animation.value == 1.0
              ? segment.color
              : segment.pathIndex == currentIndex + 1
                  ? segment.animateStrokeColor
                  : segment.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      }

      if (animation.value != 1.0) {
        //[3.4] Remove last subPath
        toPaint.remove(lastPathSegment);
        lastPathSegment.path = tmp;
      } else {
        super.onFinish(canvas, size, lastPainted: toPaint.length - 1);
      }

      //to do Problem: Path drawning is a continous iteration over the length of all segments. To make a callback which fires exactly when path is drawn is therefore not possible (I can only ensure one of the two cases: 1) segment is completely drawn 2) no next segment was started to be drawn yet - For now: 1)
      // double remainingLength = lastPathSegment.length - subPathLength;
    } else {
      paintedSegmentIndex = 0;
      _paintedLength = 0.0;
      toPaint.clear();
    }
  }
}

abstract class PathPainter extends CustomPainter {
  PathPainter(
    this.animation,
    this.pathSegments,
    this.textSegments,
  )   : canPaint = false,
        super(repaint: animation) {
    calculateBoundingBox();
  }

  /// Total bounding box of all paths
  Rect? pathBoundingBox;

  /// For expanding the bounding box when big stroke would breaks the bb
  double? strokeWidth;

  /// User defined dimensions for canvas
  final Animation<double> animation;

  /// Each [PathSegment] represents a continuous Path element of the parsed Svg
  List<PathSegment>? pathSegments;

  List<TextSegment> textSegments;

  /// Status of animation
  bool canPaint;

  /// Evoked when frame is painted
  PaintedSegmentCallback? onFinishCallback;

  late ui.PictureRecorder recorder;

  // Get boundingBox by combining boundingBox of each PathSegment and inflating the resulting bounding box by half of the found max strokeWidth to do find a better solution. This does only work if the stroke with maxWidth defines on side of bounding box. Otherwise it results to unwanted padding.
  void calculateBoundingBox() {
    var bb = pathSegments!.first.path.getBounds();
    var strokeWidth = 0;

    for (var e in pathSegments!) {
      bb = bb.expandToInclude(e.path.getBounds());
      if (strokeWidth < e.strokeWidth) {
        strokeWidth = e.strokeWidth.toInt();
      }
    }

    // if (paints.isNotEmpty) {
    //   for (var e in paints) {
    //     if (strokeWidth < e.strokeWidth) {
    //       strokeWidth = e.strokeWidth.toInt();
    //     }
    //   }
    // }
    pathBoundingBox = bb.inflate(strokeWidth / 2);
    this.strokeWidth = strokeWidth.toDouble();
  }

  void onFinish(Canvas canvas, Size size, {int lastPainted = -1}) {
    onFinishCallback?.call(lastPainted);
  }

  Canvas paintOrDebug(Canvas canvas, Size size) {
    paintPrepare(canvas, size);
    return canvas;
  }

  void paintPrepare(Canvas canvas, Size size) {
    canPaint = animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.completed;

    if (canPaint) viewBoxToCanvas(canvas, size);
  }

  _ScaleFactor calculateScaleFactor(Size viewBox) {
    //Scale factors
    var dx = (viewBox.width) / pathBoundingBox!.width;
    var dy = (viewBox.height) / pathBoundingBox!.height;

    //Applied scale factors
    late double ddx, ddy;

    //No viewport available
    assert(!(dx == 0 && dy == 0));

    //Case 1: Both width/height is specified or MediaQuery
    if (!viewBox.isEmpty) {
      // if (customDimensions != null) {
      //   //Custom width/height
      //   ddx = dx;
      //   ddy = dy;
      // } else {
      //    //Maintain resolution and viewport
      // }
      ddx = ddy = min(dx, dy);
      //Case 2: CustomDimensions specifying only one side
    } else if (dx == 0) {
      ddx = ddy = dy;
    } else if (dy == 0) {
      ddx = ddy = dx;
    }
    return _ScaleFactor(ddx, ddy);
  }

  void viewBoxToCanvas(Canvas canvas, Size size) {
    // if (scaleToViewport) {
    //   //Viewbox with Offset.zero
    //   // var viewBox =
    //   //     (customDimensions != null) ? customDimensions : Size.copy(size);

    // }
    var viewBox = Size.copy(size);
    var scale = calculateScaleFactor(viewBox);
    canvas.scale(scale.x, scale.y);

    //If offset
    var offset = Offset.zero - pathBoundingBox!.topLeft;
    canvas.translate(offset.dx, offset.dy);
    var center = Offset((size.width / scale.x - pathBoundingBox!.width) / 2,
        (size.height / scale.y - pathBoundingBox!.height) / 2);
    canvas.translate(center.dx, center.dy);

    for (var t in textSegments) {
      final textSpan = TextSpan(
        text: t.text,
        style: t.textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(canvas, t.offset - const Offset(0, 7));
    }

    //Clip bounds
    // var clipRect = pathBoundingBox;
    // if (!(debugOptions.showBoundingBox || debugOptions.showViewPort)) {
    //   canvas.clipRect(clipRect!);
    // }

    // if (debugOptions.showBoundingBox) {
    //   var pp = Paint()
    //     ..style = PaintingStyle.stroke
    //     ..color = Colors.red
    //     ..strokeWidth = 0.500;
    //   canvas.drawRect(clipRect!, pp);
    // }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}

class _ScaleFactor {
  const _ScaleFactor(this.x, this.y);
  final double x;
  final double y;
}

class DashViewPortPainter extends CustomPainter {
  final ViewPortDashSetting dashSetting;

  DashViewPortPainter({super.repaint, required this.dashSetting});

  @override
  void paint(Canvas canvas, Size size) {
    if (dashSetting.enable) {
      drawDash(canvas, size);
    }
  }

  void drawDash(Canvas canvas, Size size) {
    double dashWidth = dashSetting.length,
        dashSpace = dashSetting.spacing,
        startX = 0,
        startY = 0;
    final paint = Paint()
      ..color = dashSetting.color
      ..strokeWidth = dashSetting.strokeWidth;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HandWritePainter extends PathPainter {
  final double strokeSize;
  final Color strokeColor;
  final List<Offset> points;

  HandWritePainter(Animation<double> animation, List<PathSegment>? pathSegments,
      this.strokeColor, this.strokeSize, this.points)
      : super(animation, pathSegments, []);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = calculateScaleFactor(size);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeSize * scale.x;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
