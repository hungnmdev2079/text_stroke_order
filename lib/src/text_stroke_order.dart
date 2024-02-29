import 'package:flutter/material.dart';
import 'package:text_stroke_order/src/utils.dart';

import '../text_stroke_order.dart';
import 'animate_stroke_order.dart';

class TextStrokeOrder extends StatefulWidget {
  const TextStrokeOrder({
    super.key,
    required this.provider,
    this.type = TextStrokeOrderType.animation,
    this.animation,
    this.animationDuration,
    this.loadingBuilder,
    this.width = 300,
    this.height = 300,
    this.pading = 0,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.strokeWidth,
    this.strokeColor,
    this.animatingStrokeColor,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
  });

  final SvgProvider provider;
  final TextStrokeOrderType type;

  final AnimationController? animation;

  final Duration? animationDuration;

  final Widget Function(BuildContext context)? loadingBuilder;

  final double width;

  final double height;

  final double pading;

  final Color? backgroundColor;

  final double? borderRadius;

  final Border? border;

  final double? strokeWidth;

  final Color? strokeColor;

  final Color? animatingStrokeColor;

  final bool? showDash;

  final Color? dashColor;

  final bool isShowNumber;

  final TextStyle? numberStyle;

  @override
  State<TextStrokeOrder> createState() => _TextStrokeOrderState();
}

class _TextStrokeOrderState extends State<TextStrokeOrder> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SvgParser>(
      future: widget.provider.resolve(),
      builder: (context, snapshot) {
        final parser = snapshot.data;
        if (parser != null) {
          return _buildBody(parser);
        } else {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildBody(SvgParser parser) {
    switch (widget.type) {
      case TextStrokeOrderType.animation:
        return AnimationStrokeOrder(
          parser: parser,
          height: widget.height,
          pading: widget.pading,
          width: widget.width,
          animation: widget.animation,
          backgroundColor: widget.backgroundColor,
          border: widget.border,
          borderRadius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
          strokeColor: widget.strokeColor,
          animatingStrokeColor: widget.animatingStrokeColor,
          showDash: widget.showDash,
          dashColor: widget.dashColor,
          isShowNumber: widget.isShowNumber,
          numberStyle: widget.numberStyle,
          duration: widget.animationDuration ?? const Duration(seconds: 1),
        );
      case TextStrokeOrderType.followTutorial:
        return FollowStrokeOrder(
          parser: parser,
          height: widget.height,
          pading: widget.pading,
          width: widget.width,
          animation: widget.animation,
          backgroundColor: widget.backgroundColor,
          border: widget.border,
          borderRadius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
          strokeColor: widget.strokeColor,
          animatingStrokeColor: widget.animatingStrokeColor,
          showDash: widget.showDash,
          dashColor: widget.dashColor,
          isShowNumber: widget.isShowNumber,
          numberStyle: widget.numberStyle,
          duration: widget.animationDuration ?? const Duration(seconds: 1),
        );
      default:
        return const SizedBox();
    }
  }
}

class FollowStrokeOrder extends StatefulWidget {
  const FollowStrokeOrder({
    super.key,
    required this.parser,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    required this.pading,
    required this.width,
    required this.height,
    this.animation,
    required this.duration,
    this.strokeWidth,
    this.strokeColor,
    this.animatingStrokeColor,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
  });

  final SvgParser parser;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final double pading;
  final double width;
  final double height;
  final AnimationController? animation;
  final Duration duration;
  final double? strokeWidth;
  final Color? strokeColor;
  final Color? animatingStrokeColor;
  final bool? showDash;
  final Color? dashColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;

  @override
  State<FollowStrokeOrder> createState() => _FollowStrokeOrderState();
}

class _FollowStrokeOrderState extends State<FollowStrokeOrder>
    with TickerProviderStateMixin {
  late AnimationController animation;

  late List<PathSegment> listSegment;
  int currentIndex = 0;

  bool canDraw = true;

  Offset? oldHandlePosition;

  double handleAngle = 0;

  Offset? oldPanPosition;

  @override
  void initState() {
    super.initState();
    listSegment = widget.parser.getPathSegments();
    setTutorial();
    animation = AnimationController(vsync: this, duration: Duration.zero);
    animation.forward();
  }

  setTutorial() {
    canDraw = false;
    listSegment[currentIndex].isTutorial = true;
    // for (var i = 0; i < listSegment.length; i++) {
    //   if (i == currentIndex) {
    //     listSegment[i].isTutorial = true;
    //     // listSegment[i].isDoneTutorial = false;
    //   } else {
    //     listSegment[i].isTutorial = false;
    //   }
    // }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    animation.dispose();
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
                //print(details.localPosition);
                canDraw = true;
                oldPanPosition = details.localPosition;
              },
              onPanStart: (details) {
                // print('${details.localPosition} hehe');
              },
              onPanUpdate: (details) {
                if (!canDraw) {
                  return;
                }
                final angle = Utils.getAngleOffset(
                    oldPanPosition!, details.localPosition);
                // print(angle);
                // print("Angle : $handleAngle");
                oldPanPosition = details.localPosition;

                if ((angle - handleAngle).abs() > 0.25) {
                  return;
                }

                setState(() {
                  var s = listSegment[currentIndex].tutorialPercent;
                  var l = listSegment[currentIndex].length * s;
                  l = (l + listSegment[currentIndex].length * 0.05);
                  var t = l / listSegment[currentIndex].length;
                  if (t >= 0.9) {
                    t = 1;
                    listSegment[currentIndex].isDoneTutorial = true;
                    listSegment[currentIndex].tutorialPercent = t;

                    if (currentIndex < listSegment.length - 1) {
                      currentIndex++;
                      setTutorial();
                    }
                  } else {
                    listSegment[currentIndex].tutorialPercent = t;
                  }
                  print(t);
                });

                // print(details.localPosition);
                // print(details.delta.direction);

                // final pathMetric =
                //     listSegment[currentIndex].path.computeMetrics().first;
                // final angle = pathMetric
                //     .getTangentForOffset(listSegment[currentIndex].length / 4)!
                //     .angle;
              },
              child: CustomPaint(
                painter: PaintedPainter(
                    animation,
                    listSegment.map((e) {
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
                      e.handleSize = 6;

                      return segment;
                    }).toList(),
                    widget.parser.getTextSegments().map((e) {
                      final segment = e;
                      if (widget.numberStyle != null) {
                        segment.textStyle = widget.numberStyle!;
                      }
                      return segment;
                    }).toList(),
                    null,
                    [],
                    null, (handlePosition, nextHandlePosition) {
                  oldHandlePosition = handlePosition;
                  handleAngle =
                      Utils.getAngleOffset(handlePosition, nextHandlePosition);
                  //oldHandlePosition = handlePosition;
                  print('handle position: $handlePosition');
                  print('next handle position: $nextHandlePosition');
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
}
