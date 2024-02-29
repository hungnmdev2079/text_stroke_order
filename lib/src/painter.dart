import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:text_stroke_order/src/utils.dart';

import '../text_stroke_order.dart';
import 'callback.dart';

import 'dart:ui' as ui;

class PaintedPainter extends PathPainter {
  PaintedPainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      List<TextSegment> textSegments,
      Size? customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback? onFinishCallback,
      this.handlePositionCallback,
      this.getListCurrentOffsets,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : super(animation, pathSegments, textSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions);
  Function(Offset position)? handlePositionCallback;
  Function(List<Offset>)? getListCurrentOffsets;

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      //pathSegments for AllAtOncePainter are always in the order of PathOrders.original

      for (var segment in pathSegments!) {
        var paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
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
    if (segment.isDoneTutorial) {
      return;
    }
    var tagent = pathMetric.getTangentForOffset(drawLength);
    canvas.drawCircle(tagent!.position, segment.handleSize,
        Paint()..color = segment.handleColor);
    final scale = calculateScaleFactor(Size.copy(size));

    var offset = Offset.zero - pathBoundingBox!.topLeft;
    var center = Offset((size.width / scale.x - pathBoundingBox!.width) / 2,
        (size.height / scale.y - pathBoundingBox!.height) / 2);

    handlePositionCallback?.call((tagent.position
        .translate(offset.dx, offset.dy)
        .translate(center.dx, center.dy)
        .scale(scale.x, scale.y)));

    final textSpan = TextSpan(
      text: '${segment.pathIndex}',
      style: TextStyle(color: Colors.white, fontSize: 6),
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
  }

  void _drawTutorialLine(ui.PathMetric pathMetric, double drawLength,
      PathSegment segment, Canvas canvas) {
    var paint = (paints.isNotEmpty)
        ? paints[segment.pathIndex]
        : (Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = segment.strokeWidth);
    canvas.drawPath(segment.path, paint);

    _drawDashArrowTutorial(segment, pathMetric, canvas);

    var subPath = pathMetric.extractPath(0, drawLength);

    final p = Paint()
      ..color = segment.animateStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = segment.strokeWidth;
    canvas.drawPath(subPath, p);
  }

  void _drawDashArrowTutorial(
      PathSegment segment, ui.PathMetric pathMetric, Canvas canvas) {
    double dashLength = 0;
    double dashWidth = segment.dashWith;
    double dashSpace = segment.dashSpace;
    while (dashLength < segment.length - dashSpace - dashWidth) {
      var dashStart = dashLength;
      var dashEnd = dashStart + dashWidth;
      var subPath = pathMetric.extractPath(dashStart, dashEnd);
      final p = Paint()
        ..color = segment.dashArrowColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.5;
      canvas.drawPath(subPath, p);
      //
      dashLength = dashEnd + dashSpace;
    }
    final lastTagent1 = pathMetric.getTangentForOffset(segment.length * 0.95);
    final lastTagent2 = pathMetric.getTangentForOffset(segment.length);

    final p1 = lastTagent1!.position;
    var p2 = lastTagent2!.position;

    final angle = Utils.getAngleOffset(p1, p2);
    final arrowSize = 5;
    final arrowAngle = 25 * pi / 180;

    final path = Path();
    final paint = Paint()
      ..color = segment.dashArrowColor
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
  OneByOnePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      List<TextSegment> textSegments,
      Size? customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback? onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : totalPathSum = 0,
        super(animation, pathSegments, textSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions) {
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
        paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint() //Paint per path to do implement Paint per PathSegment?
              //to do Debug disappearing first lineSegment
              // ..color = (segment.relativeIndex == 0 && segment.pathIndex== 0) ? Colors.red : ((segment.relativeIndex == 1) ? Colors.blue : segment.color)
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
      this.customDimensions,
      this.paints,
      this.onFinishCallback,
      this.scaleToViewport,
      this.debugOptions)
      : canPaint = false,
        super(repaint: animation) {
    calculateBoundingBox();
  }

  /// Total bounding box of all paths
  Rect? pathBoundingBox;

  /// For expanding the bounding box when big stroke would breaks the bb
  double? strokeWidth;

  /// User defined dimensions for canvas
  Size? customDimensions;
  final Animation<double> animation;

  /// Each [PathSegment] represents a continuous Path element of the parsed Svg
  List<PathSegment>? pathSegments;

  List<TextSegment> textSegments;

  /// Substitutes the paint object for each [PathSegment]
  List<Paint> paints;

  /// Status of animation
  bool canPaint;

  bool scaleToViewport;

  /// Evoked when frame is painted
  PaintedSegmentCallback? onFinishCallback;

  //For debug - show widget and svg bounding box and record canvas to *.png
  DebugOptions debugOptions;
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

    if (paints.isNotEmpty) {
      for (var e in paints) {
        if (strokeWidth < e.strokeWidth) {
          strokeWidth = e.strokeWidth.toInt();
        }
      }
    }
    pathBoundingBox = bb.inflate(strokeWidth / 2);
    this.strokeWidth = strokeWidth.toDouble();
  }

  void onFinish(Canvas canvas, Size size, {int lastPainted = -1}) {
    //-1: no segment was painted yet, 0 first segment
    if (debugOptions.recordFrames) {
      final picture = recorder.endRecording();
      var frame = getFrameCount(debugOptions);
      if (frame >= 0) {
        debugPrint('Write frame $frame');
        //pass size when you want the whole viewport of the widget
        writeToFile(
            picture,
            '${debugOptions.outPutDir}/${debugOptions.fileName}_$frame.png',
            size);
      }
    }
    onFinishCallback?.call(lastPainted);
  }

  Canvas paintOrDebug(Canvas canvas, Size size) {
    if (debugOptions.recordFrames) {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);
      //Color background
      // canvas.drawColor(Color.fromRGBO(224, 121, 42, 1.0),BlendMode.srcOver);
      //factor for higher resolution
      canvas.scale(
          debugOptions.resolutionFactor, debugOptions.resolutionFactor);
    }
    paintPrepare(canvas, size);
    return canvas;
  }

