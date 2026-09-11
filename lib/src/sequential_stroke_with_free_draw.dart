import 'dart:async';

import 'package:flutter/material.dart';

import '../text_stroke_order.dart';

class SequentialStrokeWithFreeDraw extends StatefulWidget {
  const SequentialStrokeWithFreeDraw({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.padding,
    required this.width,
    required this.height,
    this.isShowNumber = true,
    this.numberStyle,
    this.onEnd,
    this.onEndStroke,
    this.randomSkipTutorial = false,
    this.onEndStrokeCheck,
    required this.handWriteSetting,
    required this.tutorialPathSetting,
    required this.hintSetting,
    required this.dashSetting,
    this.onEndDraw,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double width;
  final double height;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final Function()? onEnd;
  final Function()? onEndStroke;
  final Function(bool isCorrect)? onEndStrokeCheck;
  final Function()? onEndDraw;
  final bool randomSkipTutorial;

  final HandWriteSetting handWriteSetting;

  final TutorialPathSetting tutorialPathSetting;

  final HintSetting hintSetting;

  final ViewPortDashSetting dashSetting;

  @override
  State<SequentialStrokeWithFreeDraw> createState() =>
      _SequentialStrokeWithFreeDrawState();
}

class _SequentialStrokeWithFreeDrawState
    extends State<SequentialStrokeWithFreeDraw> {
  StreamSubscription<DrawState>? drawStateListener;
  StreamSubscription<HandDrawState>? handDrawStateListener;
  DrawState drawState = DrawState.none;

  final List<Offset> points = [];
  int? _activePointer;

  EdgeInsetsGeometry get _padding => widget.padding ?? EdgeInsets.zero;

  Offset _toDrawingPosition(Offset localPosition) {
    final padding = _padding;
    return localPosition - Offset(padding.horizontal / 2, padding.vertical / 2);
  }

  void _startStroke(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    points
      ..clear()
      ..add(_toDrawingPosition(event.localPosition));
    setState(() {});
  }

  void _updateStroke(PointerMoveEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    points.add(_toDrawingPosition(event.localPosition));
    setState(() {});
  }

  void _finishStroke(int pointer, {required bool notifyEndDraw}) {
    if (_activePointer != pointer) {
      return;
    }
    widget.controller.checkHandWriteStroke(points);
    points.clear();
    _activePointer = null;
    setState(() {});
    if (notifyEndDraw) {
      widget.onEndDraw?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.animationController.forward();
    if (widget.randomSkipTutorial) {
      widget.controller.setRandomSkipStrokeOrder();
    }
    // widget.controller.updateAnimateStrokeColor(widget.animatingStrokeColor);
    widget.controller.updateTutorial();
    widget.controller.addListener(_listener);
    drawStateListener =
        widget.controller.drawStreamState.stream.listen(_listenState);
    handDrawStateListener = widget.controller.handDrawStreamState.stream
        .listen(_listenHandDrawState);
  }

  void _listenState(DrawState event) {
    drawState = event;
    switch (event) {
      case DrawState.endStroke:
        widget.onEndStroke?.call();
        break;
      case DrawState.finish:
        widget.onEnd?.call();
        break;
      default:
    }
  }

  void _listenHandDrawState(HandDrawState event) {
    widget.onEndStrokeCheck?.call(event == HandDrawState.correct);
  }

  void _listener() {
    setState(() {});
  }

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   widget.controller.setRandomSkipStrokeOrder();
  //   widget.controller.updateTutorial();
  // }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    drawStateListener?.cancel();
    handDrawStateListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (_) {},
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _startStroke,
        onPointerMove: _updateStroke,
        onPointerUp: (event) {
          _finishStroke(event.pointer, notifyEndDraw: true);
        },
        onPointerCancel: (event) {
          _finishStroke(event.pointer, notifyEndDraw: false);
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.transparent,
            border: widget.border,
            borderRadius: widget.borderRadius == null
                ? null
                : BorderRadius.circular(widget.borderRadius!),
          ),
          padding: _padding,
          child: CustomPaint(
            painter: PaintedPainter(
              animation: widget.controller.animationController,
              pathSegments: widget.controller.listPathSegments,
              tutorialPathSetting: widget.tutorialPathSetting,
              hintSetting: widget.hintSetting,
              isFinish: drawState == DrawState.finish,
              textSegments: widget.isShowNumber
                  ? widget.controller.parser!.getTextSegments().map((e) {
                      final segment = e;
                      if (widget.numberStyle != null) {
                        segment.textStyle = widget.numberStyle!;
                      }
                      return segment;
                    }).toList()
                  : [],
              handlePositionCallback: widget.controller.updateHandlePosision,
              getListCurrentOffsets: widget.controller.updateListCurrentOffsets,
            ),
            foregroundPainter: HandWritePainter(
                widget.controller.animationController,
                widget.controller.listPathSegments,
                widget.handWriteSetting.color,
                widget.handWriteSetting.size,
                points),
            child: SizedBox(
              width: widget.width - (widget.padding?.horizontal ?? 0),
              height: widget.height - (widget.padding?.vertical ?? 0),
            ),
          ),
        ),
      ),
    );
  }
}
