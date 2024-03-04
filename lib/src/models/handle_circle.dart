import 'package:flutter/material.dart';
import 'package:text_stroke_order/src/type.dart';

class HandleCircleSetting {
  final Color color;
  final double size;
  final HandleType type;
  final TextStyle? textStyle;
  final double? arrowSize;
  final Color? arrowColor;

  const HandleCircleSetting(
      {required this.color,
      required this.size,
      required this.type,
      required this.textStyle,
      required this.arrowSize,
      required this.arrowColor});

  const HandleCircleSetting.text(
      {this.color = Colors.orange, this.size = 6, this.textStyle})
      : type = HandleType.text,
        arrowSize = null,
        arrowColor = null;

  const HandleCircleSetting.arrow(
      {this.color = Colors.orange,
      this.size = 6,
      this.arrowSize = 3,
      this.arrowColor = Colors.white})
      : type = HandleType.arrow,
        textStyle = null;
}