  void paintPrepare(Canvas canvas, Size size) {
    canPaint = animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.completed;

    if (canPaint) viewBoxToCanvas(canvas, size);
  }

  Future<void> writeToFile(
      ui.Picture picture, String fileName, Size size) async {
    var scale = calculateScaleFactor(size);
    var byteData = await ((await picture.toImage(
            (scale.x * debugOptions.resolutionFactor * pathBoundingBox!.width)
                .round(),
            (scale.y * debugOptions.resolutionFactor * pathBoundingBox!.height)
                .round()))
        .toByteData(format: ui.ImageByteFormat.png));
    final buffer = byteData!.buffer;
    await File(fileName).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    debugPrint('File: $fileName written.');
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
      if (customDimensions != null) {
        //Custom width/height
        ddx = dx;
        ddy = dy;
      } else {
        ddx = ddy = min(dx, dy); //Maintain resolution and viewport
      }
      //Case 2: CustomDimensions specifying only one side
    } else if (dx == 0) {
      ddx = ddy = dy;
    } else if (dy == 0) {
      ddx = ddy = dx;
    }
    return _ScaleFactor(ddx, ddy);
  }

  void drawDash(Canvas canvas, Size size) {
    double dashWidth = 9, dashSpace = 5, startX = 0, startY = 0;
    final paint = Paint()
      ..color = debugOptions.viewPortColor
      ..strokeWidth = 1;
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

  void viewBoxToCanvas(Canvas canvas, Size size) {
    if (debugOptions.showViewPort) {
      // var clipRect1 = Offset.zero & size;
      // var ppp = Paint()
      //   ..style = PaintingStyle.stroke
      //   ..color = Colors.green
      //   ..strokeWidth = 10.50;
      // canvas.drawRect(clipRect1, ppp);
      drawDash(canvas, size);
    }

    if (scaleToViewport) {
      //Viewbox with Offset.zero
      var viewBox =
          (customDimensions != null) ? customDimensions : Size.copy(size);
      var scale = calculateScaleFactor(viewBox!);
      canvas.scale(scale.x, scale.y);

      //If offset
      var offset = Offset.zero - pathBoundingBox!.topLeft;
      canvas.translate(offset.dx, offset.dy);

      if (debugOptions.recordFrames != true) {
        var center = Offset((size.width / scale.x - pathBoundingBox!.width) / 2,
            (size.height / scale.y - pathBoundingBox!.height) / 2);
        canvas.translate(center.dx, center.dy);
      }
    }

    if (debugOptions.showNumber) {
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
