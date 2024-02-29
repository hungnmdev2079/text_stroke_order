import 'dart:math';

import 'package:flutter/material.dart';

class Utils {
  static double getAngleOffset(Offset first, Offset second) {
    final dX = second.dx - first.dx;
    final dY = second.dy - first.dy;
    final angle = atan2(dY, dX);
    return angle;
  }
}
