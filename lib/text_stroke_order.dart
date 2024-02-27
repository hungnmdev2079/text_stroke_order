export 'src/parser.dart';
export 'src/path_parsing/path_parsing.dart';
export 'src/painter.dart';
export 'src/debug.dart';
import 'text_stroke_order_platform_interface.dart';

class TextStrokeOrder {
  Future<String?> getPlatformVersion() {
    return TextStrokeOrderPlatform.instance.getPlatformVersion();
  }
}
