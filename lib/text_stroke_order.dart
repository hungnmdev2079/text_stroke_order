export 'src/parser.dart';
import 'text_stroke_order_platform_interface.dart';

class TextStrokeOrder {
  Future<String?> getPlatformVersion() {
    return TextStrokeOrderPlatform.instance.getPlatformVersion();
  }
}
