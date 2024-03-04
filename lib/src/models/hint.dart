import 'package:flutter/material.dart';

class HintSetting {
  final bool enable;
  final Color color;
  final double strokeWidth;

  const HintSetting(
      {this.enable = true, this.color = Colors.grey, this.strokeWidth = 8});
}
