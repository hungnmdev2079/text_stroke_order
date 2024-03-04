import 'package:flutter/material.dart';

import 'arrow_dash_line.dart';
import 'handle_circle.dart';

class TutorialPathSetting {
  final bool enable;
  final bool arrowDashEnable;
  final bool handleEnable;
  final Color color;
  final Color fillColor;
  final Color finishColor;
  final double strokeWidth;
  final ArrowDashLineSetting arrowDashLineSetting;
  final HandleCircleSetting handleCircleSetting;

  const TutorialPathSetting(
      {this.enable = true,
      this.arrowDashEnable = true,
      this.handleEnable = true,
      this.strokeWidth = 8,
      this.color = Colors.grey,
      this.fillColor = Colors.orange,
      this.finishColor = Colors.green,
      this.arrowDashLineSetting = const ArrowDashLineSetting(),
      this.handleCircleSetting = const HandleCircleSetting.text()});
}
