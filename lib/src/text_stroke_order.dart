import 'package:flutter/material.dart';
import '../text_stroke_order.dart';
import 'animate_stroke_order.dart';
import 'sequential_stroke_order.dart';
import 'sequential_stroke_with_free_draw.dart';

class TextStrokeOrder extends StatefulWidget {
  const TextStrokeOrder(
      {super.key,
      required this.controller,
      this.type = TextStrokeOrderType.autoAnimation,
      this.loadingBuilder,
      this.width = 300,
      this.height = 300,
      this.padding,
      this.backgroundColor,
      this.borderRadius,
      this.border,
      this.strokeWidth,
      this.strokeColor,
      this.animatingStrokeColor,
      this.isShowNumber = true,
      this.numberStyle,
      this.onFinish,
      this.finishStrokeColor,
      this.randomSkipTutorial = false,
      this.onEndStroke,
      this.onEndStrokeCheck,
      this.autoAnimate = true,
      this.handWriteSetting = const HandWriteSetting(),
      this.tutorialPathSetting = const TutorialPathSetting(),
      this.hintSetting = const HintSetting(),
      this.viewPortDashSetting = const ViewPortDashSetting()});

  final TextStrokeOrderController controller;

  final TextStrokeOrderType type;

  final Widget Function(BuildContext context)? loadingBuilder;

  final double width;

  final double height;

  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;

  final double? borderRadius;

  final Border? border;

  final double? strokeWidth;

  final Color? strokeColor;

  final Color? animatingStrokeColor;

  final bool isShowNumber;

  final TextStyle? numberStyle;

  final Function()? onFinish;

  final Function()? onEndStroke;

  final Function(bool isCorrect)? onEndStrokeCheck;

  final Color? finishStrokeColor;

  final bool randomSkipTutorial;

  final HandWriteSetting handWriteSetting;

  final TutorialPathSetting tutorialPathSetting;

  final HintSetting hintSetting;

  final ViewPortDashSetting viewPortDashSetting;

  final bool autoAnimate;

  @override
  State<TextStrokeOrder> createState() => _TextStrokeOrderState();

  const TextStrokeOrder.autoAnimation(
      {super.key,
      required this.controller,
      this.width = 300,
      this.height = 300,
      this.padding,
      this.backgroundColor,
      this.border,
      this.borderRadius,
      this.strokeWidth,
      this.strokeColor,
      this.animatingStrokeColor,
      this.isShowNumber = true,
      this.numberStyle,
      this.loadingBuilder,
      this.onFinish,
      this.viewPortDashSetting = const ViewPortDashSetting(),
      this.autoAnimate = true})
      : type = TextStrokeOrderType.autoAnimation,
        onEndStroke = null,
        onEndStrokeCheck = null,
        finishStrokeColor = null,
        randomSkipTutorial = false,
        handWriteSetting = const HandWriteSetting(),
        tutorialPathSetting = const TutorialPathSetting(),
        hintSetting = const HintSetting();

  const TextStrokeOrder.sequentialStroke({
    super.key,
    required this.controller,
    required bool isFreeDraw,
    this.width = 300,
    this.height = 300,
    this.padding,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.isShowNumber = true,
    this.numberStyle,
    this.loadingBuilder,
    this.onFinish,
    this.onEndStroke,
    this.onEndStrokeCheck,
    this.finishStrokeColor,
    this.randomSkipTutorial = false,
    this.viewPortDashSetting = const ViewPortDashSetting(),
    this.handWriteSetting = const HandWriteSetting(),
    this.tutorialPathSetting = const TutorialPathSetting(),
    this.hintSetting = const HintSetting(),
  })  : type = isFreeDraw
            ? TextStrokeOrderType.sequentialStrokeWithFreeDraw
            : TextStrokeOrderType.sequentialStroke,
        strokeWidth = null,
        strokeColor = null,
        animatingStrokeColor = null,
        autoAnimate = true;
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
      case TextStrokeOrderType.autoAnimation:
        return AnimationStrokeOrder(
          controller: widget.controller,
          height: widget.height,
          padding: widget.padding,
          width: widget.width,
          backgroundColor: widget.backgroundColor,
          border: widget.border,
          borderRadius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
          strokeColor: widget.strokeColor,
          animatingStrokeColor: widget.animatingStrokeColor,
          isShowNumber: widget.isShowNumber,
          numberStyle: widget.numberStyle,
          autoAnimate: widget.autoAnimate,
          dashSetting: widget.viewPortDashSetting,
          onFinish: widget.onFinish,
        );
      case TextStrokeOrderType.sequentialStroke:
        return SequentialStrokeOrder(
          controller: widget.controller,
          height: widget.height,
          padding: widget.padding,
          width: widget.width,
          backgroundColor: widget.backgroundColor,
          border: widget.border,
          borderRadius: widget.borderRadius,
          strokeColor: widget.strokeColor,
          isShowNumber: widget.isShowNumber,
          numberStyle: widget.numberStyle,
          onEnd: widget.onFinish,
          randomSkipTutorial: widget.randomSkipTutorial,
          onEndStroke: widget.onEndStroke,
          tutorialPathSetting: widget.tutorialPathSetting,
          dashSetting: widget.viewPortDashSetting,
        );
      case TextStrokeOrderType.sequentialStrokeWithFreeDraw:
        return SequentialStrokeWithFreeDraw(
          controller: widget.controller,
          padding: widget.padding,
          width: widget.width,
          height: widget.height,
          isShowNumber: widget.isShowNumber,
          randomSkipTutorial: widget.randomSkipTutorial,
          backgroundColor: widget.backgroundColor,
          border: widget.border,
          borderRadius: widget.borderRadius,
          numberStyle: widget.numberStyle,
          onEnd: widget.onFinish,
          onEndStroke: widget.onEndStroke,
          onEndStrokeCheck: widget.onEndStrokeCheck,
          handWriteSetting: widget.handWriteSetting,
          tutorialPathSetting: widget.tutorialPathSetting,
          hintSetting: widget.hintSetting,
          dashSetting: widget.viewPortDashSetting,
        );
      default:
        return const SizedBox();
    }
  }
}
