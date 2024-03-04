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
    required this.pading,
    required this.width,
    required this.height,
    this.strokeColor,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
    this.onEnd,
    this.randomSkipTutorial = false,
    this.onEndStroke,
    required this.tutorialPathSetting,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final double pading;
  final double width;
  final double height;
  final Color? strokeColor;
  final bool? showDash;
  final Color? dashColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final Function()? onEnd;
  final Function()? onEndStroke;
  final bool randomSkipTutorial;
  final TutorialPathSetting tutorialPathSetting;

  @override
  State<SequentialStrokeOrder> createState() => _SequentialStrokeOrderState();
}

class _SequentialStrokeOrderState extends State<SequentialStrokeOrder> {
  StreamSubscription<DrawState>? drawStateListener;
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
    super.dispose();
    widget.controller.removeListener(_listener);
    drawStateListener?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: widget.border,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 0)),
      child: Padding(
        padding: EdgeInsets.all(widget.pading),
        child: Stack(
          children: [
            GestureDetector(
              onTapDown: (details) {
                widget.controller.startDrawCheck(details.localPosition);
              },
              onPanStart: (details) {
                if (widget.controller.canDraw = true) {
                  return;
                }
                widget.controller.startDrawCheck(details.localPosition);
              },
              onPanCancel: () {
                widget.controller.endDrawCheck();
              },
              onPanEnd: (details) {
                widget.controller.endDrawCheck();
              },
              onPanUpdate: (details) {
                widget.controller.updateDrawTutorial(details.localPosition);
              },
              child: CustomPaint(
                painter: PaintedPainter(
                    animation: widget.controller.animationController,
                    pathSegments: widget.controller.listPathSegments,
                    isFinish: drawState == DrawState.finish,
                    textSegments:
                        widget.controller.parser!.getTextSegments().map((e) {
                      final segment = e;
                      if (widget.numberStyle != null) {
                        segment.textStyle = widget.numberStyle!;
                      }
                      return segment;
                    }).toList(),
                    hintSetting:
                        HintSetting(color: widget.strokeColor ?? Colors.grey),
                    tutorialPathSetting: widget.tutorialPathSetting,
                    handlePositionCallback:
                        widget.controller.updateHandlePosision,
                    getListCurrentOffsets:
                        widget.controller.updateListCurrentOffsets,
                    debugOptions: DebugOptions(
                        showViewPort: widget.showDash ?? true,
                        viewPortColor: widget.dashColor ?? Colors.grey,
                        showNumber: widget.isShowNumber)),
                child: SizedBox(
                  width: widget.width - widget.pading,
                  height: widget.height - widget.pading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
