import 'package:flutter/material.dart';

class ArrowDashLineSetting {
  final Color color;
  final double strokeWidth;
  final double length;
  final double spacing;
  final double arrowSize;
  final double arrowAngle;

  const ArrowDashLineSetting(
      {this.color = Colors.orange,
      this.strokeWidth = 1.5,
      this.length = 3,
      this.spacing = 3,
      this.arrowSize = 5,
      this.arrowAngle = 25});
}
