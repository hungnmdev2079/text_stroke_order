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
    required this.pading,
    required this.width,
    required this.height,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
    this.onEnd,
    this.onEndStroke,
    this.randomSkipTutorial = false,
    this.onEndStrokeCheck,
    required this.handWriteSetting,
    required this.tutorialPathSetting,
    required this.hintSetting,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final double pading;
  final double width;
  final double height;
  final bool? showDash;
  final Color? dashColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final Function()? onEnd;
  final Function()? onEndStroke;
  final Function(bool isCorrect)? onEndStrokeCheck;
  final bool randomSkipTutorial;

  final HandWriteSetting handWriteSetting;

  final TutorialPathSetting tutorialPathSetting;

  final HintSetting hintSetting;

  @override
  State<SequentialStrokeWithFreeDraw> createState() =>
      _SequentialStrokeWithFreeDrawState();
}

class _SequentialStrokeWithFreeDrawState
    extends State<SequentialStrokeWithFreeDraw> {
  StreamSubscription<DrawState>? drawStateListener;
  StreamSubscription<HandDrawState>? handDrawStateListener;
  DrawState drawState = DrawState.none;
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
    super.dispose();
    widget.controller.removeListener(_listener);
    drawStateListener?.cancel();
    handDrawStateListener?.cancel();
  }

  List<Offset> points = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: widget.border,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 0)),
      child: Padding(
        padding: EdgeInsets.all(widget.pading),
        child: GestureDetector(
          onTapDown: (details) {
            points.clear();
            points.add(details.localPosition);
          },
          onPanStart: (details) {
            points.add(details.localPosition);
          },
          onPanCancel: () {
            widget.controller.checkHandWriteStroke(points);
            points.clear();
            setState(() {});
          },
          onPanEnd: (details) {
            widget.controller.checkHandWriteStroke(points);
            points.clear();
            setState(() {});
          },
          onPanUpdate: (details) {
            points.add(details.localPosition);
            setState(() {});
          },
          child: CustomPaint(
            painter: PaintedPainter(
                animation: widget.controller.animationController,
                pathSegments: widget.controller.listPathSegments,
                tutorialPathSetting: widget.tutorialPathSetting,
                hintSetting: widget.hintSetting,
                isFinish: drawState == DrawState.finish,
                textSegments:
                    widget.controller.parser!.getTextSegments().map((e) {
                  final segment = e;
                  if (widget.numberStyle != null) {
                    segment.textStyle = widget.numberStyle!;
                  }
                  return segment;
                }).toList(),
                handlePositionCallback: widget.controller.updateHandlePosision,
                getListCurrentOffsets:
                    widget.controller.updateListCurrentOffsets,
                debugOptions: DebugOptions(
                    showViewPort: widget.showDash ?? true,
                    viewPortColor: widget.dashColor ?? Colors.grey,
                    showNumber: widget.isShowNumber)),
            foregroundPainter: HandWritePainter(
                widget.controller.animationController,
                widget.controller.listPathSegments,
                widget.handWriteSetting.color,
                widget.handWriteSetting.size,
                points),
            child: SizedBox(
              width: widget.width - widget.pading,
              height: widget.height - widget.pading,
            ),
          ),
        ),
      ),
    );
  }
}
