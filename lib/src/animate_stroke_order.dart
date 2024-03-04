import 'package:flutter/material.dart';
import 'package:text_stroke_order/text_stroke_order.dart';

class AnimationStrokeOrder extends StatefulWidget {
  const AnimationStrokeOrder(
      {super.key,
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
      this.autoAnimate = true});

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
  final bool autoAnimate;

  @override
  State<AnimationStrokeOrder> createState() => _AnimationStrokeOrderState();
}

class _AnimationStrokeOrderState extends State<AnimationStrokeOrder> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialAnimate(widget.autoAnimate);
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.controller.initialAnimate(widget.autoAnimate);
  }

  @override
  void dispose() {
    super.dispose();
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
