import 'package:flutter/material.dart';

import 'debug.dart';
import 'painter.dart';
import 'parser.dart';

class AnimationStrokeOrder extends StatefulWidget {
  const AnimationStrokeOrder({
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
  State<AnimationStrokeOrder> createState() => _AnimationStrokeOrderState();
}

class _AnimationStrokeOrderState extends State<AnimationStrokeOrder>
    with SingleTickerProviderStateMixin {
  late AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = widget.animation ??
        AnimationController(
            vsync: this,
            duration: widget.duration * widget.parser.getPathSegments().length);

    if (widget.animation == null) {
      animation.forward();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    animation = widget.animation ??
        AnimationController(
            vsync: this,
            duration: widget.duration * widget.parser.getPathSegments().length);

    if (widget.animation == null) {
      animation.forward();
    }
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
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return CustomPaint(
              painter: OneByOnePainter(
                  animation,
                  widget.parser.getPathSegments().map((e) {
                    final segment = e;
                    if (widget.strokeColor != null) {
                      e.color = widget.strokeColor!;
                    }
                    if (widget.strokeWidth != null) {
                      e.strokeWidth = widget.strokeWidth!;
                    }
                    if (widget.animatingStrokeColor != null) {
                      e.animateStrokeColor = widget.animatingStrokeColor!;
                    }
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
                  null,
                  true,
                  DebugOptions(
                      showViewPort: widget.showDash ?? true,
                      viewPortColor: widget.dashColor ?? Colors.grey,
                      showNumber: widget.isShowNumber)),
              child: SizedBox(
                width: widget.width - widget.pading,
                height: widget.height - widget.pading,
              ),
            );
          },
        ),
      ),
    );
  }
}
