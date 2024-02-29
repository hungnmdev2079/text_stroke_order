import 'package:flutter/material.dart';
import '../text_stroke_order.dart';
import 'animate_stroke_order.dart';
import 'follow_stroke_order.dart';

class TextStrokeOrder extends StatefulWidget {
  const TextStrokeOrder({
    super.key,
    required this.controller,
    this.type = TextStrokeOrderType.animation,
    this.animation,
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
    this.onFinish,
    this.finishStrokeColor,
  });

  final TextStrokeOrderController controller;

  final TextStrokeOrderType type;

  final AnimationController? animation;

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

  final Function()? onFinish;

  final Color? finishStrokeColor;

  @override
  State<TextStrokeOrder> createState() => _TextStrokeOrderState();
}

class _TextStrokeOrderState extends State<TextStrokeOrder> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SvgParser?>(
      future: widget.controller.resolve,
      builder: (context, snapshot) {
        final parser = snapshot.data;
        if (parser != null && widget.controller.parser != null) {
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
          controller: widget.controller,
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
        );
      case TextStrokeOrderType.followTutorial:
        return FollowStrokeOrder(
          controller: widget.controller,
          height: widget.height,
          pading: widget.pading,
          width: widget.width,
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
          onEnd: widget.onFinish,
          finishColor: widget.finishStrokeColor,
        );
      default:
        return const SizedBox();
    }
  }
}
