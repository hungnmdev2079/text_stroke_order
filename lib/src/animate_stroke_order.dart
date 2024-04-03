import 'package:flutter/material.dart';

import 'models/model.dart';
import 'painter.dart';
import 'text_stroke_order_controller.dart';

class AnimationStrokeOrder extends StatefulWidget {
  const AnimationStrokeOrder(
      {super.key,
      required this.controller,
      this.backgroundColor,
      this.border,
      this.borderRadius,
      this.padding,
      required this.width,
      required this.height,
      this.strokeWidth,
      this.strokeColor,
      this.animatingStrokeColor,
      this.isShowNumber = true,
      this.numberStyle,
      this.autoAnimate = true,
      required this.dashSetting,
      this.onFinish});

  final TextStrokeOrderController controller;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double width;
  final double height;
  final double? strokeWidth;
  final Color? strokeColor;
  final Color? animatingStrokeColor;
  final bool isShowNumber;
  final TextStyle? numberStyle;
  final bool autoAnimate;
  final ViewPortDashSetting dashSetting;
  final Function()? onFinish;

  @override
  State<AnimationStrokeOrder> createState() => _AnimationStrokeOrderState();
}

class _AnimationStrokeOrderState extends State<AnimationStrokeOrder> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialAnimate(widget.autoAnimate);
    widget.controller.animationController.addListener(_listener);
  }

  _listener() {
    if (widget.controller.animationController.isCompleted) {
      widget.onFinish?.call();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // widget.controller.startAnimation();
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller.animationController,
      builder: (context, child) {
        return Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: CustomPaint(
            painter: OneByOnePainter(
              animation: widget.controller.animationController,
              pathSegments:
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
              textSegments: widget.isShowNumber
                  ? widget.controller.parser!.getTextSegments().map((e) {
                      final segment = e;
                      if (widget.numberStyle != null) {
                        segment.textStyle = widget.numberStyle!;
                      }
                      return segment;
                    }).toList()
                  : [],
            ),
            child: SizedBox(
              width: widget.width - (widget.padding?.horizontal ?? 0),
              height: widget.height - (widget.padding?.vertical ?? 0),
            ),
          ),
        );
      },
    );
  }
}
