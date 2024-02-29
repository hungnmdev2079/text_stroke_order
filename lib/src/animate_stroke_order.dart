import 'package:flutter/material.dart';
import 'package:text_stroke_order/src/text_stroke_order_controller.dart';

import 'debug.dart';
import 'painter.dart';

class AnimationStrokeOrder extends StatefulWidget {
  const AnimationStrokeOrder({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    required this.pading,
    required this.width,
    required this.height,
    this.animation,
    this.strokeWidth,
    this.strokeColor,
    this.animatingStrokeColor,
    this.showDash,
    this.dashColor,
    this.isShowNumber = true,
    this.numberStyle,
  });

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final double pading;
  final double width;
  final double height;
  final AnimationController? animation;
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

class _AnimationStrokeOrderState extends State<AnimationStrokeOrder> {
  @override
  void initState() {
    super.initState();
    widget.controller.animationController.duration =
        (widget.controller.duration ?? Duration(seconds: 1)) *
            widget.controller.parser!.getPathSegments().length;

    widget.controller.animationController.forward();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.controller.animationController.reset();
    widget.controller.animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.animationController.dispose();
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
          animation: widget.controller.animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: OneByOnePainter(
                  widget.controller.animationController,
                  widget.controller.parser!.getPathSegments().map((e) {
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
                  widget.controller.parser!.getTextSegments().map((e) {
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
