import 'package:flutter/material.dart';

class ViewPortDashSetting {
  final bool enable;
  final double strokeWidth;
  final double length;
  final double spacing;
  final Color color;

  const ViewPortDashSetting(
      {this.enable = true,
      this.strokeWidth = 1,
      this.length = 9,
      this.spacing = 5,
      this.color = Colors.grey});
}
