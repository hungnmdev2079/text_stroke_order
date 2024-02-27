import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'text_stroke_order_platform_interface.dart';

/// An implementation of [TextStrokeOrderPlatform] that uses method channels.
class MethodChannelTextStrokeOrder extends TextStrokeOrderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('text_stroke_order');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
