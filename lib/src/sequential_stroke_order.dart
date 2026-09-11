import 'dart:async';

import 'package:flutter/material.dart';

import '../text_stroke_order.dart';

class SequentialStrokeOrder extends StatefulWidget {
  const SequentialStrokeOrder({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.padding,
    required this.width,
    required this.height,
    this.strokeColor,
    this.isShowNumber = true,
    this.numberStyle,
    this.onEnd,
    this.randomSkipTutorial = false,
    this.onEndStroke,
    required this.tutorialPathSetting,
    required this.dashSetting,
    required this.hintSetting,
    this.onEndDraw,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double width;
  final double height;
  final Color? strokeColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final Function()? onEnd;
  final Function()? onEndStroke;
  final Function()? onEndDraw;
  final bool randomSkipTutorial;
  final TutorialPathSetting tutorialPathSetting;
  final ViewPortDashSetting dashSetting;
  final HintSetting hintSetting;

  @override
  State<SequentialStrokeOrder> createState() => _SequentialStrokeOrderState();
}

class _SequentialStrokeOrderState extends State<SequentialStrokeOrder> {
  StreamSubscription<DrawState>? drawStateListener;
  DrawState drawState = DrawState.none;
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
    widget.controller.startDrawCheck(_toDrawingPosition(event.localPosition));
  }

  void _updateStroke(PointerMoveEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    widget.controller.updateDrawTutorial(
      _toDrawingPosition(event.localPosition),
    );
  }

  void _finishStroke(int pointer, {required bool notifyEndDraw}) {
    if (_activePointer != pointer) {
      return;
    }
    widget.controller.endDrawCheck();
    _activePointer = null;
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

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    drawStateListener?.cancel();
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
              hintSetting: widget.hintSetting,
              tutorialPathSetting: widget.tutorialPathSetting,
              handlePositionCallback: widget.controller.updateHandlePosision,
              getListCurrentOffsets: widget.controller.updateListCurrentOffsets,
            ),
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
