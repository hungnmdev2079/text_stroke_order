import 'dart:math';

import 'package:flutter/material.dart';

import 'debug.dart';
import 'painter.dart';
import 'text_stroke_order_controller.dart';

class FollowStrokeOrder extends StatefulWidget {
  const FollowStrokeOrder({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    required this.pading,
    required this.width,
    required this.height,
    this.strokeWidth,
    this.strokeColor,
    this.animatingStrokeColor,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
    this.onEnd,
    this.finishColor,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final double pading;
  final double width;
  final double height;
  final double? strokeWidth;
  final Color? strokeColor;
  final Color? animatingStrokeColor;
  final bool? showDash;
  final Color? dashColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final Function()? onEnd;
  final Color? finishColor;

  @override
  State<FollowStrokeOrder> createState() => _FollowStrokeOrderState();
}

class _FollowStrokeOrderState extends State<FollowStrokeOrder> {
  int currentIndex = 0;

  bool canDraw = true;

  Offset? handlePosition;

  double handleAngle = 0;

  Offset? oldPanPosition;

  List<Offset>? currentOffset;
  bool isFinish = false;

  @override
  void initState() {
    super.initState();
    widget.controller.animationController.forward();
    final partLenght = widget.controller.listPathSegments.length ~/ 2;
    final List<int> idx = [];
    while (idx.length < partLenght) {
      Random random = Random();
      int x = random.nextInt(widget.controller.listPathSegments.length);
      if (!idx.contains(x)) {
        widget.controller.listPathSegments[x].isSkipTutorial = true;
        idx.add(x);
      }
    }
    currentIndex = widget.controller.listPathSegments
        .indexWhere((element) => !element.isSkipTutorial);

    setTutorial();
    widget.controller.addListener(_listener);
  }

  void _listener() {
    if (widget.controller.isReset) {
      _reset();
    }
  }

  setTutorial() {
    canDraw = false;
    widget.controller.listPathSegments[currentIndex].isTutorial = true;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_listener);
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
                if ((handlePosition! - details.localPosition).distance < 25) {
                  canDraw = true;
                } else {
                  canDraw = false;
                }
              },
              onPanStart: (details) {
                if (canDraw = true) {
                  return;
                }
                if ((handlePosition! - details.localPosition).distance < 25) {
                  canDraw = true;
                } else {
                  canDraw = false;
                }
              },
              onPanCancel: () {
                canDraw = false;
              },
              onPanEnd: (details) {
                canDraw = false;
              },
              onPanUpdate: (details) {
                if (!canDraw) {
                  return;
                }
                final o = details.localPosition;
                final x = findNearestIndexOffset(o, currentOffset!);
                var percent = x / (currentOffset!.length - 1);
                setState(() {
                  if (widget.controller.listPathSegments[currentIndex]
                          .isDoneTutorial ==
                      true) {
                    return;
                  }
                  if (percent >= 1) {
                    percent = 1;
                    widget.controller.listPathSegments[currentIndex]
                        .isDoneTutorial = true;
                    widget.controller.listPathSegments[currentIndex]
                        .tutorialPercent = percent;
                    if (currentIndex <
                        widget.controller.listPathSegments.length - 1) {
                      try {
                        do {
                          currentIndex++;
                        } while (widget.controller
                            .listPathSegments[currentIndex].isSkipTutorial);
                        setTutorial();
                      } catch (e) {
                        currentIndex--;
                        _onFinish();
                      }
                    } else {
                      _onFinish();
                    }
                  } else {
                    widget.controller.listPathSegments[currentIndex]
                        .tutorialPercent = percent;
                  }
                });
              },
              child: CustomPaint(
                painter: PaintedPainter(
                    widget.controller.animationController,
                    widget.controller.listPathSegments.map((e) {
                      final segment = e;
                      if (widget.strokeColor != null) {
                        e.color = widget.strokeColor!;
                      }
                      if (widget.strokeWidth != null) {
                        e.strokeWidth = widget.strokeWidth!;
                      }
                      if (widget.animatingStrokeColor != null) {
                        e.animateStrokeColor = widget.animatingStrokeColor!;
                        e.handleColor = widget.animatingStrokeColor!;
                        e.dashArrowColor = widget.animatingStrokeColor!;
                      }
                      if (isFinish) {
                        e.animateStrokeColor = widget.finishColor ??
                            widget.animatingStrokeColor ??
                            Colors.grey;
                      }
                      e.handleSize = 6;

                      return segment;
                    }).toList(),
                    widget.controller.parser!.getTextSegments().map((e) {
                      final segment = e;
                      if (widget.numberStyle != null) {
                        segment.textStyle = widget.numberStyle!;
                      }
                      return segment;
                    }).toList(),
                    null,
                    [],
                    null, (handlePosition) {
                  this.handlePosition = handlePosition;
                }, (listOffsets) {
                  currentOffset = listOffsets;
                },
                    true,
                    DebugOptions(
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

  void _onFinish() {
    isFinish = true;
    widget.onEnd?.call();
  }

  void _reset() {
    isFinish = false;
    currentIndex = widget.controller.listPathSegments
        .indexWhere((element) => !element.isSkipTutorial);
    widget.controller.listPathSegments[currentIndex].isTutorial = true;

    for (var i = 0; i < widget.controller.listPathSegments.length; i++) {
      widget.controller.listPathSegments[i].isDoneTutorial = false;
      if (i != currentIndex) {
        widget.controller.listPathSegments[i].isTutorial = false;
      }
      widget.controller.listPathSegments[i].tutorialPercent = 0;
      widget.controller.listPathSegments[i].animateStrokeColor =
          widget.animatingStrokeColor ?? Colors.grey;
    }
    setState(() {});
  }
}
